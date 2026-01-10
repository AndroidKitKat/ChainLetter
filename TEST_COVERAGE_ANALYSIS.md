# Test Coverage Analysis for ChainLetter

## Executive Summary

ChainLetter has a solid test foundation with **~112 tests** across **25 test suites**, achieving a test-to-source ratio of approximately **1.48:1**. However, there are several areas where test coverage could be improved to ensure better reliability and catch edge cases.

---

## Current Coverage Overview

| Module | Source Lines | Test Lines | Tests | Coverage Assessment |
|--------|-------------|------------|-------|---------------------|
| Chain.swift | 295 | 299 | ~27 | Good |
| MarkovText.swift | 437 | 328 | ~40 | Good |
| State.swift | 41 | (in ChainTests) | ~4 | Moderate |
| Splitters.swift | 119 | 422 | ~29 | Excellent |
| Combine functionality | (distributed) | 273 | ~16 | Good |

---

## Areas Requiring Improved Test Coverage

### 1. **Chain.swift - High Priority**

#### 1.1 Secondary Initializer (Line 45-49)
```swift
public init(model: [State: [String: Int]], stateSize: Int)
```
**Issue**: The initializer that creates a Chain from a pre-built model is not directly tested.

**Recommended Test**:
```swift
@Test("Creates chain from pre-built model")
func initFromModel() {
    let model: [State: [String: Int]] = [
        State.begin(size: 2): ["hello": 2],
        State(words: [State.beginToken, "hello"]): ["world": 1],
        State(words: ["hello", "world"]): [State.endToken: 1]
    ]
    let chain = Chain(model: model, stateSize: 2)

    #expect(chain.stateSize == 2)
    #expect(chain.model.count == 3)
    let result = chain.walk()
    #expect(result == ["hello", "world"])
}
```

#### 1.2 Binary Search Edge Cases (Line 138-151)
**Issue**: The `binarySearch` function is only tested indirectly. Edge cases like single-element arrays and boundary values are not verified.

**Recommended Tests**:
```swift
@Test("Move with single transition")
func moveWithSingleTransition() {
    let corpus = [["only"]]
    let chain = Chain(corpus: corpus, stateSize: 1)
    let word = chain.move(from: State.begin(size: 1))
    #expect(word == "only")
}

@Test("Walk that immediately ends")
func walkImmediateEnd() {
    // Single word sentence - walk from second state should return empty
    let corpus = [["word"]]
    let chain = Chain(corpus: corpus, stateSize: 2)
    let state = State(words: [State.beginToken, "word"])
    let result = chain.walk(from: state)
    #expect(result.isEmpty) // Next word is END token
}
```

#### 1.3 Weight Count Mismatch (Line 233-234)
**Issue**: The `fatalError` when weights count doesn't match chains count is untested.

**Recommended Test**:
```swift
@Test("Mismatched weights count causes fatal error")
func mismatchedWeightsCount() {
    let chain1 = Chain(corpus: [["a"]], stateSize: 1)
    let chain2 = Chain(corpus: [["b"]], stateSize: 1)

    // This should trigger fatalError - may need different testing approach
    // Consider changing fatalError to a thrown error for testability
}
```

**Recommendation**: Refactor to throw an error instead of `fatalError` for better testability and safer API.

---

### 2. **MarkovText.swift - High Priority**

#### 2.1 Secondary Initializer (Line 110-127)
```swift
public init(chain: Chain, parsedSentences: [[String]]?, wordJoiner: ...)
```
**Issue**: This initializer is only tested indirectly through combine tests.

**Recommended Test**:
```swift
@Test("Creates MarkovText from pre-built chain")
func initFromChain() {
    let chain = Chain(corpus: [["hello", "world"]], stateSize: 2)
    let text = MarkovText(chain: chain)

    #expect(text.stateSize == 2)
    let sentence = text.makeSentence(testOutput: false)
    #expect(sentence == "hello world")
}

@Test("Creates MarkovText from chain with parsed sentences")
func initFromChainWithSentences() {
    let chain = Chain(corpus: [["hello", "world"]], stateSize: 2)
    let text = MarkovText(chain: chain, parsedSentences: [["hello", "world"]])

    // Overlap checking should work
    let sentence = text.makeSentence(
        maxOverlapRatio: 0.5,
        maxOverlapTotal: 1,
        testOutput: true
    )
    // Should reject due to overlap
    #expect(sentence == nil)
}
```

#### 2.2 Well-Formed Sentence Validation (Line 136-155)
**Issue**: The `testSentenceInput` logic for well-formed sentences is not exhaustively tested.

**Recommended Tests**:
```swift
@Test("wellFormed filters lowercase starters")
func wellFormedFiltersLowercase() {
    let text = MarkovText("hello world.", wellFormed: true)
    // Should be filtered out since "hello" starts with lowercase
    #expect(text.chain.model.isEmpty)
}

@Test("wellFormed allows special lowercase starters")
func wellFormedAllowsSpecialStarters() {
    let text = MarkovText("iPhone is great.", wellFormed: true)
    #expect(!text.chain.model.isEmpty)
}

@Test("wellFormed allows eBay and similar")
func wellFormedAllowsEbay() {
    let text = MarkovText("eBay is popular.", wellFormed: true)
    #expect(!text.chain.model.isEmpty)
}

@Test("wellFormed=false allows all starters")
func wellFormedFalseAllowsAll() {
    let text = MarkovText("lowercase starter here.", wellFormed: false)
    #expect(!text.chain.model.isEmpty)
}
```

#### 2.3 makeSentenceWithStart Non-Strict Mode (Line 326-335)
**Issue**: The `strict: false` mode is not tested, which has different matching logic.

**Recommended Tests**:
```swift
@Test("makeSentenceWithStart non-strict mode matches any position")
func startWithNonStrict() {
    let corpus = """
    The cat sat on the mat. A dog ate the bone.
    """
    let text = MarkovText(corpus)

    // "the" appears in middle of sentences too
    let sentence = text.makeSentenceWithStart("the", strict: false, tries: 20, testOutput: false)
    #expect(sentence != nil)
    if let s = sentence {
        #expect(s.lowercased().hasPrefix("the"))
    }
}

@Test("makeSentenceWithStart strict vs non-strict difference")
func startWithStrictVsNonStrict() {
    let corpus = "Hello world. Say hello again."
    let text = MarkovText(corpus)

    // "hello" only appears at start of first sentence
    let strictResult = text.makeSentenceWithStart("Hello", strict: true, tries: 10, testOutput: false)
    let nonStrictResult = text.makeSentenceWithStart("hello", strict: false, tries: 10, testOutput: false)

    // Non-strict should potentially find "hello" in the middle too
    // (depends on corpus structure)
}
```

#### 2.4 makeShortSentence with Overlap Checking
**Issue**: `makeShortSentence` with `testOutput: true` is not tested.

**Recommended Test**:
```swift
@Test("makeShortSentence respects overlap checking")
func shortSentenceWithOverlap() {
    let text = MarkovText("Short sentence.")
    let sentence = text.makeShortSentence(
        maxChars: 100,
        maxOverlapRatio: 0.5,
        maxOverlapTotal: 2,
        testOutput: true
    )
    // Should return nil since it can only generate the original
    #expect(sentence == nil)
}
```

#### 2.5 Custom Splitters
**Issue**: Custom word splitter and word joiner are tested but not their interaction with generation.

**Recommended Tests**:
```swift
@Test("Custom word splitter affects generation")
func customWordSplitter() {
    let text = MarkovText(
        "hello-world",
        wordSplitter: { $0.components(separatedBy: "-") },
        wordJoiner: { $0.joined(separator: "-") }
    )
    let sentence = text.makeSentence(testOutput: false)
    #expect(sentence == "hello-world")
}

@Test("Custom word joiner in output")
func customWordJoiner() {
    let text = MarkovText(
        "one two three",
        wordJoiner: { $0.joined(separator: "_") }
    )
    let sentence = text.makeSentence(testOutput: false)
    #expect(sentence?.contains("_") == true)
}
```

---

### 3. **State.swift - Medium Priority**

#### 3.1 Edge Cases
**Issue**: State with empty words array, very large states not tested.

**Recommended Tests**:
```swift
@Test("Empty state handling")
func emptyState() {
    let state = State(words: [])
    #expect(state.size == 0)
    let appended = state.appending("word")
    #expect(appended.words == ["word"])
}

@Test("Large state size")
func largeState() {
    let words = (0..<100).map { "word\($0)" }
    let state = State(words: words)
    #expect(state.size == 100)

    let appended = state.appending("new")
    #expect(appended.size == 100)
    #expect(appended.words.last == "new")
    #expect(appended.words.first == "word1")
}
```

---

### 4. **Splitters.swift - Medium Priority**

#### 4.1 Initialism Edge Cases
**Issue**: Numbers in initialisms and edge cases not tested.

**Recommended Tests**:
```swift
@Test("Initialism with numbers")
func initialismWithNumbers() {
    // The regex allows alphanumeric
    #expect("I.B.M.".wholeMatch(of: Splitters.initialism) != nil)
    #expect("3.M.".wholeMatch(of: Splitters.initialism) != nil)
}

@Test("Single component is not initialism")
func singleComponentNotInitialism() {
    #expect("A.".wholeMatch(of: Splitters.initialism) == nil)
}
```

#### 4.2 Unicode and Special Characters
**Issue**: Unicode sentence boundaries not tested.

**Recommended Tests**:
```swift
@Test("Unicode sentence handling")
func unicodeSentences() {
    let text = "Hello. 你好世界。 Goodbye."
    let result = Splitters.splitIntoSentences(text)
    // Behavior should be documented
}

@Test("Ellipsis handling")
func ellipsis() {
    let text = "Wait... What happened? I don't know."
    let result = Splitters.splitIntoSentences(text)
    #expect(result.count == 3)
}

@Test("Multiple punctuation marks")
func multiplePunctuation() {
    let text = "Really?! Yes!! Wow..."
    let result = Splitters.splitIntoSentences(text)
    // Define expected behavior
}
```

---

### 5. **Missing Integration/Behavioral Tests - High Priority**

#### 5.1 Concurrency Safety (Sendable Conformance)
**Issue**: No tests verify that `Sendable` conformance works correctly.

**Recommended Test**:
```swift
@Test("MarkovText is thread-safe")
func threadSafety() async {
    let text = MarkovText("The quick brown fox. The lazy dog.")

    await withTaskGroup(of: String?.self) { group in
        for _ in 0..<100 {
            group.addTask {
                return text.makeSentence(testOutput: false)
            }
        }

        for await result in group {
            #expect(result != nil)
        }
    }
}
```

#### 5.2 Statistical Distribution of Random Generation
**Issue**: No tests verify that weighted transitions produce expected distributions.

**Recommended Test**:
```swift
@Test("Weighted transitions produce expected distribution")
func weightedDistribution() {
    // Create corpus where "hello" should be followed by "world" 3x more than "there"
    let corpus = [
        ["hello", "world"],
        ["hello", "world"],
        ["hello", "world"],
        ["hello", "there"]
    ]
    let chain = Chain(corpus: corpus, stateSize: 2)

    var worldCount = 0
    var thereCount = 0

    for _ in 0..<1000 {
        let words = chain.walk()
        if words.last == "world" { worldCount += 1 }
        if words.last == "there" { thereCount += 1 }
    }

    // Should be roughly 3:1 ratio (with some tolerance)
    let ratio = Double(worldCount) / Double(thereCount)
    #expect(ratio > 2.0 && ratio < 4.0)
}
```

#### 5.3 Memory Behavior with retainOriginal
**Issue**: No tests verify memory implications of `retainOriginal` flag.

**Recommended Test**:
```swift
@Test("retainOriginal=false reduces memory footprint")
func retainOriginalMemory() {
    let largeCorpus = (0..<1000).map { "Sentence number \($0)." }.joined(separator: " ")

    let withRetain = MarkovText(largeCorpus, retainOriginal: true)
    let withoutRetain = MarkovText(largeCorpus, retainOriginal: false)

    // Verify generation still works
    let sentence1 = withRetain.makeSentence(testOutput: false)
    let sentence2 = withoutRetain.makeSentence(testOutput: false)

    #expect(sentence1 != nil)
    #expect(sentence2 != nil)
}
```

---

### 6. **Error Handling - Medium Priority**

#### 6.1 Malformed JSON Decoding
**Issue**: No tests for handling corrupted/malformed JSON.

**Recommended Tests**:
```swift
@Test("Graceful handling of malformed JSON")
func malformedJSON() {
    let malformed = "{ invalid json }".data(using: .utf8)!

    #expect(throws: DecodingError.self) {
        _ = try JSONDecoder().decode(Chain.self, from: malformed)
    }
}

@Test("Missing required fields in JSON")
func missingFieldsJSON() {
    let incomplete = "{ \"stateSize\": 2 }".data(using: .utf8)!

    #expect(throws: DecodingError.self) {
        _ = try JSONDecoder().decode(Chain.self, from: incomplete)
    }
}
```

---

## Summary of Recommendations

### High Priority (Should Be Addressed First)
1. **Direct initializer tests** for `Chain(model:stateSize:)` and `MarkovText(chain:parsedSentences:)`
2. **Well-formed sentence validation** tests for special lowercase starters (iPhone, eBay, etc.)
3. **Non-strict mode** tests for `makeSentenceWithStart`
4. **Concurrency/thread-safety** tests for Sendable conformance
5. **Refactor `fatalError`** in Chain.combine to throw an error instead

### Medium Priority
1. **Binary search edge cases** in Chain
2. **Unicode and ellipsis handling** in Splitters
3. **Statistical distribution** tests for random generation
4. **Custom splitter/joiner interaction** tests
5. **Malformed JSON** handling tests

### Low Priority (Nice to Have)
1. **Memory behavior** tests for retainOriginal
2. **Large state** edge cases
3. **Performance benchmarks** for large corpora

---

## Metrics After Proposed Improvements

| Metric | Current | After Improvements |
|--------|---------|-------------------|
| Total Tests | ~112 | ~140+ |
| Test Suites | 25 | ~28 |
| Edge Case Coverage | Moderate | Good |
| Concurrency Testing | None | Basic |
| Error Handling Coverage | Moderate | Good |

---

## Appendix: Test File Structure Suggestion

Consider organizing new tests into dedicated files:

```
Tests/ChainLetterTests/
├── ChainTests.swift           (existing)
├── MarkovTextTests.swift      (existing)
├── CombineTests.swift         (existing)
├── SplittersTests.swift       (existing)
├── InitializerTests.swift     (NEW - secondary initializer tests)
├── EdgeCaseTests.swift        (NEW - edge case consolidation)
├── ConcurrencyTests.swift     (NEW - thread safety tests)
└── ErrorHandlingTests.swift   (NEW - error/JSON tests)
```

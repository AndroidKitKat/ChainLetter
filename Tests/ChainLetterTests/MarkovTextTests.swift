//
//  MarkovTextTests.swift
//  ChainLetter
//
//  Created by Claude on 1/9/26.
//

import Testing
import Foundation
@testable import ChainLetter

@Suite("MarkovText Tests")
struct MarkovTextTests {

    // MARK: - Corpus Processing Tests

    @Suite("Corpus Processing")
    struct CorpusProcessingTests {

        @Test("Empty text produces empty model")
        func emptyText() {
            let text = MarkovText("")
            #expect(text.chain.model.isEmpty)
        }

        @Test("Single sentence corpus")
        func singleSentence() {
            let text = MarkovText("Hello world.")
            #expect(!text.chain.model.isEmpty)
        }

        @Test("Multi-sentence corpus")
        func multiSentence() {
            let text = MarkovText("First sentence. Second sentence. Third sentence.")
            #expect(!text.chain.model.isEmpty)
        }

        @Test("Custom sentence splitter")
        func customSplitter() {
            let text = MarkovText(
                "Line one\nLine two\nLine three",
                sentenceSplitter: { $0.components(separatedBy: .newlines).filter { !$0.isEmpty } }
            )
            #expect(!text.chain.model.isEmpty)
        }
    }

    // MARK: - Generation Tests

    @Suite("Generation")
    struct GenerationTests {

        @Test("makeSentence returns valid sentence")
        func makeSentenceValid() {
            // Use multiple sentences so there's variety in the output
            let corpus = """
            The quick brown fox jumps over the lazy dog. The dog barks at the fox.
            The fox runs away quickly. The lazy dog goes back to sleep.
            """
            let text = MarkovText(corpus)
            let sentence = text.makeSentence(testOutput: false)
            #expect(sentence != nil)
        }

        @Test("makeSentence respects minWords")
        func makeSentenceMinWords() {
            let text = MarkovText("One. Two words. Three little words. Four words here now.")
            // With minWords=3, should skip "One." and "Two words."
            for _ in 0..<10 {
                if let sentence = text.makeSentence(testOutput: false, minWords: 3) {
                    let wordCount = sentence.split(separator: " ").count
                    #expect(wordCount >= 3)
                }
            }
        }

        @Test("makeSentence respects maxWords")
        func makeSentenceMaxWords() {
            let text = MarkovText("A very long sentence with many many words in it.")
            for _ in 0..<10 {
                if let sentence = text.makeSentence(testOutput: false, maxWords: 5) {
                    let wordCount = sentence.split(separator: " ").count
                    #expect(wordCount <= 5)
                }
            }
        }

        @Test("makeSentence returns nil for impossible constraints")
        func makeSentenceImpossible() {
            let text = MarkovText("Short.")
            let sentence = text.makeSentence(tries: 5, minWords: 100)
            #expect(sentence == nil)
        }

        @Test("Deterministic corpus produces deterministic output")
        func deterministicOutput() {
            let text = MarkovText("The only possible sentence.")
            let sentence1 = text.makeSentence(testOutput: false)
            let sentence2 = text.makeSentence(testOutput: false)
            #expect(sentence1 == sentence2)
            #expect(sentence1 == "The only possible sentence.")
        }
    }

    // MARK: - Overlap Checking Tests

    @Suite("Overlap Checking")
    struct OverlapCheckingTests {

        @Test("Exact duplicate is rejected")
        func exactDuplicate() {
            let text = MarkovText("This is the only sentence.")
            // With testOutput=true and strict overlap checking,
            // an exact duplicate should be rejected
            let sentence = text.makeSentence(
                tries: 20,
                maxOverlapRatio: 0.5,
                maxOverlapTotal: 3,
                testOutput: true
            )
            // Should return nil since there's only one possible output
            // and it overlaps 100% with the corpus
            #expect(sentence == nil)
        }

        @Test("testOutput=false skips checking")
        func skipOverlapCheck() {
            let text = MarkovText("This is the only sentence.")
            let sentence = text.makeSentence(testOutput: false)
            #expect(sentence != nil)
            #expect(sentence == "This is the only sentence.")
        }

        @Test("Works when retainOriginal=false")
        func noRetainOriginal() {
            let text = MarkovText("Hello world.", retainOriginal: false)
            // Should work fine without overlap checking
            let sentence = text.makeSentence()
            #expect(sentence != nil)
        }

        @Test("High overlap ratio allows more similar output")
        func highOverlapRatio() {
            let text = MarkovText("The quick brown fox.")
            // With high overlap allowance, should succeed
            let sentence = text.makeSentence(
                maxOverlapRatio: 1.0,
                maxOverlapTotal: 100,
                testOutput: true
            )
            #expect(sentence != nil)
        }
    }

    // MARK: - Short Sentence Tests

    @Suite("Short Sentence")
    struct ShortSentenceTests {

        @Test("makeShortSentence respects maxChars")
        func maxChars() {
            let text = MarkovText("Short. A bit longer sentence here. Very very long sentence with many words.")
            for _ in 0..<10 {
                if let sentence = text.makeShortSentence(maxChars: 20, testOutput: false) {
                    #expect(sentence.count <= 20)
                }
            }
        }

        @Test("makeShortSentence respects minChars")
        func minChars() {
            let text = MarkovText("Hi. Hello there friend. This is a longer sentence.")
            for _ in 0..<10 {
                if let sentence = text.makeShortSentence(maxChars: 100, minChars: 10, testOutput: false) {
                    #expect(sentence.count >= 10)
                }
            }
        }

        @Test("makeShortSentence returns nil for impossible constraints")
        func impossibleConstraints() {
            let text = MarkovText("This sentence is definitely longer than five characters.")
            let sentence = text.makeShortSentence(maxChars: 5, tries: 10, testOutput: false)
            #expect(sentence == nil)
        }
    }

    // MARK: - Start With Tests

    @Suite("Start With")
    struct StartWithTests {

        @Test("makeSentenceWithStart finds valid start")
        func validStart() {
            let corpus = """
            The cat sat on the mat. The dog ran in the park.
            The bird flew over the tree. A fish swam in the sea.
            """
            let text = MarkovText(corpus)

            // Should find sentences starting with "The"
            let sentence = text.makeSentenceWithStart("The", tries: 20, testOutput: false)
            #expect(sentence != nil)
            if let s = sentence {
                #expect(s.hasPrefix("The"))
            }
        }

        @Test("makeSentenceWithStart returns nil for unknown phrase")
        func unknownPhrase() {
            let text = MarkovText("Hello world. Goodbye moon.")
            let sentence = text.makeSentenceWithStart("Xyz123", tries: 5)
            #expect(sentence == nil)
        }

        @Test("makeSentenceWithStart fails if beginning too long")
        func beginningTooLong() {
            let text = MarkovText("Hello world.", stateSize: 2)
            // Beginning has 3 words, but state size is 2
            let sentence = text.makeSentenceWithStart("One two three")
            #expect(sentence == nil)
        }
    }

    // MARK: - Compilation Tests

    @Suite("Compilation")
    struct CompilationTests {

        @Test("compile sets compiled flag")
        func compileFlag() {
            var text = MarkovText("Hello world.")
            #expect(!text.compiled)
            text.compile()
            #expect(text.compiled)
        }

        @Test("Compiled model generates same results")
        func compiledGeneration() {
            let corpus = "The only possible output."
            var text = MarkovText(corpus)

            let before = text.makeSentence(testOutput: false)
            text.compile()
            let after = text.makeSentence(testOutput: false)

            #expect(before == after)
        }
    }

    // MARK: - Codable Tests

    @Suite("Codable")
    struct CodableTests {

        @Test("JSON round-trip preserves model")
        func jsonRoundTrip() throws {
            let original = MarkovText("The quick brown fox. The lazy dog sleeps.")

            let data = try JSONEncoder().encode(original)
            let restored = try JSONDecoder().decode(MarkovText.self, from: data)

            #expect(restored.stateSize == original.stateSize)
            #expect(restored.chain.model.count == original.chain.model.count)
        }

        @Test("Decoded MarkovText generates valid output")
        func decodedGeneration() throws {
            let original = MarkovText("The only sentence here.")

            let data = try JSONEncoder().encode(original)
            let restored = try JSONDecoder().decode(MarkovText.self, from: data)

            let sentence = restored.makeSentence(testOutput: false)
            #expect(sentence == "The only sentence here.")
        }

        @Test("Round-trip preserves parsedSentences")
        func preservesParsedSentences() throws {
            let original = MarkovText("First sentence. Second sentence.", retainOriginal: true)

            let data = try JSONEncoder().encode(original)
            let restored = try JSONDecoder().decode(MarkovText.self, from: data)

            // Overlap checking should still work - just verify it doesn't crash
            _ = restored.makeSentence(
                tries: 10,
                maxOverlapRatio: 0.3,
                maxOverlapTotal: 2,
                testOutput: true
            )
        }
    }

    // MARK: - Edge Cases

    @Suite("Edge Cases")
    struct EdgeCaseTests {

        @Test("State size of 1")
        func stateSize1() {
            let text = MarkovText("One two three.", stateSize: 1)
            let sentence = text.makeSentence(testOutput: false)
            #expect(sentence != nil)
        }

        @Test("State size of 3")
        func stateSize3() {
            let text = MarkovText("One two three four five.", stateSize: 3)
            let sentence = text.makeSentence(testOutput: false)
            #expect(sentence != nil)
        }

        @Test("Whitespace handling")
        func whitespace() {
            let text = MarkovText("  Sentence with   extra   spaces.  ")
            let sentence = text.makeSentence(testOutput: false)
            #expect(sentence != nil)
        }

        @Test("Unicode text")
        func unicode() {
            let text = MarkovText("Hello 世界. Bonjour le monde. Привет мир.")
            let sentence = text.makeSentence(testOutput: false)
            #expect(sentence != nil)
        }
    }
}

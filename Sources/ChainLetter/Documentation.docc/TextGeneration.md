# Text Generation

Generate sentences with various constraints and options.

## Overview

ChainLetter provides several methods for generating text, from simple random sentences to length-constrained output suitable for tweets or UI elements.

## Basic Sentence Generation

The ``MarkovText/makeSentence(initState:tries:maxOverlapRatio:maxOverlapTotal:testOutput:maxWords:minWords:)`` method generates a single sentence:

```swift
if let sentence = model.makeSentence() {
    print(sentence)
}
```

### Controlling Attempts

Generation may fail if the random walk produces text too similar to the original corpus. Increase `tries` for difficult corpora:

```swift
if let sentence = model.makeSentence(tries: 50) {
    print(sentence)
}
```

### Word Count Constraints

Limit the length of generated sentences by word count:

```swift
// At least 5 words
if let sentence = model.makeSentence(minWords: 5) {
    print(sentence)
}

// Between 5 and 15 words
if let sentence = model.makeSentence(minWords: 5, maxWords: 15) {
    print(sentence)
}
```

## Character-Limited Sentences

Use ``MarkovText/makeShortSentence(maxChars:minChars:tries:maxOverlapRatio:maxOverlapTotal:testOutput:)`` when you need sentences that fit within a character limit:

```swift
// Tweet-length (max 280 characters)
if let tweet = model.makeShortSentence(maxChars: 280) {
    print(tweet)
}

// Between 100 and 280 characters
if let tweet = model.makeShortSentence(maxChars: 280, minChars: 100) {
    print(tweet)
}
```

## Starting with a Specific Phrase

Use ``MarkovText/makeSentenceWithStart(_:strict:tries:maxOverlapRatio:maxOverlapTotal:testOutput:)`` to generate sentences beginning with a specific word or phrase:

```swift
if let sentence = model.makeSentenceWithStart("The quick") {
    print(sentence)
    // "The quick brown fox jumps over the lazy dog."
}
```

### Strict vs. Non-Strict Mode

In **strict mode** (default), the phrase must appear at the beginning of sentences in your corpus:

```swift
// Only works if sentences start with "Once upon"
if let sentence = model.makeSentenceWithStart("Once upon", strict: true) {
    print(sentence)
}
```

In **non-strict mode**, the phrase can appear anywhere in the model's states:

```swift
// Works if "brown fox" appears anywhere
if let sentence = model.makeSentenceWithStart("brown fox", strict: false) {
    print(sentence)
}
```

> Note: The starting phrase must contain at most `stateSize` words.

## Overlap Detection

By default, ChainLetter rejects sentences that too closely match the original corpus. This prevents generating exact copies of your input.

### How It Works

The algorithm checks if any contiguous sequence of words in the generated sentence appears in the original text. The thresholds are:

- **maxOverlapRatio**: Maximum overlap as a fraction of sentence length (default: 0.7)
- **maxOverlapTotal**: Maximum absolute overlap in words (default: 15)

The effective limit is the smaller of these two values.

### Adjusting Thresholds

For more original output, use stricter thresholds:

```swift
if let sentence = model.makeSentence(
    maxOverlapRatio: 0.5,  // Max 50% overlap
    maxOverlapTotal: 8     // Max 8 words
) {
    print(sentence)
}
```

### Disabling Overlap Checking

For maximum generation success (at the cost of potentially copying the source), disable checking entirely:

```swift
if let sentence = model.makeSentence(testOutput: false) {
    print(sentence)
}
```

> Important: Disabling overlap checking is useful for small corpora where overlap is unavoidable, but the output may be identical to your source text.

## Performance Optimization

For applications that generate many sentences, compile the model first:

```swift
var model = MarkovText(corpus)
model.compile()

// Generation is now faster
for _ in 0..<1000 {
    if let sentence = model.makeSentence() {
        print(sentence)
    }
}
```

Compilation pre-computes cumulative probability distributions, improving generation speed by approximately 10-20% for large models.

## See Also

- ``MarkovText/makeSentence(initState:tries:maxOverlapRatio:maxOverlapTotal:testOutput:maxWords:minWords:)``
- ``MarkovText/makeShortSentence(maxChars:minChars:tries:maxOverlapRatio:maxOverlapTotal:testOutput:)``
- ``MarkovText/makeSentenceWithStart(_:strict:tries:maxOverlapRatio:maxOverlapTotal:testOutput:)``

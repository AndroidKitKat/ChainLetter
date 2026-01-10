# ChainLetter

A Swift library for building Markov chain text generators. ChainLetter is a Swift 6 port of the popular Python [markovify](https://github.com/jsvine/markovify) library.

## Features

- Build Markov chain models from text corpora
- Generate random sentences that mimic the style of your input text
- Sentence splitting with smart handling of abbreviations, titles, and initialisms
- Overlap detection to avoid generating text too similar to the source
- Combine multiple models with optional weighting
- Full `Codable` support for saving/loading models
- Swift 6 concurrency support (`Sendable` conformance)

## Requirements

- macOS 15.0+
- Swift 6.0+

## Installation

### Swift Package Manager

Add ChainLetter to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/AndroidKitKat/ChainLetter.git", from: "1.0.0")
]
```

Then add it to your target:

```swift
.target(
    name: "YourApp",
    dependencies: ["ChainLetter"]
)
```

## Quick Start

```swift
import ChainLetter

// Build a model from text
let corpus = """
The quick brown fox jumps over the lazy dog.
The lazy cat sleeps all day long.
The brown dog runs through the park.
"""

let model = MarkovText(corpus)

// Generate a sentence
if let sentence = model.makeSentence() {
    print(sentence)
    // Example output: "The lazy cat sleeps all day long."
}
```

## Usage Guide

### Building Models

#### From a Text String

```swift
let model = MarkovText(corpus)
```

#### With Custom Options

```swift
let model = MarkovText(
    corpus,
    stateSize: 2,           // Words per state (default: 2)
    retainOriginal: true,   // Keep corpus for overlap checking (default: true)
    wellFormed: true        // Filter malformed sentences (default: true)
)
```

#### From Newline-Delimited Text (Chat Logs, Poetry, etc.)

```swift
let model = MarkovText(
    chatLogs,
    wellFormed: false,  // Allow lowercase-starting lines
    sentenceSplitter: { text in
        text.components(separatedBy: .newlines).filter { !$0.isEmpty }
    }
)
```

### Generating Text

#### Basic Sentence Generation

```swift
// Generate a sentence (may return nil if generation fails)
if let sentence = model.makeSentence() {
    print(sentence)
}

// Try more times for difficult corpora
if let sentence = model.makeSentence(tries: 100) {
    print(sentence)
}
```

#### Short Sentences (Tweet-Length, etc.)

```swift
// Generate a sentence with max 280 characters
if let tweet = model.makeShortSentence(maxChars: 280) {
    print(tweet)
}

// With minimum length
if let sentence = model.makeShortSentence(maxChars: 280, minChars: 100) {
    print(sentence)
}
```

#### Sentences Starting with a Specific Phrase

```swift
// Generate a sentence starting with "The quick"
if let sentence = model.makeSentenceWithStart("The quick") {
    print(sentence)
}

// Non-strict mode: phrase can appear anywhere in the starting state
if let sentence = model.makeSentenceWithStart("quick", strict: false) {
    print(sentence)
}
```

#### Word Count Constraints

```swift
if let sentence = model.makeSentence(minWords: 5, maxWords: 15) {
    print(sentence)
}
```

### Combining Models

Merge multiple models to blend writing styles:

```swift
let shakespeare = MarkovText(shakespeareText)
let hemingway = MarkovText(hemingwayText)

// Equal weighting
let combined = try MarkovText.combine([shakespeare, hemingway])

// Custom weights (Shakespeare 3x more influential)
let mostlyShakespeare = try MarkovText.combine(
    [shakespeare, hemingway],
    weights: [3.0, 1.0]
)
```

### Saving and Loading Models

Models are fully `Codable` for persistence:

```swift
// Save to JSON
let encoder = JSONEncoder()
let data = try encoder.encode(model)
try data.write(to: URL(fileURLWithPath: "model.json"))

// Load from JSON
let data = try Data(contentsOf: URL(fileURLWithPath: "model.json"))
let decoder = JSONDecoder()
var loaded = try decoder.decode(MarkovText.self, from: data)

// Optional: compile for faster generation
loaded.compile()
```

### Performance Optimization

For large models with repeated generation, compile for faster performance:

```swift
var model = MarkovText(largeCorpus)
model.compile()  // Pre-computes cumulative distributions

// Generation is now ~10-20% faster
for _ in 0..<1000 {
    if let sentence = model.makeSentence() {
        print(sentence)
    }
}
```

### Overlap Detection

By default, ChainLetter rejects generated sentences that are too similar to the original corpus:

```swift
// Customize overlap thresholds
if let sentence = model.makeSentence(
    maxOverlapRatio: 0.5,   // Max 50% overlap (default: 0.7)
    maxOverlapTotal: 10     // Max 10 words overlap (default: 15)
) {
    print(sentence)
}

// Disable overlap checking entirely
if let sentence = model.makeSentence(testOutput: false) {
    print(sentence)
}
```

## API Reference

### MarkovText

The main interface for text generation.

| Method | Description |
|--------|-------------|
| `init(_:stateSize:retainOriginal:wellFormed:sentenceSplitter:wordSplitter:wordJoiner:)` | Build from text |
| `init(chain:parsedSentences:wordJoiner:)` | Build from existing chain |
| `makeSentence(...)` | Generate a sentence |
| `makeShortSentence(maxChars:minChars:...)` | Generate length-constrained sentence |
| `makeSentenceWithStart(_:strict:...)` | Generate with specific starting phrase |
| `compile()` | Optimize for faster generation |
| `combine(_:weights:)` | Merge multiple models |

### Chain

Low-level Markov chain implementation.

| Method | Description |
|--------|-------------|
| `init(corpus:stateSize:)` | Build from word arrays |
| `init(model:stateSize:)` | Build from pre-built model |
| `walk(from:)` | Generate word sequence |
| `move(from:)` | Get next word from state |
| `compile()` | Optimize for faster generation |
| `combine(_:weights:)` | Merge multiple chains |

### Splitters

Sentence boundary detection utilities.

| Method | Description |
|--------|-------------|
| `splitIntoSentences(_:)` | Split text into sentences |
| `isSentenceEnder(_:)` | Check if word ends a sentence |
| `isAbbreviation(_:)` | Check if word is an abbreviation |

## How It Works

ChainLetter uses a Markov chain to model text. Here's a simplified explanation:

1. **Parsing**: Text is split into sentences, then words
2. **Model Building**: For each position, record what words follow each N-word state
3. **Generation**: Start with a begin state, randomly walk through transitions until reaching an end state
4. **Validation**: Reject outputs too similar to the original corpus

Example with state size 2:

```
Corpus: "The cat sat. The cat slept."

Model:
  [BEGIN, BEGIN] → ["The": 2]
  ["The", "cat"]  → ["sat": 1, "slept": 1]
  ["cat", "sat"]  → [END: 1]
  ["cat", "slept"] → [END: 1]
```

## Differences from Python markovify

| Feature | markovify (Python) | ChainLetter (Swift) |
|---------|-------------------|---------------------|
| Customization | Subclassing | Closures |
| Type | `Text` | `MarkovText` (avoids SwiftUI conflict) |
| Error handling | Exceptions | Optional returns / throws |
| Concurrency | Not thread-safe | `Sendable` conformance |
| `wellFormed` check | Regex for quotes/parens | Lowercase start check |

## License

MIT License - see LICENSE file for details.

## Acknowledgments

- [markovify](https://github.com/jsvine/markovify) by Jeremy Singer-Vine - the original Python library this is based on

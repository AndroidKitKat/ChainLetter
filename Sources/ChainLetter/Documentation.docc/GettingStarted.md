# Getting Started with ChainLetter

Learn how to build your first Markov chain text generator.

## Overview

ChainLetter uses Markov chains to model text statistically. By analyzing patterns in existing text, it learns which words tend to follow other words, then uses those patterns to generate new, original sentences.

This guide walks you through installation, building your first model, and generating text.

## Installation

Add ChainLetter to your Swift package dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/ChainLetter.git", from: "1.0.0")
]
```

Then add it to your target:

```swift
.target(
    name: "YourApp",
    dependencies: ["ChainLetter"]
)
```

## Building Your First Model

The ``MarkovText`` type is your primary interface for text generation. Create one by passing in your source text:

```swift
import ChainLetter

let corpus = """
It was the best of times. It was the worst of times.
It was the age of wisdom. It was the age of foolishness.
"""

let model = MarkovText(corpus)
```

ChainLetter automatically:
1. Splits your text into sentences
2. Tokenizes each sentence into words
3. Builds a probabilistic model of word transitions

## Generating Sentences

Call ``MarkovText/makeSentence(initState:tries:maxOverlapRatio:maxOverlapTotal:testOutput:maxWords:minWords:)`` to generate a random sentence:

```swift
if let sentence = model.makeSentence() {
    print(sentence)
    // "It was the age of wisdom."
}
```

The method returns an optional because generation can fail if:
- The corpus is too small
- Constraints can't be satisfied
- All attempts produced sentences too similar to the original

### Handling Generation Failures

For small or constrained corpora, increase the number of attempts:

```swift
if let sentence = model.makeSentence(tries: 100) {
    print(sentence)
} else {
    print("Could not generate a sentence")
}
```

## Understanding State Size

The `stateSize` parameter controls how many words the model considers when predicting the next word:

| State Size | Behavior |
|------------|----------|
| 1 | More random, less coherent |
| 2 | Balanced (default) |
| 3+ | More coherent, more similar to source |

```swift
// More random output
let creative = MarkovText(corpus, stateSize: 1)

// More coherent output
let conservative = MarkovText(corpus, stateSize: 3)
```

## Next Steps

- <doc:TextGeneration> - Learn about all generation methods
- <doc:CustomizingSentenceSplitting> - Handle non-standard text formats
- <doc:CombiningModels> - Blend multiple text sources

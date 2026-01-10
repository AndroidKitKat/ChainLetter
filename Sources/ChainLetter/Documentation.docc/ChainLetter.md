# ``ChainLetter``

A Swift library for building Markov chain text generators.

## Overview

ChainLetter enables you to build probabilistic text generators that learn from existing text and produce new, original sentences in a similar style. It's a Swift 6 port of the popular Python [markovify](https://github.com/jsvine/markovify) library.

Use ChainLetter to:
- Generate random sentences that mimic the style of input text
- Create chatbots, creative writing tools, or text-based games
- Blend multiple text sources with weighted influence
- Build persistent models that can be saved and loaded

```swift
import ChainLetter

let corpus = """
The quick brown fox jumps over the lazy dog.
The lazy cat sleeps all day long.
"""

let model = MarkovText(corpus)

if let sentence = model.makeSentence() {
    print(sentence)
    // "The lazy cat sleeps all day long."
}
```

## Topics

### Essentials

- <doc:GettingStarted>
- <doc:TextGeneration>
- ``MarkovText``

### Advanced Usage

- <doc:CustomizingSentenceSplitting>
- <doc:CombiningModels>
- <doc:PersistingModels>

### Core Types

- ``MarkovText``
- ``Chain``
- ``State``

### Utilities

- ``Splitters``

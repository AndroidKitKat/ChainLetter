# Combining Models

Blend multiple text sources to create hybrid generators.

## Overview

ChainLetter allows you to combine multiple Markov models into a single generator. This is useful for blending writing styles, mixing topics, or creating weighted hybrids from different corpora.

## Basic Combination

Use ``MarkovText/combine(_:weights:)`` to merge models:

```swift
let sciFi = MarkovText(sciFiCorpus)
let fantasy = MarkovText(fantasyCorpus)

let blended = try MarkovText.combine([sciFi, fantasy])
```

The combined model generates text that draws from both sources with equal probability.

## Weighted Combination

Apply weights to control the influence of each source:

```swift
let formal = MarkovText(formalWriting)
let casual = MarkovText(casualWriting)

// 75% formal, 25% casual influence
let mixed = try MarkovText.combine(
    [formal, casual],
    weights: [3.0, 1.0]
)
```

Weights are relative, so `[3.0, 1.0]` is equivalent to `[0.75, 0.25]` or `[6.0, 2.0]`.

## Combining Multiple Sources

Combine any number of models:

```swift
let author1 = MarkovText(corpus1)
let author2 = MarkovText(corpus2)
let author3 = MarkovText(corpus3)

let mashup = try MarkovText.combine(
    [author1, author2, author3],
    weights: [2.0, 1.0, 1.0]  // author1 has 2x influence
)
```

## Requirements and Constraints

### Same State Size

All models must have the same `stateSize`:

```swift
let model1 = MarkovText(text1, stateSize: 2)
let model2 = MarkovText(text2, stateSize: 3)

// This throws Chain.CombineError.mismatchedStateSizes
let combined = try MarkovText.combine([model1, model2])
```

### Uncompiled Models Only

Compiled models cannot be combined:

```swift
var model = MarkovText(corpus)
model.compile()

// This throws Chain.CombineError.compiledChainNotSupported
let combined = try MarkovText.combine([model, otherModel])
```

Combine models first, then compile the result if needed.

## Error Handling

The `combine` method throws ``Chain/CombineError`` for invalid inputs:

```swift
do {
    let combined = try MarkovText.combine([model1, model2])
} catch Chain.CombineError.emptyModels {
    print("No models provided")
} catch Chain.CombineError.mismatchedStateSizes(let sizes) {
    print("State sizes don't match: \(sizes)")
} catch Chain.CombineError.compiledChainNotSupported {
    print("Cannot combine compiled models")
}
```

## How Combination Works

When models are combined, their transition counts are merged:

```
Model A: "hello" → ["world": 3, "there": 1]
Model B: "hello" → ["world": 1, "friend": 2]

Combined: "hello" → ["world": 4, "there": 1, "friend": 2]
```

With weights, counts are multiplied before merging:

```
Model A (weight 2.0): "hello" → ["world": 6, "there": 2]
Model B (weight 1.0): "hello" → ["world": 1, "friend": 2]

Combined: "hello" → ["world": 7, "there": 2, "friend": 2]
```

## Overlap Checking in Combined Models

When models are combined, their parsed sentences are also merged (if `retainOriginal` was true). This means overlap checking works against all source corpora:

```swift
let model1 = MarkovText(text1, retainOriginal: true)
let model2 = MarkovText(text2, retainOriginal: true)

let combined = try MarkovText.combine([model1, model2])

// Overlap checking works against both text1 and text2
if let sentence = combined.makeSentence() {
    print(sentence)
}
```

## Combining at the Chain Level

For lower-level control, combine ``Chain`` objects directly:

```swift
let chain1 = Chain(corpus: corpus1, stateSize: 2)
let chain2 = Chain(corpus: corpus2, stateSize: 2)

let combined = try Chain.combine([chain1, chain2], weights: [1.5, 1.0])

// Create MarkovText from the combined chain
let model = MarkovText(chain: combined)
```

## Use Cases

### Blending Writing Styles

Create a generator that mixes multiple authors:

```swift
let classicLit = MarkovText(dickensAndAusten)
let modernFiction = MarkovText(contemporaryNovels)

let blended = try MarkovText.combine(
    [classicLit, modernFiction],
    weights: [1.0, 2.0]  // More modern influence
)
```

### Topic Mixing

Combine domain-specific corpora:

```swift
let techNews = MarkovText(technologyArticles)
let sportNews = MarkovText(sportsArticles)

let newsBot = try MarkovText.combine([techNews, sportNews])
```

### Personality Tuning

Adjust the "personality" of a chatbot by weighting different conversation styles:

```swift
let friendly = MarkovText(friendlyDialogue)
let professional = MarkovText(professionalDialogue)
let humorous = MarkovText(comedyDialogue)

let chatbot = try MarkovText.combine(
    [friendly, professional, humorous],
    weights: [2.0, 1.0, 0.5]
)
```

## See Also

- ``MarkovText/combine(_:weights:)``
- ``Chain/combine(_:weights:)``
- ``Chain/CombineError``

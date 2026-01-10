# Persisting Models

Save and load Markov models for later use.

## Overview

Building a Markov model from a large corpus can take time. ChainLetter supports full `Codable` conformance, allowing you to save trained models to disk and reload them instantly.

## Saving a Model

Use Swift's `JSONEncoder` to serialize a model:

```swift
import ChainLetter
import Foundation

// Train the model
let model = MarkovText(largeCorpus)

// Encode to JSON
let encoder = JSONEncoder()
encoder.outputFormatting = .prettyPrinted  // Optional: human-readable
let data = try encoder.encode(model)

// Write to disk
let url = URL(fileURLWithPath: "model.json")
try data.write(to: url)
```

## Loading a Model

Use `JSONDecoder` to restore a saved model:

```swift
let url = URL(fileURLWithPath: "model.json")
let data = try Data(contentsOf: url)

let decoder = JSONDecoder()
var model = try decoder.decode(MarkovText.self, from: data)

// Optional: compile for faster generation
model.compile()

// Ready to use
if let sentence = model.makeSentence() {
    print(sentence)
}
```

## What Gets Saved

The following data is persisted:

| Property | Description |
|----------|-------------|
| `stateSize` | The N-gram size |
| `chain.model` | All state transitions with counts |
| `parsedSentences` | Original corpus for overlap checking (if `retainOriginal` was true) |

## What Doesn't Get Saved

The following are **not** persisted:

| Property | Why |
|----------|-----|
| `compiled` state | Recompute with `compile()` after loading |
| Custom closures | Sentence/word splitters reset to defaults |

### Restoring Custom Closures

If you used custom splitters, you'll need to reapply them after loading:

```swift
// Original model with custom splitter
let original = MarkovText(
    corpus,
    sentenceSplitter: myCustomSplitter
)

// After loading, the model uses default splitters
var loaded = try decoder.decode(MarkovText.self, from: data)

// For generation, this usually doesn't matter since the model
// is already built. But if you need the same behavior, create
// a new model with the loaded chain:
let restored = MarkovText(
    chain: loaded.chain,
    parsedSentences: nil  // Already in the chain
)
```

## Binary Encoding

For smaller file sizes, use a binary encoder like `PropertyListEncoder`:

```swift
// Save as binary plist
let encoder = PropertyListEncoder()
encoder.outputFormat = .binary
let data = try encoder.encode(model)
try data.write(to: URL(fileURLWithPath: "model.plist"))

// Load
let data = try Data(contentsOf: URL(fileURLWithPath: "model.plist"))
let model = try PropertyListDecoder().decode(MarkovText.self, from: data)
```

## Saving Only the Chain

If you don't need overlap checking, save just the chain for a smaller file:

```swift
// Save only the chain
let chainData = try JSONEncoder().encode(model.chain)
try chainData.write(to: URL(fileURLWithPath: "chain.json"))

// Load and create MarkovText
let chainData = try Data(contentsOf: URL(fileURLWithPath: "chain.json"))
let chain = try JSONDecoder().decode(Chain.self, from: chainData)
let model = MarkovText(chain: chain)
```

> Note: Without `parsedSentences`, overlap checking is disabled. Set `testOutput: false` when generating, or accept that duplicates may occur.

## File Size Considerations

Model file sizes depend on:

- **Corpus size**: Larger corpora produce larger models
- **State size**: Higher state sizes create more unique states
- **retainOriginal**: Storing parsed sentences increases file size

Typical file sizes:

| Corpus Size | Approximate JSON Size |
|-------------|----------------------|
| 10 KB text | 50-100 KB |
| 100 KB text | 500 KB - 1 MB |
| 1 MB text | 5-10 MB |

To reduce file size:
- Use binary encoding (PropertyListEncoder)
- Set `retainOriginal: false` if you don't need overlap checking
- Consider compression (gzip)

### Compressing Saved Models

```swift
import Compression

// Save with compression
let data = try JSONEncoder().encode(model)
let compressed = try (data as NSData).compressed(using: .lzfse)
try compressed.write(to: URL(fileURLWithPath: "model.json.lzfse"))

// Load with decompression
let compressed = try Data(contentsOf: URL(fileURLWithPath: "model.json.lzfse"))
let data = try (compressed as NSData).decompressed(using: .lzfse)
let model = try JSONDecoder().decode(MarkovText.self, from: data as Data)
```

## App Bundle Resources

Include pre-trained models in your app bundle:

```swift
guard let url = Bundle.main.url(
    forResource: "trained_model",
    withExtension: "json"
) else {
    fatalError("Model not found in bundle")
}

let data = try Data(contentsOf: url)
var model = try JSONDecoder().decode(MarkovText.self, from: data)
model.compile()
```

## Thread Safety

``MarkovText`` and ``Chain`` conform to `Sendable`, making them safe to use across concurrency domains:

```swift
let model = try JSONDecoder().decode(MarkovText.self, from: data)

// Safe to use from multiple tasks
await withTaskGroup(of: String?.self) { group in
    for _ in 0..<10 {
        group.addTask {
            model.makeSentence()
        }
    }

    for await sentence in group {
        if let sentence {
            print(sentence)
        }
    }
}
```

> Important: The `compile()` method mutates the model. Compile before sharing across tasks, or use separate copies.

## See Also

- ``MarkovText``
- ``Chain``

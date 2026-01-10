# Customizing Sentence Splitting

Handle non-standard text formats like chat logs, poetry, and structured data.

## Overview

ChainLetter's default sentence splitter handles standard prose with periods, question marks, and exclamation points. However, many text sources use different conventions. This guide shows you how to customize text processing for your specific needs.

## Default Behavior

By default, ``MarkovText`` uses ``Splitters/splitIntoSentences(_:)`` which:

- Splits on `.`, `?`, and `!`
- Preserves abbreviations (Mr., Dr., U.S.A.)
- Handles titles and initialisms correctly
- Filters sentences that don't start with a capital letter

```swift
let model = MarkovText("Hello world. How are you?")
// Produces two sentences: ["Hello world.", "How are you?"]
```

## Custom Sentence Splitting

Pass a custom `sentenceSplitter` closure to handle non-standard formats.

### Newline-Delimited Text

For chat logs, poetry, lyrics, or any text where each line is a separate "sentence":

```swift
let chatLogs = """
hey what's up
not much, you?
just chilling lol
"""

let model = MarkovText(
    chatLogs,
    wellFormed: false,  // Allow lowercase starts
    sentenceSplitter: { text in
        text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
)
```

### Paragraph-Based Splitting

For documents where paragraphs are the unit of generation:

```swift
let model = MarkovText(
    document,
    sentenceSplitter: { text in
        text.components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
)
```

### CSV or Structured Data

For structured data sources:

```swift
let tweets = """
This is tweet one
This is tweet two
Another tweet here
"""

let model = MarkovText(
    tweets,
    sentenceSplitter: { text in
        text.components(separatedBy: .newlines)
            .filter { !$0.isEmpty }
    }
)
```

## The wellFormed Parameter

The `wellFormed` parameter controls whether sentences are filtered based on formatting rules.

### When wellFormed is true (Default)

Sentences starting with lowercase letters (except common exceptions like "iPhone") are rejected:

```swift
let model = MarkovText("Hello world. this is ignored.")
// Only "Hello world." is included
```

### When wellFormed is false

All non-empty sentences are included:

```swift
let model = MarkovText(
    "Hello world. this is included.",
    wellFormed: false
)
// Both sentences are included
```

> Tip: Set `wellFormed: false` for chat logs, informal text, or any corpus where sentences commonly start with lowercase letters.

## Custom Word Splitting

You can also customize how sentences are split into words:

```swift
let model = MarkovText(
    corpus,
    wordSplitter: { sentence in
        // Split on any whitespace
        sentence.components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
    }
)
```

### Preserving Punctuation

The default splitter keeps punctuation attached to words. To separate it:

```swift
let model = MarkovText(
    corpus,
    wordSplitter: { sentence in
        var result: [String] = []
        let words = sentence.split(separator: " ")
        for word in words {
            // Separate trailing punctuation
            let str = String(word)
            if let last = str.last, ".!?,;:".contains(last) {
                result.append(String(str.dropLast()))
                result.append(String(last))
            } else {
                result.append(str)
            }
        }
        return result
    }
)
```

## Custom Word Joining

Control how words are joined back into sentences:

```swift
let model = MarkovText(
    corpus,
    wordJoiner: { words in
        // Custom joining logic
        words.joined(separator: " ")
    }
)
```

## Complete Example: Processing Chat Logs

Here's a complete example for processing IRC or Discord chat logs:

```swift
import ChainLetter

let chatLog = """
<alice> hey everyone
<bob> sup alice
<alice> not much, just hanging out
<bob> cool cool
<alice> anyone want to play games later?
<bob> sure, sounds fun
"""

let model = MarkovText(
    chatLog,
    stateSize: 1,  // Lower state size for short messages
    wellFormed: false,
    sentenceSplitter: { text in
        text.components(separatedBy: .newlines)
            .compactMap { line -> String? in
                // Remove the username prefix
                guard let closeBracket = line.firstIndex(of: ">") else {
                    return nil
                }
                let message = line[line.index(after: closeBracket)...]
                    .trimmingCharacters(in: .whitespaces)
                return message.isEmpty ? nil : message
            }
    }
)

if let message = model.makeSentence() {
    print(message)
    // "anyone want to play games later?"
}
```

## See Also

- ``MarkovText/init(_:stateSize:retainOriginal:wellFormed:sentenceSplitter:wordSplitter:wordJoiner:)``
- ``Splitters``

//
//  MarkovMarkovText.swift
//  ChainLetter
//
//  Created by Claude on 1/9/26.
//

import Foundation

/// A high-level interface for generating text using Markov chains.
/// Combines corpus processing, model building, and sentence generation.
public struct MarkovText: Sendable {

    // MARK: - Properties

    /// The number of words that make up a state in the Markov chain
    public let stateSize: Int

    /// The underlying Markov chain model
    public private(set) var chain: Chain

    /// The parsed corpus as word lists (nil if retainOriginal is false)
    private let parsedSentences: [[String]]?

    /// The rejoined corpus text for overlap checking (nil if retainOriginal is false)
    private let rejoinedText: String?

    // MARK: - Customization Closures

    /// Function to split text into sentences
    public let sentenceSplitter: @Sendable (String) -> [String]

    /// Function to split a sentence into words
    public let wordSplitter: @Sendable (String) -> [String]

    /// Function to join words into a sentence
    public let wordJoiner: @Sendable ([String]) -> String

    // MARK: - Default Implementations

    /// Default sentence splitter using Splitters
    public static let defaultSentenceSplitter: @Sendable (String) -> [String] = { text in
        Splitters.splitIntoSentences(text)
    }

    /// Default word splitter (splits on whitespace)
    public static let defaultWordSplitter: @Sendable (String) -> [String] = { sentence in
        sentence.split(separator: " ").map(String.init)
    }

    /// Default word joiner (joins with spaces)
    public static let defaultWordJoiner: @Sendable ([String]) -> String = { words in
        words.joined(separator: " ")
    }

    // MARK: - Initialization

    /// Creates a MarkovText model from raw input text
    /// - Parameters:
    ///   - text: The input text to build the model from
    ///   - stateSize: The number of words that make up a state (default: 2)
    ///   - retainOriginal: Whether to keep the original corpus for overlap checking (default: true)
    ///   - wellFormed: Whether to filter out malformed sentences (default: true)
    ///   - sentenceSplitter: Custom function to split text into sentences
    ///   - wordSplitter: Custom function to split sentences into words
    ///   - wordJoiner: Custom function to join words into sentences
    public init(
        _ text: String,
        stateSize: Int = 2,
        retainOriginal: Bool = true,
        wellFormed: Bool = true,
        sentenceSplitter: @escaping @Sendable (String) -> [String] = MarkovText.defaultSentenceSplitter,
        wordSplitter: @escaping @Sendable (String) -> [String] = MarkovText.defaultWordSplitter,
        wordJoiner: @escaping @Sendable ([String]) -> String = MarkovText.defaultWordJoiner
    ) {
        self.stateSize = stateSize
        self.sentenceSplitter = sentenceSplitter
        self.wordSplitter = wordSplitter
        self.wordJoiner = wordJoiner

        // Generate the corpus
        let sentences = sentenceSplitter(text)
        var corpus: [[String]] = []

        for sentence in sentences {
            let words = wordSplitter(sentence)
            if MarkovText.testSentenceInput(words, wellFormed: wellFormed) {
                corpus.append(words)
            }
        }

        // Build the chain
        self.chain = Chain(corpus: corpus, stateSize: stateSize)

        // Store original if requested
        if retainOriginal {
            self.parsedSentences = corpus
            self.rejoinedText = corpus.map { wordJoiner($0) }.joined(separator: " ")
        } else {
            self.parsedSentences = nil
            self.rejoinedText = nil
        }
    }

    /// Creates a MarkovText model from a pre-built chain
    /// - Parameters:
    ///   - chain: The pre-built Markov chain
    ///   - parsedSentences: Optional parsed sentences for overlap checking
    ///   - wordJoiner: Custom function to join words into sentences
    public init(
        chain: Chain,
        parsedSentences: [[String]]? = nil,
        wordJoiner: @escaping @Sendable ([String]) -> String = MarkovText.defaultWordJoiner
    ) {
        self.stateSize = chain.stateSize
        self.chain = chain
        self.parsedSentences = parsedSentences
        self.wordJoiner = wordJoiner
        self.sentenceSplitter = MarkovText.defaultSentenceSplitter
        self.wordSplitter = MarkovText.defaultWordSplitter

        if let sentences = parsedSentences {
            self.rejoinedText = sentences.map { wordJoiner($0) }.joined(separator: " ")
        } else {
            self.rejoinedText = nil
        }
    }

    // MARK: - Sentence Validation

    /// Tests whether a sentence should be included in the corpus
    /// - Parameters:
    ///   - words: The words of the sentence
    ///   - wellFormed: Whether to enforce well-formedness rules
    /// - Returns: true if the sentence should be included
    private static func testSentenceInput(_ words: [String], wellFormed: Bool) -> Bool {
        // Reject empty sentences
        guard !words.isEmpty else { return false }

        if wellFormed {
            // Check that the sentence doesn't start with lowercase
            // (unless it's a single letter or special case)
            if let firstWord = words.first,
               let firstChar = firstWord.first,
               firstChar.isLowercase && firstWord.count > 1 {
                // Allow if it's a common lowercase starter
                let lowercaseStarters = ["i", "iPhone", "iPad", "iOS", "eBay", "iTunes"]
                if !lowercaseStarters.contains(firstWord) {
                    return false
                }
            }
        }

        return true
    }

    // MARK: - Generation

    /// Generates a sentence from the model
    /// - Parameters:
    ///   - initState: Optional starting state
    ///   - tries: Maximum number of attempts (default: 10)
    ///   - maxOverlapRatio: Maximum overlap as a ratio of sentence length (default: 0.7)
    ///   - maxOverlapTotal: Maximum absolute overlap in words (default: 15)
    ///   - testOutput: Whether to check for overlap with corpus (default: true)
    ///   - maxWords: Maximum words in the generated sentence
    ///   - minWords: Minimum words in the generated sentence
    /// - Returns: A generated sentence, or nil if generation failed
    public func makeSentence(
        initState: State? = nil,
        tries: Int = 10,
        maxOverlapRatio: Double = 0.7,
        maxOverlapTotal: Int = 15,
        testOutput: Bool = true,
        maxWords: Int? = nil,
        minWords: Int? = nil
    ) -> String? {
        for _ in 0..<tries {
            let words = chain.walk(from: initState)

            // Check word count constraints
            if let min = minWords, words.count < min { continue }
            if let max = maxWords, words.count > max { continue }

            // Check for overlap with original corpus
            if testOutput && rejoinedText != nil {
                if !testSentenceOutput(
                    words: words,
                    maxOverlapRatio: maxOverlapRatio,
                    maxOverlapTotal: maxOverlapTotal
                ) {
                    continue
                }
            }

            return wordJoiner(words)
        }

        return nil
    }

    /// Tests whether a generated sentence has too much overlap with the original corpus
    /// - Parameters:
    ///   - words: The generated words
    ///   - maxOverlapRatio: Maximum overlap as a ratio of sentence length
    ///   - maxOverlapTotal: Maximum absolute overlap in words
    /// - Returns: true if the sentence passes the overlap test
    private func testSentenceOutput(
        words: [String],
        maxOverlapRatio: Double,
        maxOverlapTotal: Int
    ) -> Bool {
        guard let rejoinedText = rejoinedText else { return true }
        guard !words.isEmpty else { return true }

        // Calculate the maximum overlap size
        let overlapRatio = Int((Double(words.count) * maxOverlapRatio).rounded())
        let overlapMax = min(maxOverlapTotal, overlapRatio)
        let overlapOver = overlapMax + 1

        // If the sentence is shorter than the overlap threshold, it passes
        guard words.count >= overlapOver else { return true }

        // Check all n-grams of size overlapOver
        for i in 0...(words.count - overlapOver) {
            let ngram = words[i..<(i + overlapOver)]
            let ngramText = wordJoiner(Array(ngram))

            if rejoinedText.contains(ngramText) {
                return false
            }
        }

        return true
    }

    /// Generates a sentence with a maximum character length
    /// - Parameters:
    ///   - maxChars: Maximum character length
    ///   - minChars: Minimum character length (default: 0)
    ///   - tries: Maximum number of attempts (default: 10)
    ///   - maxOverlapRatio: Maximum overlap with corpus as a ratio of sentence length (default: 0.7)
    ///   - maxOverlapTotal: Maximum absolute overlap with corpus in words (default: 15)
    ///   - testOutput: Whether to check for overlap with corpus (default: true)
    /// - Returns: A generated sentence within the character limits, or nil
    public func makeShortSentence(
        maxChars: Int,
        minChars: Int = 0,
        tries: Int = 10,
        maxOverlapRatio: Double = 0.7,
        maxOverlapTotal: Int = 15,
        testOutput: Bool = true
    ) -> String? {
        for _ in 0..<tries {
            if let sentence = makeSentence(
                tries: 1,
                maxOverlapRatio: maxOverlapRatio,
                maxOverlapTotal: maxOverlapTotal,
                testOutput: testOutput
            ) {
                if sentence.count >= minChars && sentence.count <= maxChars {
                    return sentence
                }
            }
        }
        return nil
    }

    /// Generates a sentence starting with a specific phrase
    /// - Parameters:
    ///   - beginning: The phrase to start with
    ///   - strict: If true, only uses states from actual sentence beginnings (default: true)
    ///   - tries: Maximum number of attempts (default: 10)
    ///   - maxOverlapRatio: Maximum overlap with corpus as a ratio of sentence length (default: 0.7)
    ///   - maxOverlapTotal: Maximum absolute overlap with corpus in words (default: 15)
    ///   - testOutput: Whether to check for overlap with corpus (default: true)
    /// - Returns: A generated sentence starting with the phrase, or nil
    public func makeSentenceWithStart(
        _ beginning: String,
        strict: Bool = true,
        tries: Int = 10,
        maxOverlapRatio: Double = 0.7,
        maxOverlapTotal: Int = 15,
        testOutput: Bool = true
    ) -> String? {
        let beginningWords = wordSplitter(beginning)

        guard beginningWords.count <= stateSize else {
            // Beginning is too long for the state size
            return nil
        }

        // Find matching states in the model
        var matchingStates: [State] = []

        if strict {
            // Only match states that actually begin sentences
            // The beginning must match the start of the sentence
            for (state, _) in chain.model {
                // Check if this state represents a sentence beginning
                let stateWords = state.words
                var isBeginningState = true

                // Check if the state starts with BEGIN tokens followed by beginning words
                for i in 0..<stateSize {
                    if i < (stateSize - beginningWords.count) {
                        // Should be BEGIN token
                        if stateWords[i] != State.beginToken {
                            isBeginningState = false
                            break
                        }
                    } else {
                        // Should match beginning words
                        let beginIdx = i - (stateSize - beginningWords.count)
                        if beginIdx < beginningWords.count && stateWords[i] != beginningWords[beginIdx] {
                            isBeginningState = false
                            break
                        }
                    }
                }

                if isBeginningState {
                    matchingStates.append(state)
                }
            }
        } else {
            // Match any state that ends with the beginning words
            for (state, _) in chain.model {
                let stateWords = state.words
                let suffix = Array(stateWords.suffix(beginningWords.count))
                if suffix == beginningWords {
                    matchingStates.append(state)
                }
            }
        }

        guard !matchingStates.isEmpty else { return nil }

        // Try to generate from matching states
        for _ in 0..<tries {
            guard let initState = matchingStates.randomElement() else { continue }

            if let sentence = makeSentence(
                initState: initState,
                tries: 1,
                maxOverlapRatio: maxOverlapRatio,
                maxOverlapTotal: maxOverlapTotal,
                testOutput: testOutput
            ) {
                // Prepend the beginning words if they're not in the generated output
                let sentenceWords = wordSplitter(sentence)

                // Skip empty results (can happen if the start word is often at END of sentences)
                if sentenceWords.isEmpty && !strict {
                    continue
                }

                if strict {
                    // For strict mode, prepend the beginning
                    return wordJoiner(beginningWords + sentenceWords)
                } else {
                    // For non-strict, include the beginning words + continuation
                    return wordJoiner(beginningWords + sentenceWords)
                }
            }
        }

        return nil
    }

    // MARK: - Compilation

    /// Compiles the chain for faster generation
    public mutating func compile() {
        chain.compile()
    }

    /// Whether the chain has been compiled
    public var compiled: Bool {
        chain.compiled
    }
}

// MARK: - Combining Models

extension MarkovText {
    /// Combines multiple MarkovText models into a single model with weighted transitions
    /// - Parameters:
    ///   - models: The models to combine (must all have the same state size)
    ///   - weights: Optional weights for each model (defaults to equal weights of 1.0)
    /// - Returns: A new MarkovText with combined transition probabilities
    /// - Throws: `Chain.CombineError` if models are incompatible
    public static func combine(_ models: [MarkovText], weights: [Double]? = nil) throws -> MarkovText {
        guard !models.isEmpty else {
            throw Chain.CombineError.emptyModels
        }

        // Extract chains and combine them
        let chains = models.map { $0.chain }
        let combinedChain = try Chain.combine(chains, weights: weights)

        // Combine parsed sentences if any models retained originals
        var combinedSentences: [[String]]? = nil
        let modelsWithSentences = models.compactMap { $0.parsedSentences }
        if !modelsWithSentences.isEmpty {
            combinedSentences = modelsWithSentences.flatMap { $0 }
        }

        return MarkovText(chain: combinedChain, parsedSentences: combinedSentences)
    }
}

// MARK: - Codable

extension MarkovText: Codable {
    private enum CodingKeys: String, CodingKey {
        case stateSize
        case chain
        case parsedSentences
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        _ = try container.decode(Int.self, forKey: .stateSize) // stateSize comes from chain
        let chain = try container.decode(Chain.self, forKey: .chain)
        let parsedSentences = try container.decodeIfPresent([[String]].self, forKey: .parsedSentences)

        self.init(chain: chain, parsedSentences: parsedSentences)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(stateSize, forKey: .stateSize)
        try container.encode(chain, forKey: .chain)
        try container.encodeIfPresent(parsedSentences, forKey: .parsedSentences)
    }
}

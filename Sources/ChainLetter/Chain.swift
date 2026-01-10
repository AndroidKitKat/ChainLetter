//
//  Chain.swift
//  ChainLetter
//
//  Created by Claude on 1/9/26.
//

import Foundation

/// A Markov chain representing a sequence model with explicit begin and end states.
/// Used to model processes like sentences that have natural beginnings and endings.
public struct Chain: Sendable {
    /// The number of words that make up a state
    public let stateSize: Int

    /// The transition model: maps states to possible next words with their counts
    public private(set) var model: [State: [String: Int]]

    /// Whether the model has been compiled for faster generation
    public private(set) var compiled: Bool = false

    /// Cached data for the begin state (used when not compiled)
    private var beginChoices: [String]?
    private var beginCumulativeDistribution: [Int]?

    /// Compiled model data: maps states to (words, cumulative frequencies)
    private var compiledModel: [State: ([String], [Int])]?

    // MARK: - Initialization

    /// Creates a new chain by building a model from a corpus
    /// - Parameters:
    ///   - corpus: A list of "runs" (e.g., sentences), where each run is a list of words
    ///   - stateSize: The number of words that make up a state (typically 2 or 3)
    public init(corpus: [[String]], stateSize: Int = 2) {
        self.stateSize = stateSize
        self.model = Chain.build(corpus: corpus, stateSize: stateSize)
        self.precomputeBeginState()
    }

    /// Creates a chain from a pre-built model
    /// - Parameters:
    ///   - model: The transition model dictionary
    ///   - stateSize: The number of words that make up a state
    public init(model: [State: [String: Int]], stateSize: Int) {
        self.stateSize = stateSize
        self.model = model
        self.precomputeBeginState()
    }

    // MARK: - Model Building

    /// Builds a transition model from a corpus
    /// - Parameters:
    ///   - corpus: A list of runs, where each run is a list of words
    ///   - stateSize: The number of words that make up a state
    /// - Returns: The transition model dictionary
    public static func build(corpus: [[String]], stateSize: Int) -> [State: [String: Int]] {
        var model: [State: [String: Int]] = [:]

        for run in corpus {
            // Pad the run with BEGIN tokens at the start and END token at the end
            let paddedRun = Array(repeating: State.beginToken, count: stateSize) + run + [State.endToken]

            // Create transitions for each position
            for i in 0..<(paddedRun.count - stateSize) {
                let stateWords = Array(paddedRun[i..<(i + stateSize)])
                let state = State(words: stateWords)
                let follow = paddedRun[i + stateSize]

                // Increment the count for this transition
                model[state, default: [:]][follow, default: 0] += 1
            }
        }

        return model
    }

    // MARK: - Precomputation

    /// Precomputes the cumulative distribution for the begin state
    /// This optimizes generation by caching the most commonly used state
    private mutating func precomputeBeginState() {
        let beginState = State.begin(size: stateSize)
        guard let transitions = model[beginState] else { return }

        let (choices, cumdist) = compileTransitions(transitions)
        beginChoices = choices
        beginCumulativeDistribution = cumdist
    }

    /// Converts a transitions dictionary to compiled format (words array + cumulative frequencies)
    private func compileTransitions(_ transitions: [String: Int]) -> ([String], [Int]) {
        let choices = Array(transitions.keys)
        var cumulative: [Int] = []
        var sum = 0
        for word in choices {
            sum += transitions[word]!
            cumulative.append(sum)
        }
        return (choices, cumulative)
    }

    // MARK: - Generation

    /// Selects the next word from the given state using weighted random selection
    /// - Parameter state: The current state
    /// - Returns: The selected next word, or nil if the state doesn't exist in the model
    public func move(from state: State) -> String? {
        let choices: [String]
        let cumdist: [Int]

        if compiled, let compiledData = compiledModel?[state] {
            // Use compiled model
            (choices, cumdist) = compiledData
        } else if state == State.begin(size: stateSize),
                  let cachedChoices = beginChoices,
                  let cachedCumdist = beginCumulativeDistribution {
            // Use cached begin state
            choices = cachedChoices
            cumdist = cachedCumdist
        } else if let transitions = model[state] {
            // Compute on the fly
            (choices, cumdist) = compileTransitions(transitions)
        } else {
            return nil
        }

        guard let total = cumdist.last, total > 0 else { return nil }

        // Weighted random selection using binary search
        let r = Int.random(in: 0..<total)
        let index = binarySearch(cumdist, for: r)
        return choices[index]
    }

    /// Binary search to find the first index where cumdist[index] > value
    private func binarySearch(_ cumdist: [Int], for value: Int) -> Int {
        var low = 0
        var high = cumdist.count

        while low < high {
            let mid = (low + high) / 2
            if cumdist[mid] <= value {
                low = mid + 1
            } else {
                high = mid
            }
        }
        return low
    }

    /// Generates a sequence of words by walking the chain from the given state
    /// - Parameter initState: The starting state (defaults to begin state)
    /// - Returns: An array of generated words (not including BEGIN/END tokens)
    public func walk(from initState: State? = nil) -> [String] {
        var state = initState ?? State.begin(size: stateSize)
        var result: [String] = []

        while true {
            guard let nextWord = move(from: state) else { break }
            if nextWord == State.endToken { break }
            result.append(nextWord)
            state = state.appending(nextWord)
        }

        return result
    }

    // MARK: - Compilation

    /// Compiles the model for faster generation by precomputing cumulative distributions
    public mutating func compile() {
        guard !compiled else { return }

        var compiled: [State: ([String], [Int])] = [:]
        for (state, transitions) in model {
            compiled[state] = compileTransitions(transitions)
        }
        compiledModel = compiled
        self.compiled = true
    }
}

// MARK: - Combining Models

extension Chain {
    /// Error thrown when combining chains fails
    public enum CombineError: Error, CustomStringConvertible {
        case emptyModels
        case mismatchedStateSizes([Int])
        case compiledChainNotSupported

        public var description: String {
            switch self {
            case .emptyModels:
                return "Cannot combine empty array of models"
            case .mismatchedStateSizes(let sizes):
                return "All chains must have the same state size. Found: \(sizes)"
            case .compiledChainNotSupported:
                return "Cannot combine compiled chains"
            }
        }
    }

    /// Combines multiple chains into a single chain with weighted transitions
    /// - Parameters:
    ///   - chains: The chains to combine (must all have the same state size)
    ///   - weights: Optional weights for each chain (defaults to equal weights of 1.0)
    /// - Returns: A new chain with combined transition probabilities
    /// - Throws: `CombineError` if chains are incompatible
    public static func combine(_ chains: [Chain], weights: [Double]? = nil) throws -> Chain {
        guard !chains.isEmpty else {
            throw CombineError.emptyModels
        }

        // Validate no compiled chains
        if chains.contains(where: { $0.compiled }) {
            throw CombineError.compiledChainNotSupported
        }

        // Validate all chains have the same state size
        let stateSizes = chains.map { $0.stateSize }
        guard Set(stateSizes).count == 1 else {
            throw CombineError.mismatchedStateSizes(stateSizes)
        }

        let stateSize = chains[0].stateSize

        // Default to equal weights if not provided
        let effectiveWeights: [Double]
        if let weights = weights {
            guard weights.count == chains.count else {
                fatalError("weights count (\(weights.count)) must match chains count (\(chains.count))")
            }
            effectiveWeights = weights
        } else {
            effectiveWeights = Array(repeating: 1.0, count: chains.count)
        }

        // Combine the models
        var combinedModel: [State: [String: Int]] = [:]

        for (chain, weight) in zip(chains, effectiveWeights) {
            for (state, transitions) in chain.model {
                var current = combinedModel[state] ?? [:]
                for (word, count) in transitions {
                    let weightedCount = Int((Double(count) * weight).rounded())
                    current[word, default: 0] += weightedCount
                }
                combinedModel[state] = current
            }
        }

        return Chain(model: combinedModel, stateSize: stateSize)
    }
}

// MARK: - Codable

extension Chain: Codable {
    private enum CodingKeys: String, CodingKey {
        case stateSize
        case model
    }

    /// Helper struct for encoding model entries (since State can't be a JSON key directly)
    private struct ModelEntry: Codable {
        let state: State
        let transitions: [String: Int]
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let stateSize = try container.decode(Int.self, forKey: .stateSize)
        let entries = try container.decode([ModelEntry].self, forKey: .model)

        // Reconstruct the model dictionary
        var model: [State: [String: Int]] = [:]
        for entry in entries {
            model[entry.state] = entry.transitions
        }

        self.init(model: model, stateSize: stateSize)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(stateSize, forKey: .stateSize)

        // Convert model to array of entries for JSON compatibility
        let entries = model.map { ModelEntry(state: $0.key, transitions: $0.value) }
        try container.encode(entries, forKey: .model)
    }
}

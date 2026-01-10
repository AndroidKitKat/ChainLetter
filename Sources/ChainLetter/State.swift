//
//  State.swift
//  ChainLetter
//
//  Created by Claude on 1/9/26.
//

import Foundation

/// Represents a state in the Markov chain, consisting of a sequence of words.
/// Used as dictionary keys to map states to their possible transitions.
public struct State: Hashable, Codable, Sendable {
    public let words: [String]

    /// Special token marking the beginning of a sequence
    public static let beginToken = "___BEGIN__"

    /// Special token marking the end of a sequence
    public static let endToken = "___END__"

    /// Creates a state with the given words
    public init(words: [String]) {
        self.words = words
    }

    /// Creates a begin state with the specified number of begin tokens
    public static func begin(size: Int) -> State {
        State(words: Array(repeating: beginToken, count: size))
    }

    /// Creates a new state by dropping the first word and appending a new word.
    /// This implements the sliding window behavior for Markov chain traversal.
    public func appending(_ word: String) -> State {
        State(words: Array(words.dropFirst()) + [word])
    }

    /// The number of words in this state (equivalent to state_size)
    public var size: Int {
        words.count
    }
}

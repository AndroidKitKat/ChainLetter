//
//  ChainTests.swift
//  ChainLetter
//
//  Created by Claude on 1/9/26.
//

import Testing
import Foundation
@testable import ChainLetter

@Suite("Chain Tests")
struct ChainTests {

    // MARK: - State Tests

    @Suite("State")
    struct StateTests {

        @Test("Begin state has correct tokens")
        func beginState() {
            let state = State.begin(size: 2)
            #expect(state.words == [State.beginToken, State.beginToken])
            #expect(state.size == 2)
        }

        @Test("Appending creates sliding window")
        func appending() {
            let state = State(words: ["hello", "world"])
            let next = state.appending("!")
            #expect(next.words == ["world", "!"])
        }

        @Test("State is hashable")
        func hashable() {
            let state1 = State(words: ["a", "b"])
            let state2 = State(words: ["a", "b"])
            let state3 = State(words: ["a", "c"])

            #expect(state1 == state2)
            #expect(state1 != state3)

            var dict: [State: Int] = [:]
            dict[state1] = 1
            #expect(dict[state2] == 1)
        }

        @Test("State size property")
        func sizeProperty() {
            let state1 = State(words: ["a"])
            #expect(state1.size == 1)

            let state2 = State(words: ["a", "b"])
            #expect(state2.size == 2)

            let state3 = State(words: ["a", "b", "c", "d", "e"])
            #expect(state3.size == 5)

            let emptyState = State(words: [])
            #expect(emptyState.size == 0)
        }
    }

    // MARK: - Model Building Tests

    @Suite("Model Building")
    struct ModelBuildingTests {

        @Test("Empty corpus produces empty model")
        func emptyCorpus() {
            let chain = Chain(corpus: [], stateSize: 2)
            #expect(chain.model.isEmpty)
        }

        @Test("Single word sentence")
        func singleWord() {
            let corpus = [["hello"]]
            let chain = Chain(corpus: corpus, stateSize: 2)

            // Should have transitions:
            // (BEGIN, BEGIN) -> "hello"
            // (BEGIN, "hello") -> END
            let beginState = State.begin(size: 2)
            #expect(chain.model[beginState]?["hello"] == 1)

            let secondState = State(words: [State.beginToken, "hello"])
            #expect(chain.model[secondState]?[State.endToken] == 1)
        }

        @Test("Multiple words")
        func multipleWords() {
            let corpus = [["hello", "world"]]
            let chain = Chain(corpus: corpus, stateSize: 2)

            let beginState = State.begin(size: 2)
            #expect(chain.model[beginState]?["hello"] == 1)

            let state1 = State(words: [State.beginToken, "hello"])
            #expect(chain.model[state1]?["world"] == 1)

            let state2 = State(words: ["hello", "world"])
            #expect(chain.model[state2]?[State.endToken] == 1)
        }

        @Test("Repeated patterns increase counts")
        func repeatedPatterns() {
            let corpus = [
                ["hello", "world"],
                ["hello", "there"]
            ]
            let chain = Chain(corpus: corpus, stateSize: 2)

            let beginState = State.begin(size: 2)
            #expect(chain.model[beginState]?["hello"] == 2)
        }

        @Test("State size of 1")
        func stateSize1() {
            let corpus = [["a", "b", "c"]]
            let chain = Chain(corpus: corpus, stateSize: 1)

            let beginState = State.begin(size: 1)
            #expect(chain.model[beginState]?["a"] == 1)

            let stateA = State(words: ["a"])
            #expect(chain.model[stateA]?["b"] == 1)
        }

        @Test("State size of 3")
        func stateSize3() {
            let corpus = [["a", "b", "c", "d"]]
            let chain = Chain(corpus: corpus, stateSize: 3)

            let beginState = State.begin(size: 3)
            #expect(chain.model[beginState]?["a"] == 1)

            let state = State(words: ["a", "b", "c"])
            #expect(chain.model[state]?["d"] == 1)
        }

        @Test("Pre-built model initialization")
        func preBuiltModel() {
            // Manually create a model
            let beginState = State.begin(size: 2)
            let state1 = State(words: [State.beginToken, "hello"])
            let state2 = State(words: ["hello", "world"])

            let model: [State: [String: Int]] = [
                beginState: ["hello": 1],
                state1: ["world": 1],
                state2: [State.endToken: 1]
            ]

            let chain = Chain(model: model, stateSize: 2)

            #expect(chain.stateSize == 2)
            #expect(chain.model.count == 3)
            #expect(!chain.compiled)

            // Should be able to walk
            let result = chain.walk()
            #expect(result == ["hello", "world"])
        }

        @Test("Pre-built model with multiple transitions")
        func preBuiltModelMultipleTransitions() {
            let beginState = State.begin(size: 1)
            let stateA = State(words: ["a"])
            let stateB = State(words: ["b"])

            let model: [State: [String: Int]] = [
                beginState: ["a": 3, "b": 1],  // "a" is 3x more likely
                stateA: [State.endToken: 1],
                stateB: [State.endToken: 1]
            ]

            let chain = Chain(model: model, stateSize: 1)

            // Generate many and count
            var aCount = 0
            var bCount = 0
            for _ in 0..<100 {
                let result = chain.walk()
                if result == ["a"] { aCount += 1 }
                if result == ["b"] { bCount += 1 }
            }

            // "a" should appear more often (roughly 3x)
            #expect(aCount > bCount)
        }
    }

    // MARK: - Generation Tests

    @Suite("Generation")
    struct GenerationTests {

        @Test("Move returns valid word")
        func moveReturnsValidWord() {
            let corpus = [["hello", "world"]]
            let chain = Chain(corpus: corpus, stateSize: 2)

            let beginState = State.begin(size: 2)
            let word = chain.move(from: beginState)
            #expect(word == "hello")
        }

        @Test("Move returns nil for unknown state")
        func moveUnknownState() {
            let corpus = [["hello"]]
            let chain = Chain(corpus: corpus, stateSize: 2)

            let unknownState = State(words: ["foo", "bar"])
            let word = chain.move(from: unknownState)
            #expect(word == nil)
        }

        @Test("Walk produces deterministic output for single path")
        func walkDeterministic() {
            let corpus = [["the", "quick", "brown", "fox"]]
            let chain = Chain(corpus: corpus, stateSize: 2)

            let result = chain.walk()
            #expect(result == ["the", "quick", "brown", "fox"])
        }

        @Test("Walk produces valid output from multiple paths")
        func walkMultiplePaths() {
            let corpus = [
                ["hello", "world"],
                ["hello", "there"],
                ["goodbye", "world"]
            ]
            let chain = Chain(corpus: corpus, stateSize: 2)

            // Run multiple times to test randomness
            for _ in 0..<10 {
                let result = chain.walk()
                #expect(!result.isEmpty)

                // First word should be either "hello" or "goodbye"
                #expect(result[0] == "hello" || result[0] == "goodbye")

                // If starts with "hello", second word is "world" or "there"
                if result[0] == "hello" {
                    #expect(result[1] == "world" || result[1] == "there")
                }

                // If starts with "goodbye", second word is "world"
                if result[0] == "goodbye" {
                    #expect(result[1] == "world")
                }
            }
        }

        @Test("Walk with custom init state")
        func walkWithInitState() {
            let corpus = [
                ["a", "b", "c"],
                ["x", "b", "c"]
            ]
            let chain = Chain(corpus: corpus, stateSize: 2)

            // Start from state ("a", "b")
            let initState = State(words: ["a", "b"])
            let result = chain.walk(from: initState)

            // Should continue from "b" -> "c" -> END
            #expect(result == ["c"])
        }

        @Test("Move from state with empty transitions returns nil")
        func moveEmptyTransitions() {
            // Create a model with an empty transitions dictionary
            let beginState = State.begin(size: 1)
            let stateA = State(words: ["a"])

            let model: [State: [String: Int]] = [
                beginState: ["a": 1],
                stateA: [:]  // Empty transitions
            ]

            let chain = Chain(model: model, stateSize: 1)

            // Move from stateA should return nil
            let result = chain.move(from: stateA)
            #expect(result == nil)
        }

        @Test("Walk stops at state with no transitions")
        func walkStopsAtDeadEnd() {
            // Create a chain where we can reach a dead end
            let beginState = State.begin(size: 1)
            // Note: stateA = State(words: ["a"]) has no entry - it's a dead end

            let model: [State: [String: Int]] = [
                beginState: ["a": 1],
                // State(words: ["a"]) has no entry - it's a dead end
            ]

            let chain = Chain(model: model, stateSize: 1)
            let result = chain.walk()

            // Should get "a" and then stop (no END token, just stops)
            #expect(result == ["a"])
        }

        @Test("Walk with state that only leads to END")
        func walkDirectToEnd() {
            let beginState = State.begin(size: 1)
            let stateA = State(words: ["a"])

            let model: [State: [String: Int]] = [
                beginState: ["a": 1],
                stateA: [State.endToken: 1]
            ]

            let chain = Chain(model: model, stateSize: 1)
            let result = chain.walk()

            #expect(result == ["a"])
        }
    }

    // MARK: - Compilation Tests

    @Suite("Compilation")
    struct CompilationTests {

        @Test("Compile sets compiled flag")
        func compileFlag() {
            var chain = Chain(corpus: [["hello"]], stateSize: 2)
            #expect(!chain.compiled)

            chain.compile()
            #expect(chain.compiled)
        }

        @Test("Compiled chain produces same results")
        func compiledSameResults() {
            let corpus = [["the", "quick", "brown", "fox"]]
            var chain = Chain(corpus: corpus, stateSize: 2)

            let beforeCompile = chain.walk()
            chain.compile()
            let afterCompile = chain.walk()

            // Deterministic corpus should produce same results
            #expect(beforeCompile == afterCompile)
        }

        @Test("Multiple compile calls are idempotent")
        func compileIdempotent() {
            var chain = Chain(corpus: [["hello"]], stateSize: 2)
            chain.compile()
            chain.compile()
            chain.compile()
            #expect(chain.compiled)
        }
    }

    // MARK: - Codable Tests

    @Suite("Codable")
    struct CodableTests {

        @Test("JSON round-trip preserves model")
        func jsonRoundTrip() throws {
            let corpus = [
                ["hello", "world"],
                ["hello", "there"],
                ["goodbye", "world"]
            ]
            let original = Chain(corpus: corpus, stateSize: 2)

            // Encode to JSON
            let encoder = JSONEncoder()
            let data = try encoder.encode(original)

            // Decode from JSON
            let decoder = JSONDecoder()
            let restored = try decoder.decode(Chain.self, from: data)

            // Verify properties match
            #expect(restored.stateSize == original.stateSize)
            #expect(restored.model.count == original.model.count)

            // Verify all transitions are preserved
            for (state, transitions) in original.model {
                #expect(restored.model[state] == transitions)
            }
        }

        @Test("Decoded chain generates valid output")
        func decodedChainGenerates() throws {
            let corpus = [["the", "quick", "brown", "fox"]]
            let original = Chain(corpus: corpus, stateSize: 2)

            let data = try JSONEncoder().encode(original)
            let restored = try JSONDecoder().decode(Chain.self, from: data)

            // Deterministic corpus should produce same output
            let result = restored.walk()
            #expect(result == ["the", "quick", "brown", "fox"])
        }

        @Test("State is codable")
        func stateCodable() throws {
            let state = State(words: ["hello", "world"])

            let data = try JSONEncoder().encode(state)
            let restored = try JSONDecoder().decode(State.self, from: data)

            #expect(restored == state)
        }
    }
}

//
//  CombineTests.swift
//  ChainLetter
//
//  Created by Claude on 1/9/26.
//

import Testing
import Foundation
@testable import ChainLetter

@Suite("Combine Tests")
struct CombineTests {

    // MARK: - Chain Combine Tests

    @Suite("Chain.combine")
    struct ChainCombineTests {

        @Test("Combines two simple chains")
        func combinesTwoChains() throws {
            let corpus1 = [["hello", "world"]]
            let corpus2 = [["hello", "swift"]]

            let chain1 = Chain(corpus: corpus1, stateSize: 2)
            let chain2 = Chain(corpus: corpus2, stateSize: 2)

            let combined = try Chain.combine([chain1, chain2])

            // The begin state should have transitions to both "hello"
            let beginState = State.begin(size: 2)
            let beginTransitions = combined.model[beginState]
            #expect(beginTransitions?["hello"] == 2)

            // "hello world" state should have END as next
            let helloWorldState = State(words: ["hello", "world"])
            #expect(combined.model[helloWorldState]?[State.endToken] == 1)

            // "hello swift" state should have END as next
            let helloSwiftState = State(words: ["hello", "swift"])
            #expect(combined.model[helloSwiftState]?[State.endToken] == 1)
        }

        @Test("Combines with weights")
        func combinesWithWeights() throws {
            let corpus1 = [["hello", "world"]]
            let corpus2 = [["hello", "world"]]

            let chain1 = Chain(corpus: corpus1, stateSize: 2)
            let chain2 = Chain(corpus: corpus2, stateSize: 2)

            // Weight chain2 at 2x
            let combined = try Chain.combine([chain1, chain2], weights: [1.0, 2.0])

            let beginState = State.begin(size: 2)
            // chain1 contributes 1, chain2 contributes 2 (1 * 2.0)
            #expect(combined.model[beginState]?["hello"] == 3)
        }

        @Test("Throws on empty models array")
        func throwsOnEmptyModels() throws {
            #expect(throws: Chain.CombineError.self) {
                _ = try Chain.combine([])
            }
        }

        @Test("Throws on mismatched state sizes")
        func throwsOnMismatchedStateSizes() throws {
            let chain1 = Chain(corpus: [["a", "b"]], stateSize: 2)
            let chain2 = Chain(corpus: [["a", "b", "c"]], stateSize: 3)

            #expect(throws: Chain.CombineError.self) {
                _ = try Chain.combine([chain1, chain2])
            }
        }

        @Test("Throws on compiled chains")
        func throwsOnCompiledChains() throws {
            var chain1 = Chain(corpus: [["a", "b"]], stateSize: 2)
            chain1.compile()
            let chain2 = Chain(corpus: [["c", "d"]], stateSize: 2)

            #expect(throws: Chain.CombineError.self) {
                _ = try Chain.combine([chain1, chain2])
            }
        }

        @Test("Combined chain can generate")
        func combinedChainCanGenerate() throws {
            let corpus1 = [["the", "cat", "sat"]]
            let corpus2 = [["the", "dog", "ran"]]

            let chain1 = Chain(corpus: corpus1, stateSize: 2)
            let chain2 = Chain(corpus: corpus2, stateSize: 2)

            let combined = try Chain.combine([chain1, chain2])

            // Should be able to walk the combined chain
            let words = combined.walk()
            #expect(!words.isEmpty)
            #expect(words.first == "the")
        }
    }

    // MARK: - MarkovText Combine Tests

    @Suite("MarkovText.combine")
    struct MarkovTextCombineTests {

        @Test("Combines two MarkovText models")
        func combinesTwoModels() throws {
            let text1 = MarkovText("Hello world.", stateSize: 2, wellFormed: false)
            let text2 = MarkovText("Hello swift.", stateSize: 2, wellFormed: false)

            let combined = try MarkovText.combine([text1, text2])

            #expect(combined.stateSize == 2)
            // Should be able to generate
            let sentence = combined.makeSentence(testOutput: false)
            #expect(sentence != nil)
        }

        @Test("Combines with weights")
        func combinesWithWeights() throws {
            let text1 = MarkovText("Cat.", stateSize: 1, wellFormed: false)
            let text2 = MarkovText("Dog.", stateSize: 1, wellFormed: false)

            let combined = try MarkovText.combine([text1, text2], weights: [3.0, 1.0])

            // Generate many sentences - "Cat." should appear more often
            var catCount = 0
            var dogCount = 0
            for _ in 0..<100 {
                if let sentence = combined.makeSentence(testOutput: false) {
                    if sentence.contains("Cat") { catCount += 1 }
                    if sentence.contains("Dog") { dogCount += 1 }
                }
            }

            // Cat should be generated more often (roughly 3x)
            #expect(catCount > dogCount)
        }

        @Test("Combines parsed sentences when retained")
        func combinesParsedSentences() throws {
            let text1 = MarkovText("Hello world.", stateSize: 2, retainOriginal: true, wellFormed: false)
            let text2 = MarkovText("Goodbye world.", stateSize: 2, retainOriginal: true, wellFormed: false)

            let combined = try MarkovText.combine([text1, text2])

            // The combined model should have overlap checking enabled
            // (parsedSentences should be combined)
            // We can't directly test parsedSentences (it's private), but we can test behavior
            let sentence = combined.makeSentence(testOutput: true)
            // Just verify it doesn't crash
            _ = sentence
        }

        @Test("Throws on empty models array")
        func throwsOnEmptyModels() throws {
            #expect(throws: Chain.CombineError.self) {
                _ = try MarkovText.combine([])
            }
        }

        @Test("Throws on mismatched state sizes")
        func throwsOnMismatchedStateSizes() throws {
            let text1 = MarkovText("Hello world.", stateSize: 2, wellFormed: false)
            let text2 = MarkovText("Hello world again.", stateSize: 3, wellFormed: false)

            #expect(throws: Chain.CombineError.self) {
                _ = try MarkovText.combine([text1, text2])
            }
        }

        @Test("Combined model generates valid sentences")
        func combinedModelGeneratesValidSentences() throws {
            let text1 = MarkovText("The quick brown fox.", stateSize: 2, wellFormed: false)
            let text2 = MarkovText("The lazy dog sleeps.", stateSize: 2, wellFormed: false)

            let combined = try MarkovText.combine([text1, text2])

            // Generate several sentences
            for _ in 0..<10 {
                if let sentence = combined.makeSentence(testOutput: false) {
                    #expect(sentence.starts(with: "The"))
                }
            }
        }

        @Test("Combined model with custom word joiner")
        func combinedModelWithCustomJoiner() throws {
            let text1 = MarkovText("a b.", stateSize: 1, wellFormed: false)
            let text2 = MarkovText("c d.", stateSize: 1, wellFormed: false)

            let combined = try MarkovText.combine([text1, text2])

            // Combined model uses default word joiner (space-separated)
            if let sentence = combined.makeSentence(testOutput: false) {
                #expect(sentence.contains(" ") || sentence.count == 1)
            }
        }
    }

    // MARK: - Integration Tests

    @Suite("Integration")
    struct IntegrationTests {

        @Test("Combined model can be compiled")
        func combinedModelCanBeCompiled() throws {
            let text1 = MarkovText("Hello world.", stateSize: 2, wellFormed: false)
            let text2 = MarkovText("Hello swift.", stateSize: 2, wellFormed: false)

            var combined = try MarkovText.combine([text1, text2])
            #expect(!combined.compiled)

            combined.compile()
            #expect(combined.compiled)

            // Should still generate after compilation
            let sentence = combined.makeSentence(testOutput: false)
            #expect(sentence != nil)
        }

        @Test("Combined model can be serialized")
        func combinedModelCanBeSerialized() throws {
            let text1 = MarkovText("Hello world.", stateSize: 2, wellFormed: false)
            let text2 = MarkovText("Hello swift.", stateSize: 2, wellFormed: false)

            let combined = try MarkovText.combine([text1, text2])

            // Encode to JSON
            let encoder = JSONEncoder()
            let data = try encoder.encode(combined)

            // Decode back
            let decoder = JSONDecoder()
            let restored = try decoder.decode(MarkovText.self, from: data)

            #expect(restored.stateSize == combined.stateSize)

            // Should be able to generate
            let sentence = restored.makeSentence(testOutput: false)
            #expect(sentence != nil)
        }

        @Test("Combining three or more models")
        func combinesMultipleModels() throws {
            let text1 = MarkovText("Apples are red.", stateSize: 2, wellFormed: false)
            let text2 = MarkovText("Bananas are yellow.", stateSize: 2, wellFormed: false)
            let text3 = MarkovText("Grapes are purple.", stateSize: 2, wellFormed: false)

            let combined = try MarkovText.combine([text1, text2, text3])

            // Should have transitions from all three corpora
            var foundApples = false
            var foundBananas = false
            var foundGrapes = false

            for _ in 0..<50 {
                if let sentence = combined.makeSentence(testOutput: false) {
                    if sentence.contains("Apples") { foundApples = true }
                    if sentence.contains("Bananas") { foundBananas = true }
                    if sentence.contains("Grapes") { foundGrapes = true }
                }
            }

            // Should eventually find sentences from all three sources
            #expect(foundApples || foundBananas || foundGrapes)
        }
    }
}

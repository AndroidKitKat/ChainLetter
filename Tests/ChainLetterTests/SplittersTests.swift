//
//  SplittersTests.swift
//  ChainLetter
//
//  Created by Michael Eisemann on 1/9/26.
//

import Testing
import Foundation
@testable import ChainLetter

@Suite("Splitters Tests")
struct SplittersTests {

    // MARK: - Initialism Tests

    @Suite("Initialism Detection")
    struct InitialismTests {

        @Test("U.S.A. is recognized as initialism")
        func usaInitialism() {
            let text = "U.S.A."
            #expect(text.wholeMatch(of: Splitters.initialism) != nil)
        }

        @Test("U.S. is recognized as initialism")
        func usInitialism() {
            let text = "U.S."
            #expect(text.wholeMatch(of: Splitters.initialism) != nil)
        }

        @Test("Ph.D. is recognized as initialism")
        func phdInitialism() {
            let text = "Ph.D."
            #expect(text.wholeMatch(of: Splitters.initialism) != nil)
        }

        @Test("Regular word is not an initialism")
        func regularWord() {
            let text = "Hello."
            #expect(text.wholeMatch(of: Splitters.initialism) == nil)
        }
    }

    // MARK: - Abbreviation Tests

    @Suite("Abbreviation Detection")
    struct AbbreviationTests {

        @Test("Single letter initial is abbreviation")
        func singleLetterInitial() {
            #expect(Splitters.isAbbreviation("A."))
            #expect(Splitters.isAbbreviation("B."))
            #expect(Splitters.isAbbreviation("Z."))
        }

        @Test("Common titles are abbreviations")
        func titles() {
            #expect(Splitters.isAbbreviation("Mr."))
            #expect(Splitters.isAbbreviation("Mrs."))
            #expect(Splitters.isAbbreviation("Dr."))
            #expect(Splitters.isAbbreviation("Prof."))
            #expect(Splitters.isAbbreviation("Sen."))
            #expect(Splitters.isAbbreviation("Rep."))
        }

        @Test("State abbreviations are recognized")
        func states() {
            #expect(Splitters.isAbbreviation("Calif."))
            #expect(Splitters.isAbbreviation("Fla."))
            #expect(Splitters.isAbbreviation("Mass."))
            #expect(Splitters.isAbbreviation("Pa."))
        }

        @Test("Lowercase abbreviations are recognized")
        func lowercaseAbbreviations() {
            #expect(Splitters.isAbbreviation("etc."))
            #expect(Splitters.isAbbreviation("vs."))
            #expect(Splitters.isAbbreviation("viz."))
            #expect(Splitters.isAbbreviation("al."))
        }

        @Test("Month abbreviations are recognized")
        func months() {
            #expect(Splitters.isAbbreviation("Jan."))
            #expect(Splitters.isAbbreviation("Feb."))
            #expect(Splitters.isAbbreviation("Sept."))
            #expect(Splitters.isAbbreviation("Dec."))
        }

        @Test("Street abbreviations are recognized")
        func streets() {
            #expect(Splitters.isAbbreviation("Ave."))
            #expect(Splitters.isAbbreviation("Blvd."))
            #expect(Splitters.isAbbreviation("St."))
            #expect(Splitters.isAbbreviation("Rd."))
        }

        @Test("Regular words are not abbreviations")
        func regularWords() {
            #expect(!Splitters.isAbbreviation("Hello."))
            #expect(!Splitters.isAbbreviation("World."))
            #expect(!Splitters.isAbbreviation("Test."))
        }

        @Test("Words without dots are not abbreviations")
        func noDot() {
            #expect(!Splitters.isAbbreviation("Mr"))
            #expect(!Splitters.isAbbreviation("etc"))
        }
    }

    // MARK: - Sentence Ender Tests

    @Suite("Sentence Ender Detection")
    struct SentenceEnderTests {

        @Test("Question mark is sentence ender")
        func questionMark() {
            #expect(Splitters.isSentenceEnder("Why?"))
            #expect(Splitters.isSentenceEnder("really?"))
        }

        @Test("Exclamation mark is sentence ender")
        func exclamationMark() {
            #expect(Splitters.isSentenceEnder("Stop!"))
            #expect(Splitters.isSentenceEnder("Amazing!"))
        }

        @Test("Period after regular word is sentence ender")
        func periodAfterWord() {
            #expect(Splitters.isSentenceEnder("done."))
            #expect(Splitters.isSentenceEnder("Hello."))
        }

        @Test("Abbreviations are not sentence enders")
        func abbreviations() {
            #expect(!Splitters.isSentenceEnder("Mr."))
            #expect(!Splitters.isSentenceEnder("Dr."))
            #expect(!Splitters.isSentenceEnder("etc."))
            #expect(!Splitters.isSentenceEnder("Jan."))
        }

        @Test("Initialisms are not sentence enders")
        func initialisms() {
            #expect(!Splitters.isSentenceEnder("U.S.A."))
            #expect(!Splitters.isSentenceEnder("Ph.D."))
        }

        @Test("Words with multiple uppercase letters are sentence enders")
        func multipleUppercase() {
            #expect(Splitters.isSentenceEnder("NASA"))
            #expect(Splitters.isSentenceEnder("FBI"))
            #expect(Splitters.isSentenceEnder("USA"))
        }

        @Test("Single letter initial is not sentence ender")
        func singleLetterInitial() {
            #expect(!Splitters.isSentenceEnder("A."))
            #expect(!Splitters.isSentenceEnder("B."))
        }
    }

    // MARK: - Sentence Splitting Tests

    @Suite("Sentence Splitting")
    struct SentenceSplittingTests {

        @Test("Simple sentence")
        func simpleSentence() {
            let text = "This is a test."
            let result = Splitters.splitIntoSentences(text)
            #expect(result.count == 1)
            #expect(result[0] == "This is a test.")
        }

        @Test("Two simple sentences")
        func twoSentences() {
            let text = "First sentence. Second sentence."
            let result = Splitters.splitIntoSentences(text)
            #expect(result.count == 2)
            #expect(result[0] == "First sentence.")
            #expect(result[1] == "Second sentence.")
        }

        @Test("Multiple sentences")
        func multipleSentences() {
            let text = "One. Two. Three. Four."
            let result = Splitters.splitIntoSentences(text)
            #expect(result.count == 4)
            #expect(result == ["One.", "Two.", "Three.", "Four."])
        }

        @Test("Sentences with question marks")
        func questionMarks() {
            let text = "How are you? I am fine."
            let result = Splitters.splitIntoSentences(text)
            #expect(result.count == 2)
            #expect(result[0] == "How are you?")
            #expect(result[1] == "I am fine.")
        }

        @Test("Sentences with exclamation marks")
        func exclamationMarks() {
            let text = "Watch out! Be careful."
            let result = Splitters.splitIntoSentences(text)
            #expect(result.count == 2)
            #expect(result[0] == "Watch out!")
            #expect(result[1] == "Be careful.")
        }

        @Test("Mixed punctuation")
        func mixedPunctuation() {
            let text = "Is it? Yes! Maybe. No."
            let result = Splitters.splitIntoSentences(text)
            #expect(result.count == 4)
            #expect(result == ["Is it?", "Yes!", "Maybe.", "No."])
        }

        @Test("Sentences with abbreviations")
        func withAbbreviations() {
            let text = "Mr. Smith went to Dr. Jones. He was sick."
            let result = Splitters.splitIntoSentences(text)
            #expect(result.count == 2)
            #expect(result[0] == "Mr. Smith went to Dr. Jones.")
            #expect(result[1] == "He was sick.")
        }

        @Test("Sentences with initials")
        func withInitials() {
            let text = "A. B. Smith is here. He arrived today."
            let result = Splitters.splitIntoSentences(text)
            #expect(result.count == 2)
            #expect(result[0] == "A. B. Smith is here.")
            #expect(result[1] == "He arrived today.")
        }

        @Test("Sentences with U.S.")
        func withUS() {
            let text = "The U.S. is large. It has many states."
            let result = Splitters.splitIntoSentences(text)
            #expect(result.count == 2)
            #expect(result[0] == "The U.S. is large.")
            #expect(result[1] == "It has many states.")
        }

        @Test("Sentences with quotes")
        func withQuotes() {
            let text = "He said \"hello.\" She replied."
            let result = Splitters.splitIntoSentences(text)
            #expect(result.count == 2)
            #expect(result[0] == "He said \"hello.\"")
            #expect(result[1] == "She replied.")
        }

        @Test("Sentences with smart quotes")
        func withSmartQuotes() {
            let text = #"He said "hello." She replied."#
            let result = Splitters.splitIntoSentences(text)
            #expect(result.count == 2)
            #expect(result[0] == #"He said "hello.""#)
            #expect(result[1] == "She replied.")
        }

        @Test("Sentences with parentheses")
        func withParentheses() {
            let text = "This is good (very good). I agree."
            let result = Splitters.splitIntoSentences(text)
            #expect(result.count == 2)
            #expect(result[0] == "This is good (very good).")
            #expect(result[1] == "I agree.")
        }

        @Test("Sentences ending with closing bracket")
        func withBracket() {
            let text = "Look at this [example]. It's clear."
            let result = Splitters.splitIntoSentences(text)
            #expect(result.count == 2)
            #expect(result[0] == "Look at this [example].")
            #expect(result[1] == "It's clear.")
        }

        @Test("Sentences with etc")
        func withEtc() {
            // etc. is an abbreviation, so it doesn't end sentences (matches Python behavior)
            let text = "We have apples, oranges, etc. They are fresh."
            let result = Splitters.splitIntoSentences(text)
            #expect(result.count == 1)
            #expect(result[0] == "We have apples, oranges, etc. They are fresh.")
        }

        @Test("Empty text")
        func emptyText() {
            let text = ""
            let result = Splitters.splitIntoSentences(text)
            #expect(result.isEmpty)
        }

        @Test("Whitespace only")
        func whitespaceOnly() {
            let text = "   \n  \t  "
            let result = Splitters.splitIntoSentences(text)
            #expect(result.isEmpty)
        }

        @Test("Text without sentence enders")
        func noEnders() {
            let text = "Hello world"
            let result = Splitters.splitIntoSentences(text)
            #expect(result.count == 1)
            #expect(result[0] == "Hello world")
        }

        @Test("Extra whitespace is trimmed")
        func extraWhitespace() {
            let text = "  First sentence.   Second sentence.  "
            let result = Splitters.splitIntoSentences(text)
            #expect(result.count == 2)
            #expect(result[0] == "First sentence.")
            #expect(result[1] == "Second sentence.")
        }

        @Test("Paragraph with multiple sentences")
        func paragraph() {
            let text = """
            The quick brown fox jumps over the lazy dog. This is a well-known \
            pangram. It contains every letter of the alphabet. Isn't that amazing?
            """
            let result = Splitters.splitIntoSentences(text)
            #expect(result.count == 4)
            #expect(result[0] == "The quick brown fox jumps over the lazy dog.")
            #expect(result[1] == "This is a well-known pangram.")
            #expect(result[2] == "It contains every letter of the alphabet.")
            #expect(result[3] == "Isn't that amazing?")
        }

        @Test("Real world example with dates")
        func withDates() {
            let text = "The meeting is on Jan. 15th. Please attend."
            let result = Splitters.splitIntoSentences(text)
            #expect(result.count == 2)
            #expect(result[0] == "The meeting is on Jan. 15th.")
            #expect(result[1] == "Please attend.")
        }

        @Test("Academic text with titles")
        func academicText() {
            let text = "Prof. Smith published a paper. Dr. Jones reviewed it."
            let result = Splitters.splitIntoSentences(text)
            #expect(result.count == 2)
            #expect(result[0] == "Prof. Smith published a paper.")
            #expect(result[1] == "Dr. Jones reviewed it.")
        }

        @Test("Address with street abbreviations")
        func address() {
            // St. and Ave. are abbreviations, so they don't end sentences (matches Python behavior)
            let text = "I live on Main St. near Oak Ave. It's a nice area."
            let result = Splitters.splitIntoSentences(text)
            #expect(result.count == 1)
            #expect(result[0] == "I live on Main St. near Oak Ave. It's a nice area.")
        }

        @Test("Contractions are handled")
        func contractions() {
            let text = "It's sunny. We're happy. They've arrived."
            let result = Splitters.splitIntoSentences(text)
            #expect(result.count == 3)
            #expect(result == ["It's sunny.", "We're happy.", "They've arrived."])
        }

        @Test("Sentences don't split on lowercase after period")
        func noSplitOnLowercase() {
            let text = "This is a test.txt file. It works."
            let result = Splitters.splitIntoSentences(text)
            // .txt should not cause a split because 't' is lowercase
            #expect(result.count == 2)
        }
    }

    // MARK: - Edge Cases

    @Suite("Edge Cases")
    struct EdgeCaseTests {

        @Test("Single character with period")
        func singleChar() {
            #expect(Splitters.isAbbreviation("I."))
        }

        @Test("Empty string handling in isAbbreviation")
        func emptyAbbreviation() {
            #expect(!Splitters.isAbbreviation(""))
            #expect(!Splitters.isAbbreviation("."))
        }

        @Test("Multiple spaces between sentences")
        func multipleSpaces() {
            let text = "First.    Second."
            let result = Splitters.splitIntoSentences(text)
            #expect(result.count == 2)
            #expect(result[0] == "First.")
            #expect(result[1] == "Second.")
        }

        @Test("Newlines between sentences")
        func newlines() {
            let text = "First.\n\nSecond."
            let result = Splitters.splitIntoSentences(text)
            #expect(result.count == 2)
            #expect(result[0] == "First.")
            #expect(result[1] == "Second.")
        }

        @Test("All caps words are sentence enders")
        func allCaps() {
            let text = "He works for NASA. She works for FBI."
            let result = Splitters.splitIntoSentences(text)
            #expect(result.count == 2)
        }
    }
}

//
//  Splitters.swift
//  ChainLetter
//
//  Created by Michael Eisemann on 1/9/26.
//

import Foundation
import RegexBuilder

public enum Splitters {
    public static var initialism: Regex<Substring> {
        /^[A-Za-z0-9]{1,2}(?:\.[A-Za-z0-9]{1,2})+\.$/
    }

    // Abbreviation lists
    private static let abbrCapped: Set<String> = [
        // States
        "ala","ariz","ark","calif","colo","conn","del","fla","ga","ill","ind",
        "kan","ky","la","md","mass","mich","minn","miss","mo","mont",
        "neb","nev","okla","ore","pa","tenn","vt","va","wash","wis","wyo",
        // Other
        "u.s",
        // Titles
        "mr","ms","mrs","msr","dr","gov","pres","sen","sens","rep","reps",
        "prof","gen","messrs","col","sr","jf","sgt","mgr","fr","rev",
        "jr","snr","atty","supt",
        // Streets
        "ave","blvd","st","rd","hwy",
        // Months
        "jan","feb","mar","apr","jun","jul","aug","sep","sept","oct","nov","dec"
    ]

    private static let abbrLowercase: Set<String> = [
        "etc","v","vs","viz","al","pct"
    ]

    private static var potentialEnd: Regex<(Substring, Substring, Substring, Substring)> {
        // Build character classes using RegexBuilder APIs
        let wordChars = CharacterClass.word.union(.anyOf(".''&])"))
        let punct = CharacterClass.anyOf(".?!")
        let quotes = CharacterClass.anyOf("''\u{201C}\u{201D}'\"").union(.anyOf(")]"))
        let dashes = CharacterClass.anyOf("-–—")
        // Lowercase letters and dashes
        let lowerOrDash = CharacterClass.generalCategory(.lowercaseLetter).union(dashes)

        // Use references for typed captures
        let wordWithPunctRef = Reference(Substring.self)
        let trailingQuotesRef = Reference(Substring.self)
        let followingSpaceRef = Reference(Substring.self)

        return Regex<(Substring, Substring, Substring, Substring)> {
            Capture(as: wordWithPunctRef) {    // wordWithPunct
                OneOrMore(wordChars)
                One(punct)
            }

            Capture(as: trailingQuotesRef) {   // trailingQuotes
                ZeroOrMore(quotes)
            }

            Capture(as: followingSpaceRef) {   // followingSpace
                OneOrMore(.whitespace)
                NegativeLookahead { lowerOrDash }
            }
        }
    }

    public static func isAbbreviation(_ dottedWord: String) -> Bool {
        guard dottedWord.hasSuffix("."), dottedWord.count > 1 else { return false }
        let clipped = dottedWord.dropLast()
        guard let first = clipped.first else { return false }

        if first.isUppercase {
            if clipped.count == 1 { return true } // Initial like "A."
            return abbrCapped.contains(clipped.lowercased())
        } else {
            return abbrLowercase.contains(String(clipped))
        }
    }

    public static func isSentenceEnder(_ word: String) -> Bool {
        if word.wholeMatch(of: initialism) != nil { return false }
        if word.last == "?" || word.last == "!" { return true }

        // If more than one uppercase letter in the word
        let uppercaseCount = word.unicodeScalars.filter { CharacterSet.uppercaseLetters.contains($0) }.count
        if uppercaseCount > 1 { return true }

        if word.hasSuffix(".") && !isAbbreviation(word) { return true }
        return false
    }

    public static func splitIntoSentences(_ text: String) -> [String] {
        var endIndices: [String.Index] = []
        var searchStart = text.startIndex

        while let match = text[searchStart...].firstMatch(of: potentialEnd) {
            let (_, wordWithPunct, trailingQuotes, _) = match.output
            let boundary = trailingQuotes.endIndex

            if isSentenceEnder(String(wordWithPunct)) {
                endIndices.append(boundary)
            }
            searchStart = match.range.upperBound
        }

        var sentences: [String] = []
        var prev = text.startIndex
        for end in endIndices {
            let slice = text[prev..<end].trimmingCharacters(in: .whitespacesAndNewlines)
            if !slice.isEmpty { sentences.append(String(slice)) }
            prev = end
        }
        let tail = text[prev...].trimmingCharacters(in: .whitespacesAndNewlines)
        if !tail.isEmpty { sentences.append(String(tail)) }
        return sentences
    }
}

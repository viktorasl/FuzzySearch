//
//  FuzzySearch.swift
//  FuzzySearch
//
//  Created by Viktoras Laukevičius on 05/08/16.
//  Copyright © 2016 Treatwell. All rights reserved.
//

import Foundation

private extension String {
    subscript(i: Int) -> Character {
        guard i >= 0 && i < characters.count else { return Character("") }
        return self[startIndex.advancedBy(i)]
    }
}

public struct FuzzySearchResult {
    public let weight: Int
    public let parts: [NSRange]
}

public protocol FuzzySearchable {
    var fuzzyStringToMatch: String { get }
}

public extension FuzzySearchable {
    func fuzzyMatch(pattern: String) -> FuzzySearchResult {
        let string = fuzzyStringToMatch
        let compareString = string.lowercaseString
        
        let pattern = pattern.lowercaseString
        
        var totalScore = 0
        var parts: [NSRange] = []
        
        var patternIdx = 0
        var currScore = 0
        var currPart = NSRange(location: 0, length: 0)
        
        for (idx, _) in string.characters.enumerate() {
            if patternIdx < pattern.characters.count && compareString[idx] == pattern[patternIdx] {
                patternIdx += 1
                currScore += 1 + currScore
                currPart.length += 1
            } else {
                currScore = 0
                if currPart.length != 0 {
                    parts.append(currPart)
                }
                currPart = NSRange(location: idx + 1, length: 0)
            }
            totalScore += currScore
        }
        if currPart.length != 0 {
            parts.append(currPart)
        }
        
        if patternIdx == pattern.characters.count {
            // if all pattern chars were found
            return FuzzySearchResult(weight: totalScore, parts: parts)
        } else {
            return FuzzySearchResult(weight: 0, parts: parts)
        }
    }
}

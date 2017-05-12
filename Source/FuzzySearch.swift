//
//  FuzzySearch.swift
//  FuzzySearch
//
//  Created by Viktoras Laukevičius on 05/08/16.
//  Copyright © 2016 Treatwell. All rights reserved.
//

import Foundation

private struct CharOpts {
    let ch: String
    let normalized: String
}

private extension String {
    subscript(i: Int) -> Character? {
        guard i >= 0 && i < characters.count else { return nil }
        return self[characters.index(startIndex, offsetBy: i)]
    }
    
    func tokenize() -> [CharOpts] {
        return characters.map{
            let str = String($0).lowercased()
            guard let data = str.data(using: .ascii, allowLossyConversion: true),
                let accentFoldedStr = String(data: data, encoding: .ascii) else {
                return CharOpts(ch: str, normalized: str)
            }
            return CharOpts(ch: str, normalized: accentFoldedStr)
        }
    }
    
    // checking if string has prefix and returning prefix length on success
    func hasPrefix(_ prefix: CharOpts, atIndex index: Int) -> Int? {
        for pfx in [prefix.ch, prefix.normalized] {
            if (self as NSString).substring(from: index).hasPrefix(pfx) {
                return pfx.characters.count
            }
        }
        return nil
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
    func fuzzyMatch(_ pattern: String) -> FuzzySearchResult {
        let compareString = fuzzyStringToMatch.tokenize()
        
        let pattern = pattern.lowercased()
        
        var totalScore = 0
        var parts: [NSRange] = []
        
        var patternIdx = 0
        var currScore = 0
        var currPart = NSRange(location: 0, length: 0)
        
        for (idx, strChar) in compareString.enumerated() {
            if let prefixLength = pattern.hasPrefix(strChar, atIndex: patternIdx) {
                patternIdx += prefixLength
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
            return FuzzySearchResult(weight: 0, parts: [])
        }
    }
}

public extension Collection where Iterator.Element: FuzzySearchable {
    func fuzzyMatch(_ pattern: String) -> [(item: Iterator.Element, result: FuzzySearchResult)] {
        return map{
            (item: $0, result: $0.fuzzyMatch(pattern))
        }.filter{
            $0.result.weight > 0
        }.sorted{
            $0.result.weight > $1.result.weight
        }
    }
}

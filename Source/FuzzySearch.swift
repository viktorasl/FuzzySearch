//
//  FuzzySearch.swift
//  FuzzySearch
//
//  Created by Viktoras Laukevičius on 05/08/16.
//  Copyright © 2016 Treatwell. All rights reserved.
//

import Foundation

fileprivate struct CharOpts {
    let ch: String
    let normalized: String
}

/// A private cache containing pre-parsed metadata from a previous `.fuzzyMatch`
/// call.
/// Used by CachedFuzzySearchable<T> bellow.
fileprivate class FuzzyCache {
    /// Hash of last fuzzed string
    fileprivate var hash: Int?
    
    /// Array of last parsed fuzzy characters
    fileprivate var lastTokenization = FuzzyTokens(tokens: [])
    
    fileprivate init() {
        
    }
}

/// Opaque struct containing the results of a pre-tokenization phase that is
/// applied to a fuzzy searchable value.
fileprivate struct FuzzyTokens {
    fileprivate var tokens: [CharOpts]
}

fileprivate extension String {
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

/// Specifies that a value exposes a string fit for fuzzy-matching against string
/// patterns.
public protocol FuzzySearchable {
    var fuzzyStringToMatch: String { get }
    
    func fuzzyMatch(_ pattern: String) -> FuzzySearchResult
}

/// Container over a FuzzySearchable that allows caching of metadata generated
/// while fuzzying.
///
/// This allows for improved performance when fuzzy-searching multiple times 
/// objects that don't change the contents of `fuzzyStringToMatch` too often.
public struct CachedFuzzySearchable<T> : FuzzySearchable where T : FuzzySearchable {
    fileprivate let searchable: T
    fileprivate let fuzzyCache: FuzzyCache
    
    public init(wrapping searchable: T) {
        self.searchable = searchable
        self.fuzzyCache = FuzzyCache()
    }
    
    public var fuzzyStringToMatch: String {
        return searchable.fuzzyStringToMatch
    }
}

// Private implementation of fuzzy matcher that is used by `FuzzySearchable` and
// the specialized `CachedFuzzySearchable` bellow.
fileprivate extension FuzzySearchable {
    func fuzzyMatch(_ pattern: String, with tokens: FuzzyTokens) -> FuzzySearchResult {
        let compareString = tokens.tokens
        
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

fileprivate extension FuzzySearchable {
    func fuzzyTokenized() -> FuzzyTokens {
        return FuzzyTokens(tokens: fuzzyStringToMatch.tokenize())
    }
}

fileprivate extension CachedFuzzySearchable {
    func fuzzyTokenized() -> FuzzyTokens {
        // Re-create fuzzy cache, if stale
        if fuzzyCache.hash == nil || fuzzyCache.hash != fuzzyStringToMatch.hashValue {
            let tokens = fuzzyStringToMatch.tokenize()
            fuzzyCache.hash = fuzzyStringToMatch.hashValue
            fuzzyCache.lastTokenization = FuzzyTokens(tokens: tokens)
        }
        
        return fuzzyCache.lastTokenization
    }
}

public extension FuzzySearchable {
    func fuzzyMatch(_ pattern: String) -> FuzzySearchResult {
        let tokens = fuzzyTokenized()
        return fuzzyMatch(pattern, with: tokens)
    }
}

public extension CachedFuzzySearchable {
    // Note: Extension here is required to use the fileprivate `CachedFuzzySearchable.fuzzyTokenized`
    // method, otherwise we end up using the `FuzzySearchable.fuzzyTokenized`
    // implementation which, since it's declared in an extension, cannot be overriden
    // by `CachedFuzzySearchable` (but `fuzzyMatch` can, and so we implement
    // the call to the custom cached `fuzzyTokenized` method here).
    
    func fuzzyMatch(_ pattern: String) -> FuzzySearchResult {
        let tokens = fuzzyTokenized()
        return fuzzyMatch(pattern, with: tokens)
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

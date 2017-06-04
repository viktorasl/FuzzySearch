//
//  FuzzySearch.swift
//  FuzzySearch
//
//  Created by Viktoras Laukevičius on 05/08/16.
//  Copyright © 2016 Treatwell. All rights reserved.
//

import Foundation

internal struct CharOpts {
    let ch: String
    let normalized: String
}

/// A private cache containing pre-parsed metadata from a previous `.fuzzyMatch`
/// call.
/// Used by CachedFuzzySearchable<T> bellow.
internal class FuzzyCache {
    /// Hash of last fuzzed string
    internal var hash: Int?
    
    /// Array of last parsed fuzzy characters
    internal var lastTokenization = FuzzyTokens(tokens: [])
    
    internal init() {
        
    }
}

/// Opaque struct containing the results of a pre-tokenization phase that is
/// applied to a fuzzy searchable value.
public struct FuzzyTokens {
    fileprivate var tokens: [CharOpts]
}

internal extension String {
    func tokenize() -> [CharOpts] {
        return characters.map{
            let str = String($0).lowercased()
            // Returns nil only if flag is false and the receiver can't be converted without losing some information
            // so it's safe to force unwrap the result
            let data = str.data(using: .ascii, allowLossyConversion: true)!
            // as data was encoded using ascii encoding it's safe to force unwrap the result
            let accentFoldedStr = String(data: data, encoding: .ascii)!
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

/// Used to represent fuzzy search result
public struct FuzzySearchResult {
    /// Natural number represenated weight of match.
    public let weight: Int
    /// Matched ranges in text.
    public let parts: [NSRange]
}

/// Types adopting `FuzzySearchable` protocol can be used to fuzzy search against
/// text represented pattern.
///
/// Specifies that a value exposes a string fit for fuzzy-matching against string
/// patterns.
public protocol FuzzySearchable {
    
    /// Text representation which will be used to find fuzzy match against pattern
    var fuzzyStringToMatch: String { get }
    
    /// Finds match info against provided pattern.
    ///
    /// - parameter pattern: a text against which fuzzy match will be searched.
    ///
    /// - returns: A FuzzySearchResult.
    func fuzzyMatch(_ pattern: String) -> FuzzySearchResult
}

/// Container over a FuzzySearchable that allows caching of metadata generated
/// while fuzzying.
///
/// This allows for improved performance when fuzzy-searching multiple times 
/// objects that don't change the contents of `fuzzyStringToMatch` too often.
public struct CachedFuzzySearchable<T> : FuzzySearchable where T : FuzzySearchable {
    internal let searchable: T
    internal let fuzzyCache: FuzzyCache
    
    /// A `FuzzySearchable` instance which will be wrapped into `CachedFuzzySearchable` container
    /// for faster fuzzy search when it's done multiple times on the same representation.
    ///
    /// parameter searchable: An instance conforming to `FuzzySearchable` protocol.
    public init(wrapping searchable: T) {
        self.searchable = searchable
        self.fuzzyCache = FuzzyCache()
    }
    
    /// Text representation which will be used to find fuzzy match against pattern
    public var fuzzyStringToMatch: String {
        return searchable.fuzzyStringToMatch
    }
}

// Private implementation of fuzzy matcher that is used by `FuzzySearchable` and
// the specialized `CachedFuzzySearchable` bellow.
extension FuzzySearchable {
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
        }
        return FuzzySearchResult(weight: 0, parts: [])
    }
}

extension FuzzySearchable {
    func fuzzyTokenized() -> FuzzyTokens {
        return FuzzyTokens(tokens: fuzzyStringToMatch.tokenize())
    }
}

extension CachedFuzzySearchable {
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
    
    /// Finds match info against provided pattern.
    ///
    /// - parameter pattern: a text against which fuzzy match will be searched.
    ///
    /// - returns: A FuzzySearchResult.
    func fuzzyMatch(_ pattern: String) -> FuzzySearchResult {
        let tokens = fuzzyTokenized()
        return fuzzyMatch(pattern, with: tokens)
    }
}

public extension CachedFuzzySearchable {
    
    // Note: Extension here is required to use the internal `CachedFuzzySearchable.fuzzyTokenized`
    // method, otherwise we end up using the `FuzzySearchable.fuzzyTokenized`
    // implementation which, since it's declared in an extension, cannot be overriden
    // by `CachedFuzzySearchable` (but `fuzzyMatch` can, and so we implement
    // the call to the custom cached `fuzzyTokenized` method here).
    
    /// Finds match info against provided pattern using cache container if possible.
    ///
    /// - parameter pattern: a text against which fuzzy match will be searched.
    ///
    /// - returns: A FuzzySearchResult.
    func fuzzyMatch(_ pattern: String) -> FuzzySearchResult {
        let tokens = fuzzyTokenized()
        return fuzzyMatch(pattern, with: tokens)
    }
}

public extension Collection where Iterator.Element: FuzzySearchable {
    
    /// Iterates over elements conforming to `FuzzySearchable` protocol and gets `FuzzySearchResult`
    /// for each of them. Filters results having weights greather than zero and sorts them
    /// in descending order.
    ///
    /// - parameter pattern: a text against which fuzzy match will be searched.
    ///
    /// - returns: An array of 2-tuple containing element and it's `FuzzySearchResult`
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

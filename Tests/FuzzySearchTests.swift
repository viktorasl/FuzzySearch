//
//  FuzzySearchTests.swift
//  FuzzySearchTests
//
//  Created by Viktoras Laukevičius on 05/08/16.
//  Copyright (c) 2016 Viktoras Laukevičius. All rights reserved.
//

import XCTest
import FuzzySearch

extension String: FuzzySearchable {
    public var fuzzyStringToMatch: String {
        return self
    }
}

class CacheableString: FuzzySearchable {
    var fuzzyStringToMatch: String
    
    init(_ value: String) {
        self.fuzzyStringToMatch = value
    }
}

extension NSRange: Equatable {}
public func ==(lhs: NSRange, rhs: NSRange) -> Bool {
    return lhs.length == rhs.length && lhs.location == rhs.location
}

class FuzzySearchTests: XCTestCase {
    
    func testThatConsecutiveMatchingGives2xForEachChar() {
        let str = "Ladies Wash, Cut & Blow Dry"
        XCTAssertEqual(str.fuzzyMatch("l").weight, 1)
        XCTAssertEqual(str.fuzzyMatch("la").weight, 4)
        XCTAssertEqual(str.fuzzyMatch("lad").weight, 11)
        XCTAssertEqual(str.fuzzyMatch("ladi").weight, 26)
        XCTAssertEqual(str.fuzzyMatch("ladie").weight, 57)
    }
    
    func testThatConsecutiveMatchingGives2xForEachChar_Cached() {
        let str = CachedFuzzySearchable(wrapping: "Ladies Wash, Cut & Blow Dry")
        
        XCTAssertEqual(str.fuzzyMatch("l").weight, 1)
        XCTAssertEqual(str.fuzzyMatch("la").weight, 4)
        XCTAssertEqual(str.fuzzyMatch("lad").weight, 11)
        XCTAssertEqual(str.fuzzyMatch("ladi").weight, 26)
        XCTAssertEqual(str.fuzzyMatch("ladie").weight, 57)
    }
    
    func testThatChangingFuzzyStringAffectsCache() {
        let source = CacheableString("Ladies Wash, Cut & Blow Dry")
        let str = CachedFuzzySearchable(wrapping: source)
        
        XCTAssertEqual(str.fuzzyMatch("l").weight, 1)
        XCTAssertEqual(str.fuzzyMatch("la").weight, 4)
        XCTAssertEqual(str.fuzzyMatch("lad").weight, 11)
        XCTAssertEqual(str.fuzzyMatch("ladi").weight, 26)
        XCTAssertEqual(str.fuzzyMatch("ladie").weight, 57)
        
        source.fuzzyStringToMatch = "Weird Assassin"
        
        XCTAssertEqual(str.fuzzyMatch("w").weight, 1)
        XCTAssertEqual(str.fuzzyMatch("we").weight, 4)
        XCTAssertEqual(str.fuzzyMatch("wei").weight, 11)
        XCTAssertEqual(str.fuzzyMatch("weir").weight, 26)
    }
    
    func testThatCorrectMatchingPartsAreReturned() {
        XCTAssertEqual("Ladies Wash, Cut & Blow Dry".fuzzyMatch("ladieblry").parts, [
            NSRange(location: 0, length: 5),
            NSRange(location: 19, length: 2),
            NSRange(location: 25, length: 2)
        ])
        XCTAssertEqual("Short Cut".fuzzyMatch("Short Cut").parts, [
            NSRange(location: 0, length: 9)
        ])
    }
    
    func testThatFuzzySearchableArrayReturnsFilteredResults() {
        let strs = [
            "Ladies Wash, Cut & Blow Dry",
            "Weird Assassin",
            "Wash & Go",
            "Go to wash"
        ]
        XCTAssertEqual(strs.fuzzyMatch("wash").map{ $0.item }, [
            "Ladies Wash, Cut & Blow Dry",
            "Wash & Go",
            "Go to wash"
        ])
    }
    
    func testThatFuzzySearchableArrayReturnsSortedResults() {
        let strs = [
            "Ladies Wash, Cut & Blow Dry",
            "World in ashes",
            "Wash & Go"
        ]
        XCTAssertEqual(strs.fuzzyMatch("wash").map{ $0.item }, [
            "Ladies Wash, Cut & Blow Dry",
            "Wash & Go",
            "World in ashes"
        ])
    }
    
    func testThatAccentFoldingWorks() {
        XCTAssertEqual("Øresund".fuzzyMatch("ore").parts, [NSRange(location: 0, length: 3)])
        XCTAssertEqual("Æon Flux".fuzzyMatch("aeon fl").parts, [NSRange(location: 0, length: 6)])
        XCTAssertEqual("la víbora".fuzzyMatch("vibor").parts, [NSRange(location: 3, length: 5)])
        XCTAssertEqual("bádminton".fuzzyMatch("badmin").parts, [NSRange(location: 0, length: 6)])
    }
    
    func testThatAccentFoldingWorksWithMixedAccents() {
        XCTAssertEqual("ačiū".fuzzyMatch("ačiu").parts, [NSRange(location: 0, length: 4)])
    }
    
    func testSpeedOfFuzzySearchFor1000SpanishWords() {
        let path = Bundle(for: type(of: self)).path(forResource: "spanish-words", ofType: "json")!
        let jsonData = try! Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
        let spanishWords: Array<String> = try! JSONSerialization.jsonObject(with: jsonData as Data, options: JSONSerialization.ReadingOptions.mutableContainers) as! Array<String>
        
        measure{
            _ = spanishWords.fuzzyMatch("l")
            _ = spanishWords.fuzzyMatch("la")
            _ = spanishWords.fuzzyMatch("la ")
            _ = spanishWords.fuzzyMatch("la s")
            _ = spanishWords.fuzzyMatch("la sa")
            _ = spanishWords.fuzzyMatch("la sar")
            _ = spanishWords.fuzzyMatch("la sart")
        }
    }
    
    func testSpeedOfFuzzySearchFor1000SpanishWords_cached() {
        let path = Bundle(for: type(of: self)).path(forResource: "spanish-words", ofType: "json")!
        let jsonData = try! Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
        let spanishWords: Array<String> = try! JSONSerialization.jsonObject(with: jsonData as Data, options: JSONSerialization.ReadingOptions.mutableContainers) as! Array<String>
        let spanishWordsCached = spanishWords.map(CachedFuzzySearchable.init)
        
        measure {
            _ = spanishWordsCached.fuzzyMatch("l")
            _ = spanishWordsCached.fuzzyMatch("la")
            _ = spanishWordsCached.fuzzyMatch("la ")
            _ = spanishWordsCached.fuzzyMatch("la s")
            _ = spanishWordsCached.fuzzyMatch("la sa")
            _ = spanishWordsCached.fuzzyMatch("la sar")
            _ = spanishWordsCached.fuzzyMatch("la sart")
        }
    }
}

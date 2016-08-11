//
//  FuzzySearchTests.swift
//  FuzzySearchTests
//
//  Created by Viktoras Laukevičius on 05/08/16.
//  Copyright © 2016 Treatwell. All rights reserved.
//

import XCTest
import FuzzySearch

extension String: FuzzySearchable {
    public var fuzzyStringToMatch: String {
        return self
    }
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
    
    func testSpeedOfFuzzySearchFor1000SpanishWords() {
        let path = NSBundle(forClass: self.dynamicType).pathForResource("spanish-words", ofType: "json")!
        let jsonData = try! NSData(contentsOfFile: path, options: .DataReadingMappedIfSafe)
        let spanishWords: Array<String> = try! NSJSONSerialization.JSONObjectWithData(jsonData, options: NSJSONReadingOptions.MutableContainers) as! Array<String>
        measureBlock{
            spanishWords.fuzzyMatch("la sart")
        }
    }
}

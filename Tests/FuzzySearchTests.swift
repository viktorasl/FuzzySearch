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
}

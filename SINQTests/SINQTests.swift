//
//  SINQTests.swift
//  SINQTests
//
//  Created by Leszek Ślażyński on 25/06/14.
//  Copyright (c) 2014 Leszek Ślażyński. All rights reserved.
//

import XCTest
import SINQ

class SINQTests: XCTestCase {

    func testAll() {
        XCTAssertTrue(sinq([11, 12, 15, 10]).all{ $0 >= 10 })
        XCTAssertFalse(sinq([11, 12, 15, 10]).all{ $0 > 10 })
    }
    
    func testAny() {
        XCTAssertTrue(sinq([11, 12, 15, 10]).any{ $0 <= 10 })
        XCTAssertFalse(sinq([11, 12, 15, 10]).any{ $0 > 15 })
    }
    
    func testConcat() {
        let sequence = sinq([1,2,3]).concat(sinq([4,5,6]))
        var counter = 1
        for elem in sequence {
            XCTAssertEqual(elem, counter++)
        }
    }
    
    func testContains() {
        let sequence = sinq([1,2,3,4,5,6])
        for i in 1...6 {
            XCTAssertTrue(sequence.contains(i, { $0 == $1 }))
        }
        for i in 7...10 {
            XCTAssertFalse(sequence.contains(i, { $0 == $1 }))
        }
    }

    func testCount() {
        XCTAssertEqual(sinq(0..10).count(), 10)
    }

    func testDistinct() {
        XCTAssertEqual(sinq(0..10).distinct{ $0 == $1 }.count(), 10)
        XCTAssertEqual(sinq(Repeat(count: 10, repeatedValue: 1)).distinct{ $0 == $1 }.count(), 1)
    }
   
    func testExcept() {
        XCTAssertEqual(sinq(0..10).except(4..6, { $0 == $1 }).count(), 8)
    }
    
    func testFirst() {
        XCTAssertNil(sinq(Array<Int>()).firstOrNil())
        XCTAssertNotNil(sinq([1]).firstOrNil())
        XCTAssertEqual(sinq([42, 1, 2, 3]).first(), 42)
        XCTAssertEqual(sinq(Array<Int>()).firstOrDefault(10), 10)
        XCTAssertEqual(sinq([42, 1, 2, 3]).firstOrDefault(10), 42)
    }

    func testGroupBy() {
        let counts = from([1, 2, 3, 4, 5]).groupBy{ $0 % 2 }.select{ ($0.key, $0.values.count()) }
        let dict = counts.toDictionary({ ($0, $1) })
        XCTAssertEqual(dict[0]!, 2)
        XCTAssertEqual(dict[1]!, 3)
    }
    
    func testGroupJoin() {
        let counts = sinq([0, 1]).groupJoin(inner: [1, 2, 3, 4, 5],
                outerKey: { $0 },
                innerKey: { $0 % 2 },
                result: { $0 })
            .select{ ($0, $1.count()) }
        let dict = counts.toDictionary({ ($0, $1) })
        XCTAssertEqual(dict[0]!, 2)
        XCTAssertEqual(dict[1]!, 3)
    }
    
    func testIntersect() {
        XCTAssertEqual(sinq(1...10).intersect(4...6, { $0 == $1 }).count(), 3)
        XCTAssertEqual(sinq(1...10).intersect(0...20, { $0 == $1 }).count(), 10)
        XCTAssertEqual(sinq(10...20).intersect(4...6, { $0 == $1 }).count(), 0)
    }
    
    func testJoin() {
        let pairs = sinq(0..10)
                .join(inner: 0..10,
                    outerKey: { $0 },
                    innerKey: { $0 / 2 },
                    result: { (half: $0, whole: $1) })
                .toArray()
        
        XCTAssertEqual(pairs.count, 10)
        for pair in pairs {
            XCTAssertEqual(pair.whole / 2, pair.half)
        }
    }

    func testLast() {
        XCTAssertNil(sinq(Array<Int>()).lastOrNil())
        XCTAssertNotNil(sinq([1]).lastOrNil())
        XCTAssertEqual(sinq([42, 1, 2, 3]).last(), 3)
        XCTAssertEqual(sinq(Array<Int>()).lastOrDefault(10), 10)
        XCTAssertEqual(sinq([42, 1, 2, 3]).lastOrDefault(10), 3)
    }

    func testOrderBy() {
        let sorted = sinq([1,3,4,2,5,6,9,8,7,0]).orderBy{ $0 }
        var counter = 0
        for elem in sorted {
            XCTAssertEqual(elem, counter++)
        }
    }
    
    func testOrderByDescending() {
        let sorted = sinq([1,3,4,2,5,6,9,8,7,0]).orderByDescending{ $0 }
        var counter = 9
        for elem in sorted {
            XCTAssertEqual(elem, counter--)
        }
    }
    
    func testReverse() {
        let sequence = sinq([1,2,3,4,5]).reverse()
        var counter = 5
        for elem in sequence {
            XCTAssertEqual(elem, counter--)
        }
    }

    func testSelect() {
        var counter = 0
        for (idx, elem) in sinq(10..20).select({ ($1, 2*$0) }) {
            XCTAssertEqual(idx, counter++)
            XCTAssertEqual(elem, 2*(10+idx))
        }
    }

    func testSelectMany() {
        let results = sinq(0..10).selectMany({ 0..$0 }).toArray()
        XCTAssertEqual(results.count, 45)
        var gen = results.generate()
        for i in 0..10 {
            for j in 0..i {
                XCTAssertEqual(gen.next()!, j)
            }
        }
    }

    func testSkip() {
        let res = sinq(0..10).skip(2)
        XCTAssertEqual(res.count(), 8)
        var counter = 2
        for elem in res {
            XCTAssertEqual(elem, counter++)
        }
    }

    func testSkipWhile() {
        let res = sinq(0..10).skipWhile({ $0 < 5 })
        XCTAssertEqual(res.count(), 5)
        var counter = 5
        for elem in res {
            XCTAssertEqual(elem, counter++)
        }
    }

    func testTake() {
        let res = sinq(0..10).take(2)
        XCTAssertEqual(res.count(), 2)
        var counter = 0
        for elem in res {
            XCTAssertEqual(elem, counter++)
        }
    }

    func testTakeWhile() {
        let res = sinq(0..10).takeWhile{ $0 < 6 }
        XCTAssertEqual(res.count(), 6)
        var counter = 0
        for elem in res {
            XCTAssertEqual(elem, counter++)
        }
    }
    
    func testToDictionary() {
        let res = sinq(0..10).toDictionary{ 10 - $0 }
        XCTAssertEqual(res.count, 10)
        for (k, v) in res {
            XCTAssertEqual(k, 10-v)
        }
    }

    func testUnion() {
        let res = sinq([1, 2, 1, 2]).union([3, 2, 1], { $0 == $1 })
        var counter = 1
        XCTAssertEqual(res.count(), 3)
        for elem in res {
            XCTAssertEqual(elem, counter++)
        }
    }

}

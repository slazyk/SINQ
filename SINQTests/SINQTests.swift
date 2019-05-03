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
        let seq = sinq([11, 12, 15, 10])
        XCTAssertTrue(seq.all{ $0 >= 10 })
        XCTAssertFalse(seq.all{ $0 < 13 })
    }

    func testAny() {
        let seq = sinq([11, 12, 15, 10])
        XCTAssertTrue(seq.any{ $0 <= 10 })
        XCTAssertFalse(seq.any{ $0 > 15 })
    }

    func testConcat() {
        let sequence = sinq([1,2,3]).concat(sinq([4,5,6]))
        var counter = 1
        for elem in sequence {
            XCTAssertEqual(elem, counter)
            counter += 1
        }
    }

    func testContains() {
        let sequence = sinq(1...6)
        for i in 1...6 {
            XCTAssertTrue(sequence.contains(i){$0 == $1})
            XCTAssertTrue(sequence.contains(i){$0})
        }
        for i in 7...10 {
            XCTAssertFalse(sequence.contains(i){$0 == $1})
            XCTAssertFalse(sequence.contains(i){$0})
        }
    }

    func testCount() {
        let seq = sinq(0..<3)
        XCTAssertEqual(seq.count(), 3)
    }

    func testDistinct() {
        let toNine = sinq(0..<10)
        XCTAssertEqual(toNine.distinct{$0 == $1}.count(), 10)
        XCTAssertEqual(toNine.distinct{$0}.count(), 10)
        let repeated = sinq(repeatElement(1, count: 10))
        XCTAssertEqual(repeated.distinct{$0 == $1}.count(), 1)
        XCTAssertEqual(repeated.distinct{$0}.count(), 1)
    }

    func testEach() {
        var cnt = 0
        sinq(1...3).each{ cnt += $0 }
        XCTAssertEqual(cnt, 6)
    }
    
    func testElementAt() {
        let toNine = sinq(0..<10)
        XCTAssertEqual(toNine.elementAt(2), 2)
        XCTAssertNil(toNine.elementAtOrNil(20))
        XCTAssertEqual(toNine.elementAt(21, orDefault: 42), 42)
    }

    func testExcept() {
        let toNine = sinq(0..<10)
        XCTAssertEqual(toNine.except(4..<6){$0 == $1}.count(), 8)
        XCTAssertEqual(toNine.except(4..<6){$0}.count(), 8)
        let notUnique = sinq([1, 1, 2])
        XCTAssertEqual(notUnique.except([2]){$0 == $1}.count(), 1)
        XCTAssertEqual(notUnique.except([2]){$0}.count(), 1)
    }

    func testFilterIsLazy() {
        var timesCalled = 0
        let predicate: (Int) -> Bool = { x in
            timesCalled += 1
            return x % 2 == 0
        }
        
        let longSequence = sinq(1...1000).filter(predicate)
        
        let gen = longSequence.makeIterator()
        
        for i in 1...5 {
            XCTAssertEqual(gen.next()!, 2*i)
            XCTAssertEqual(timesCalled, 2*i)
        }
        
    }
    
    func testFirst() {
        let empty = sinq(0..<0)
        let nonEmpty = sinq(0..<1)
        XCTAssertNil(empty.firstOrNil())
        XCTAssertNotNil(nonEmpty.firstOrNil())
        let seq = sinq([42, 1, 2, 3])
        XCTAssertEqual(seq.first(), 42)
        XCTAssertEqual(empty.firstOrDefault(10), 10)
        XCTAssertEqual(seq.firstOrDefault(10), 42)
    }

    func testGroupBy() {
        let seq = sinq(1...5)
        let counts = seq.groupBy{ $0 % 2 }.select{ ($0.key, $0.values.count()) }
        let dict = counts.toDictionary({ ($0, $1) })
        XCTAssertEqual(dict[0]!, 2)
        XCTAssertEqual(dict[1]!, 3)
    }
    
    func testGroupJoin() {
        let seq = sinq(0...1)
        let counts = seq.groupJoin(inner: [1, 2, 3, 4, 5],
                outerKey: { $0 },
                innerKey: { $0 % 2 },
                result: { ($0, $1) })
            .select{ ($0, $1.count()) }
        let dict = counts.toDictionary({ ($0, $1) })
        XCTAssertEqual(dict[0]!, 2)
        XCTAssertEqual(dict[1]!, 3)
    }

    func testIntersect() {
        let upToTen = sinq(0...10)
        let tenToTwnety = sinq(10...20)
        let repeated = sinq([1, 1, 1])
        XCTAssertEqual(upToTen.intersect(4...6){ $0 == $1 }.count(), 3)
        XCTAssertEqual(upToTen.intersect(0...20){ $0 == $1 }.count(), 11)
        XCTAssertEqual(tenToTwnety.intersect(4...6){ $0 == $1 }.count(), 0)
        XCTAssertEqual(repeated.intersect([1, 1]){ $0 == $1 }.count(), 1)
        XCTAssertEqual(repeated.intersect([1, 1]){$0}.count(), 1)
    }

    func testJoin() {
        let pairs = sinq(0..<10)
                .join(inner: 0..<10,
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
        let empty = sinq(0..<0)
        let nonEmpty = sinq(0..<1)
        XCTAssertNil(empty.lastOrNil())
        XCTAssertNotNil(nonEmpty.lastOrNil())
        let seq = sinq([42, 1, 2, 3])
        XCTAssertEqual(seq.last(), 3)
        XCTAssertEqual(empty.lastOrDefault(10), 10)
        XCTAssertEqual(seq.lastOrDefault(10), 3)
    }

    func testMax() {
        let cities = sinq([("Warsaw", 1717), ("Geneve", 184), ("Amsterdam", 779), ("Zurich", 366)])
        let population = cities.max{ $0.1 }
        let city = cities.argmax{ $0.1 }.0
        XCTAssertEqual(population, 1717)
        XCTAssertEqual(city, "Warsaw")
    }

    func testMin() {
        let cities = sinq([("Warsaw", 1717), ("Geneve", 184), ("Amsterdam", 779), ("Zurich", 366)])
        let population = cities.min{ $0.1 }
        let city = cities.argmin{ $0.1 }.0
        XCTAssertEqual(population, 184)
        XCTAssertEqual(city, "Geneve")
    }
    
    func testOrderAndFilter() {
        let sorted = sinq(0..<100).orderBy{$0}.filter{$0 < 10}
        var counter = 0
        for elem in sorted {
            XCTAssertEqual(elem, counter)
            counter += 1
        }
        XCTAssertEqual(counter, 10)
    }

    func testOrderBy() {
        let sorted = sinq([1,3,4,2,5,6,9,8,7,0]).orderBy{ $0 }
        var counter = 0
        for elem in sorted {
            XCTAssertEqual(elem, counter)
            counter += 1
        }
    }
    
    func testOrderByDescending() {
        let sorted = sinq([1,3,4,2,5,6,9,8,7,0]).orderByDescending{ $0 }
        var counter = 9
        for elem in sorted {
            XCTAssertEqual(elem, counter)
            counter -= 1
        }
    }
    
    func testReverse() {
        let sequence = sinq([1,2,3,4,5]).reverse()
        var counter = 5
        for elem in sequence {
            XCTAssertEqual(elem, counter)
            counter -= 1
        }
    }

    func testSelect() {
        var counter = 0
        for (idx, elem) in sinq(10..<20).select({ ($1, 2*$0) }) {
            XCTAssertEqual(idx, counter)
            XCTAssertEqual(elem, 2*(10+idx))
            counter += 1
        }
    }
    
    func testSelectIsLazy() {
        var calledTimes = 0
        let identity: (Int) -> Int = { x in
            calledTimes += 1
            return x
        }
        let longSequence = sinq(1...1000).select(identity)
        let generator = longSequence.makeIterator()
        for i in 1...5 {
            XCTAssertEqual(generator.next()!, i)
            XCTAssertEqual(calledTimes, i)
        }
    }

    func testSelectMany() {
        let results = sinq(0..<10).selectMany({ 0..<$0 }).toArray()
        XCTAssertEqual(results.count, 45)
        var gen = results.makeIterator()
        for i in 0..<10 {
            for j in 0..<i {
                XCTAssertEqual(gen.next()!, j)
            }
        }
    }
    
    func testSingle() {
        let empty = sinq(0..<0)
        let single = sinq([42])
        let double = sinq([42, 43])
        XCTAssertNil(empty.singleOrNil())
        XCTAssertNotNil(single.singleOrNil())
        XCTAssertNil(double.singleOrNil())
        XCTAssertEqual(single.single(), 42)
        XCTAssertEqual(empty.singleOrDefault(44), 44)
        XCTAssertEqual(double.singleOrDefault(44), 44)
        let seq = sinq([1, 10, 42, 42])
        XCTAssertNil(seq.singleOrNil({$0 == 2}))
        XCTAssertEqual(seq.single({$0 == 10}), 10)
        XCTAssertEqual(seq.singleOrDefault(44, predicate: {$0 == 2}), 44)
        XCTAssertNil(seq.singleOrNil({$0 == 42}))
        XCTAssertEqual(seq.singleOrDefault(44, predicate: {$0 == 42}), 44)
    }

    func testSkip() {
        let res = sinq(0..<10).skip(2)
        XCTAssertEqual(res.count(), 8)
        var counter = 2
        for elem in res {
            XCTAssertEqual(elem, counter)
            counter += 1
        }
    }

    func testSkipWhile() {
        let res = sinq(0..<10).skipWhile({ $0 < 5 })
        XCTAssertEqual(res.count(), 5)
        var counter = 5
        for elem in res {
            XCTAssertEqual(elem, counter)
            counter += 1
        }
    }

    func testTake() {
        let res = sinq(0..<10).take(2)
        XCTAssertEqual(res.count(), 2)
        var counter = 0
        for elem in res {
            XCTAssertEqual(elem, counter)
            counter += 1
        }
    }

    func testTakeWhile() {
        let res = sinq(0..<10).takeWhile{ $0 < 6 }
        XCTAssertEqual(res.count(), 6)
        var counter = 0
        for elem in res {
            XCTAssertEqual(elem, counter)
            counter += 1
        }
    }

    func testThenBy() {
        let sorted = sinq([(0, 1), (1, 1), (2, 0), (1, 0), (3, 1), (2, 1), (0, 0), (3, 0) ]).orderBy{$0.0}.thenBy{$0.1}
        var counter = 0
        for elem in sorted {
            XCTAssertEqual(elem.0, counter/2)
            XCTAssertEqual(elem.1, counter%2)
            counter += 1
        }
    }

    func testThenByDescending() {
        let sorted = sinq([(0, 1), (1, 1), (2, 0), (1, 0), (3, 1), (2, 1), (0, 0), (3, 0) ]).orderBy{$0.0}.thenByDescending{$0.1}
        var counter = 0
        for elem in sorted {
            XCTAssertEqual(elem.0, counter/2)
            XCTAssertEqual(elem.1, 1-counter%2)
            counter += 1
        }
    }
    
    func testToDictionary() {
        let res = sinq(0..<10).toDictionary{ 10 - $0 }
        XCTAssertEqual(res.count, 10)
        for (k, v) in res {
            XCTAssertEqual(k, 10-v)
        }
    }
    
    func testToLookupDictionary() {
        let res = sinq(0..<9).toLookupDictionary{ $0 % 3 }
        XCTAssertEqual(res.count, 3)
        for r in (0..<3) {
            var ctr = r
            XCTAssertEqual(res[r]!.count(), 3)
            for v in res[r]! {
                XCTAssertEqual(v, ctr)
                ctr += 3
            }
        }
    }

    func testUnion() {
        let seq = sinq([1, 2, 1, 2])
        let res1 = seq.union([3, 3, 2, 1]){$0 == $1}
        let res2 = seq.union([3, 3, 2, 1]){$0}
        XCTAssertEqual(res1.count(), 3)
        XCTAssertEqual(res2.count(), 3)
        var counter = 1
        for elem in res1 {
            XCTAssertEqual(elem, counter)
            counter += 1
        }
        counter = 1
        for elem in res2 {
            XCTAssertEqual(elem, counter)
            counter += 1
        }
    }
    
}

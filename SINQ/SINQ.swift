//
//  SINQ.swift
//  SINQ
//
//  Created by Leszek Ślażyński on 25/06/14.
//  Copyright (c) 2014 Leszek Ślażyński. All rights reserved.
//

// this does not compile (you cannot extend protocols)
//extension Sequence {

// this does compile but does not link (e.g. groupBy)
//extension SequenceOf {

// but we want to be inherited from anyways, hence class and composition
open class SinqSequence<T>: Sequence {

    fileprivate let sequence : AnySequence<T>

    open func makeIterator() -> AnyIterator<T> { return sequence.makeIterator() }
    
    public init<G : IteratorProtocol>(_ generate: @escaping () -> G) where G.Element == T {
        sequence = AnySequence(generate)
    }
    
    public init<S : Sequence>(_ self_: S) where S.Iterator.Element == T {
        sequence = AnySequence({ self_.makeIterator() })
    }
    
    public final func aggregate(_ combine: (T, T) -> T) -> T {
        return reduce(combine)
    }
    
    public final func aggregate<R>(_ initial: R, combine: (R, T) -> R) -> R {
        return reduce(initial, combine: combine)
    }

    public final func aggregate<C, R>(_ initial: C, combine: (C, T) -> C, result: (C) -> R) -> R {
        return reduce(initial, combine: combine, result: result)
    }
    
    open func reduce(_ combine: (T, T) -> T) -> T {
        let g = self.makeIterator()
        var r = g.next()!
        while let e = g.next() {
            r = combine(r, e)
        }
        return r
    }
    
    open func reduce<R>(_ initial: R, combine: (R, T) -> R) -> R {
        return sequence.reduce(initial, combine)
    }

    open func reduce<C, R>(_ initial: C, combine: (C, T) -> C, result: (C) -> R) -> R {
        return result(reduce(initial, combine: combine))
    }
    
    open func all(_ predicate: (T) -> Bool) -> Bool {
        for elem in self {
            if !predicate(elem) {
                return false
            }
        }
        return true
    }
    
    open func any() -> Bool {
        let g = self.makeIterator()
        return g.next() != nil
    }
    
    open func any(_ predicate: (T) -> Bool) -> Bool {
        for elem in self {
            if predicate(elem) {
                return true
            }
        }
        return false
    }
    
    open func concat
        <S: Sequence>
        (_ other: S) -> SinqSequence<T> where S.Iterator.Element == T
    {
        return SinqSequence { () -> AnyIterator<T> in
            let g1 = self.makeIterator()
            var g2 = other.makeIterator()
            return AnyIterator {
                switch g1.next() {
                case .some(let e): return e
                case _: return g2.next()
                }
            }
            
        }
    }
    
    open func contains(_ value: T, equality: (T, T) -> Bool) -> Bool {
        for e in self {
            if equality(e, value) {
                return true
            }
        }
        return false
    }

    open func contains<K: Equatable>(_ value: T, key: (T) -> K) -> Bool {
        return contains(value, equality: { key($0)==key($1) })
    }
    
//    public func contains<T: Equatable> (value: T) -> Bool {
//        return self.contains(value, equality: { $0 == $1 })
//    }
    
    open func count() -> Int {
        var counter = 0
        let gen = self.makeIterator()
        while gen.next() != nil {
            counter += 1
        }
        return counter
    }
    
    // O(N^2) :(
    open func distinct(_ equality: @escaping (T, T) -> Bool) -> SinqSequence<T> {
        return SinqSequence { () -> AnyIterator<T> in
            var uniq = [T]()
            let g = self.makeIterator()
            return AnyIterator {
                while let e = g.next() {
                    if !sinq(uniq).contains(e, equality: equality) {
                        uniq.append(e)
                        return e
                    }
                }
                return nil
            }
        }
    }
    
    open func distinct<K: Hashable>(_ key: @escaping (T) -> K) -> SinqSequence<T> {
        return SinqSequence { () -> AnyIterator<T> in
            var uniq = Dictionary<K, Bool>()
            let g = self.makeIterator()
            return AnyIterator {
                while let e = g.next() {
                    if uniq.updateValue(true, forKey: key(e)) == nil {
                        return e
                    }
                }
                return nil
            }
        }
    }
    
//    public func distinct<T: Equatable>() -> SinqSequence<T> {
//        return distinct({ $0 == $1 })
//    }
    
    open func each(_ function: (T) -> ()) {
        for elem in self {
            function(elem)
        }
    }
    
    open func elementAtOrNil(_ index: Int) -> T? {
        if (index < 0) {
            return nil
        }
        let g = self.makeIterator()
        for _ in 0..<index {
            let _ = g.next()
        }
        return g.next()
    }
    
    open func elementAt(_ index: Int) -> T {
        return elementAtOrNil(index)!
    }
    
    open func elementAt(_ index: Int, orDefault def: T) -> T {
        switch elementAtOrNil(index) {
        case .some(let e): return e
        case .none: return def
        }
    }
    
    // O(N*M) :(
    open func except
        <S: Sequence>
        (_ sequence: S, equality: @escaping (T, T) -> Bool) -> SinqSequence<T> where T == S.Iterator.Element
    {
        return SinqSequence { () -> AnyIterator<T> in
            let g = self.distinct(equality).makeIterator()
            let sinqSequence: SinqSequence<T> = sinq(sequence)
            return AnyIterator {
                while let e = g.next() {
                    if !sinqSequence.contains(e, equality: equality) {
                        return e
                    }
                }
                return nil
            }
        }
    }
    
    open func except
        <S: Sequence, K: Hashable>
        (_ sequence: S, key: @escaping (T) -> K) -> SinqSequence<T> where T == S.Iterator.Element
    {
        return SinqSequence { () -> AnyIterator<T> in
            let g = self.makeIterator()
            var uniq = sinq(sequence).toDictionary{(key($0), true)}
            return AnyIterator {
                while let e = g.next() {
                    if uniq.updateValue(true, forKey: key(e)) == nil {
                        return e
                    }
                }
                return nil
            }
        }
    }
    
//    public func except
//        <S: SequenceType, T: Equatable where T == S.Generator.Element>
//        (sequence: S) -> SinqSequence<T>
//    {
//        return self.except(sequence, equality: { $0 == $1 })
//    }
    
    open func first() -> T {
        return self.firstOrNil()!
    }
    
    open func firstOrNil() -> T? {
        let g = self.makeIterator()
        return g.next()
    }

    open func firstOrDefault(_ defaultElement: T) -> T {
        switch(self.firstOrNil()) {
        case .some(let e): return e
        case .none: return defaultElement
        }
    }
    
    open func first(_ predicate: (T) -> Bool) -> T {
        return self.firstOrNil(predicate)!
    }
    
    open func firstOrNil(_ predicate: (T) -> Bool) -> T? {
        let g = self.makeIterator()
        while let e = g.next() {
            if predicate(e) {
                return e
            }
        }
        return nil
    }
    
    open func firstOrDefault(_ defaultElement: T, predicate: (T) -> Bool) -> T {
        switch firstOrNil(predicate) {
        case .some(let e): return e
        case .none: return defaultElement
        }
    }
    
    open func groupBy
        <K: Hashable>
        (_ key: @escaping (T) -> K) -> SinqSequence<Grouping<K, T>>
    {
        return self.groupBy(key, element: { $0 })
    }

    open func groupBy
        <K: Hashable, V>
        (_ key: @escaping (T) -> K, element: @escaping (T) -> V) -> SinqSequence<Grouping<K, V>>
    {
        return SinqSequence<Grouping<K,V>> { () -> AnyIterator<Grouping<K,V>> in
            var groups = [K:[T]]()
            for element in self {
                let elemKey = key(element)
                if var group = groups[elemKey] {
                    group.append(element)
                    groups[elemKey] = group
                } else {
                    groups[elemKey] = [ element ]
                }
            }
            
            var keysGen = groups.keys.makeIterator()

            return AnyIterator {
                if let key = keysGen.next() {
                    let values = sinq(groups[key]!).select(element)
                    return Grouping(key: key, values: values)
                } else {
                    return nil
                }
            }
        }
    }
    
    open func groupBy
        <K: Hashable, V, R>
        (   _ key: @escaping (T) -> K,
            element: @escaping (T) -> V,
            result: @escaping (K, SinqSequence<V>) -> R
        ) -> SinqSequence<R>
    {
        return self.groupBy(key, element: element)
            .select{ result($0.key, $0.values) }
    }
    
    open func groupJoin
        <S: Sequence, K: Hashable, R>
        (   inner: S,
            outerKey: @escaping (T) -> K,
            innerKey: @escaping (S.Iterator.Element) -> K,
            result: @escaping (T, SinqSequence<S.Iterator.Element>) -> R
        ) -> SinqSequence<R>
    {
        return SinqSequence<R> { () -> AnyIterator<R> in

            var innerGrouping = Dictionary<K, [S.Iterator.Element]>()
            for element in inner {
                let key = innerKey(element)
                if var group = innerGrouping[key] {
                    group.append(element)
                    innerGrouping[key] = group
                } else {
                    innerGrouping[key] = [ element ]
                }
            }
            let gen = self.makeIterator()
            
            return AnyIterator {
                if let element = gen.next() {
                    let key = outerKey(element)
                    if let group = innerGrouping[key] {
                        return result(element, sinq(group))
                    } else {
                        return result(element, sinq(Array<S.Iterator.Element>()))
                    }
                } else {
                    return nil
                }
            }
        }
    }
    
    open func groupJoin
        <S: Sequence, K: Hashable>
        (   inner: S,
            outerKey: @escaping (T) -> K,
            innerKey: @escaping (S.Iterator.Element) -> K
        ) -> SinqSequence<Grouping<T, S.Iterator.Element>>
    {
        return groupJoin(inner: inner,
                         outerKey: outerKey,
                         innerKey: innerKey,
                         result: { Grouping(key: $0, values: $1) })
    }
    
    // O(N*M) :(
    open func intersect
        <S: Sequence>
        (_ sequence: S, equality: @escaping (T, T) -> Bool) -> SinqSequence<T> where S.Iterator.Element == T
    {
        return SinqSequence { () -> AnyIterator<T> in
            let g = self.distinct(equality).makeIterator()
            let sinqSequence : SinqSequence<T> = sinq(sequence)
            return AnyIterator {
                while let e = g.next() {
                    if sinqSequence.contains(e, equality: equality) {
                        return e
                    }
                }
                return nil
            }
        }
    }
    
    open func intersect
        <S: Sequence, K: Hashable>
        (_ sequence: S, key: @escaping (T) -> K) -> SinqSequence<T> where S.Iterator.Element == T
    {
        return SinqSequence { () -> AnyIterator<T> in
            let g = self.makeIterator()
            var uniq = sinq(sequence).toDictionary{(key($0), true)}
            return AnyIterator {
                while let e = g.next() {
                    if uniq.removeValue(forKey: key(e)) != nil {
                        return e
                    }
                }
                return nil
            }
        }
    }
    
    open func join
        <S: Sequence, K: Hashable, R>
        (   inner: S,
            outerKey: @escaping (T) -> K,
            innerKey: @escaping (S.Iterator.Element) -> K,
            result: @escaping (T, S.Iterator.Element) -> R
        ) -> SinqSequence<R>
    {
        return SinqSequence<R> { () -> AnyIterator<R> in
            var innerGrouping = Dictionary<K, [S.Iterator.Element]>()
            for element in inner {
                let key = innerKey(element)
                if var group = innerGrouping[key] {
                    group.append(element)
                    innerGrouping[key] = group
                } else {
                    innerGrouping[key] = [ element ]
                }
            }
            
            let gen1 = self.makeIterator()
            var innerElem: T? = nil
            var gen2: Array<S.Iterator.Element>.Iterator = Array<S.Iterator.Element>().makeIterator()

            return AnyIterator {
                while let element = gen2.next() {
                    return result(innerElem!, element)
                }
                while let element = gen1.next() {
                    let key = outerKey(element)
                    if let group = innerGrouping[key] {
                        gen2 = group.makeIterator()
                        innerElem = element
                        return result(element, gen2.next()!)
                    }
                }
                return nil
            }
        }
    }
    
    open func join
        <S: Sequence, K: Hashable>
        (   inner: S,
            outerKey: @escaping (T) -> K,
            innerKey: @escaping (S.Iterator.Element) -> K
        ) -> SinqSequence<(T, S.Iterator.Element)>
    {
        return join(inner: inner,
                    outerKey: outerKey,
                    innerKey: innerKey,
                    result: { ($0, $1) })
    }
    
    open func last(_ predicate: (T) -> Bool) -> T {
        return self.lastOrNil(predicate)!
    }
    
    open func lastOrNil(_ predicate: (T) -> Bool) -> T? {
        var eOrNil: T? = nil
        let g = self.makeIterator()
        while let e = g.next() {
            if predicate(e) {
                eOrNil = e
            }
        }
        return eOrNil
    }
    
    open func lastOrDefault(_ defaultElement: T, predicate: (T) -> Bool) -> T {
        switch self.lastOrNil(predicate) {
        case .some(let e): return e
        case .none: return defaultElement
        }
    }

    open func lastOrNil() -> T? {
        var eOrNil: T? = nil
        let g = self.makeIterator()
        while let e = g.next() {
            eOrNil = e
        }
        return eOrNil
    }
    
    open func last() -> T {
        return self.lastOrNil()!
    }
    
    open func lastOrDefault(_ defaultElement: T) -> T {
        switch (self.lastOrNil()) {
        case .some(let e): return e
        case .none: return defaultElement
        }
    }
    
    open func max<R: Comparable>(_ key: (T) -> R) -> R {
        let gen = self.makeIterator()
        var ret = key(gen.next()!)
        while let elem = gen.next().map(key) {
            if elem > ret {
                ret = elem
            }
        }
        return ret
    }
    
    open func min<R: Comparable>(_ key: (T) -> R) -> R {
        let gen = self.makeIterator()
        var ret = key(gen.next()!)
        while let elem = gen.next().map(key) {
            if elem < ret {
                ret = elem
            }
        }
        return ret
    }
    
    open func argmax<R: Comparable>(_ key: (T) -> R) -> T {
        let gen = self.makeIterator()
        var ret = gen.next()!
        var res = key(ret)
        while let arg = gen.next() {
            let elem = key(arg)
            if elem > res {
                res = elem
                ret = arg
            }
        }
        return ret
    }
    
    open func argmin<R: Comparable>(_ key: (T) -> R) -> T {
        let gen = self.makeIterator()
        var ret = gen.next()!
        var res = key(ret)
        while let arg = gen.next() {
            let elem = key(arg)
            if elem < res {
                res = elem
                ret = arg
            }
        }
        return ret
    }
    
    open func orderBy<K: Comparable>(_ key: @escaping (T) -> K) -> SinqOrderedSequence<T> {
        let comparator = { key($0) < key($1) }
        return SinqOrderedSequence(source: sequence, comparators: [ comparator ])
    }
    
    open func orderByDescending<K: Comparable>(_ key: @escaping (T) -> K) -> SinqOrderedSequence<T> {
        let comparator = { key($0) > key($1) }
        return SinqOrderedSequence(source: sequence, comparators: [ comparator ])
    }

    open func reverse() -> SinqSequence<T> {
        return SinqSequence { () -> IndexingIterator<[T]> in
            Array(self.toArray().reversed()).makeIterator()
        }
    }
    
    open func select<V>(_ selector: @escaping (T) -> V) -> SinqSequence<V> {
        return self.select({ (x, _) in selector(x) })
    }

    open func select<V>(_ selector: @escaping (T, Int) -> V) -> SinqSequence<V> {
        return SinqSequence<V> { () -> AnyIterator<V> in
            let g = self.makeIterator()
            var counter = 0
            return AnyIterator {
                if let e = g.next() {
                    let ret = selector(e, counter)
                    counter += 1
                    return ret
                }
                return nil
            }
        }
    }
    
    public final func map<V>(_ selector: @escaping (T) -> V) -> SinqSequence<V> {
        return select(selector)
    }
    
    public final func map<V>(_ selector: @escaping (T, Int) -> V) -> SinqSequence<V> {
        return select(selector)
    }

    open func selectMany<S: Sequence, R>(_ selector: @escaping (T, Int) -> S, result: @escaping (S.Iterator.Element) -> R) -> SinqSequence<R> {
        return SinqSequence<R> { () -> AnyIterator<R> in
            typealias C = S.Iterator.Element
            
            let gen1 = self.makeIterator()
            var gen2: AnySequence<C>.Iterator = SinqSequence<C>([C]()).makeIterator()
            var counter = 0
            
            return AnyIterator {
                while let element = gen2.next() {
                    return result(element)
                }
                while let element = gen1.next() {
                    let many = sinq(selector(element, counter))
                    counter += 1
                    gen2 = many.makeIterator()
                    if let inner = gen2.next() {
                        return result(inner)
                    }
                }
                return nil
            }
        }
    }
    
    open func selectMany<S: Sequence, R>(_ selector: @escaping (T) -> S, result: @escaping (S.Iterator.Element) -> R) -> SinqSequence<R> {
        return selectMany({ (x, _) in selector(x) }, result: result)
    }

    open func selectMany<S: Sequence>(_ selector: @escaping (T, Int) -> S) -> SinqSequence<S.Iterator.Element> {
        return selectMany(selector, result: { $0 })
    }
    
    open func selectMany<S: Sequence>(_ selector: @escaping (T) -> S) -> SinqSequence<S.Iterator.Element> {
        return selectMany({ (x, _) in selector(x) }, result: { $0 })
    }
    
    open func single() -> T {
        return self.singleOrNil()!
    }
    
    open func singleOrNil() -> T? {
        let gen = self.makeIterator()
        switch (gen.next(), gen.next()) {
        case (.some(let e), .none): return e
        case _: return nil
        }
    }
    
    open func singleOrDefault(_ defaultElement: T) -> T {
        switch self.singleOrNil() {
        case .some(let e): return e
        case .none: return defaultElement
        }
    }
    
    open func single(_ predicate: @escaping (T) -> Bool) -> T {
        return whereTrue(predicate).single()
    }
    
    open func singleOrNil(_ predicate: @escaping (T) -> Bool) -> T? {
        return whereTrue(predicate).singleOrNil()
    }
    
    open func singleOrDefault(_ defaultElement: T, predicate: @escaping (T) -> Bool) -> T {
        return whereTrue(predicate).singleOrDefault(defaultElement)
    }
    
    open func skip(_ count: Int) -> SinqSequence<T> {
        return SinqSequence { () -> AnyIterator<T> in
            let gen = self.makeIterator()
            for _ in 0..<count {
                let _ = gen.next()
            }
            return gen
        }
    }

    open func skipWhile(_ predicate: @escaping (T) -> Bool) -> SinqSequence<T> {
        return SinqSequence { () -> AnyIterator<T> in
            var found = false
            let gen = self.makeIterator()
            
            return AnyIterator {
                if found {
                    return gen.next()
                }
                while let e = gen.next() {
                    if !predicate(e) {
                        found = true
                        return e
                    }
                }
                return nil
            }
        }
    }

    // TODO: sum
    
    open func take(_ count: Int) -> SinqSequence<T> {
        return SinqSequence { () -> AnyIterator<T> in
            let gen = self.makeIterator()
            var counter = 0

            return AnyIterator {
                if counter >= count {
                    return nil
                }
                counter += 1
                return gen.next()
            }
        }
    }
    
    open func takeWhile(_ predicate: @escaping (T) -> Bool) -> SinqSequence<T> {
        return SinqSequence { () -> AnyIterator<T> in
            var found = false
            let gen = self.makeIterator()
        
            return AnyIterator {
                if found {
                    return nil
                }
                if let e = gen.next() {
                    if predicate(e) {
                        return e
                    } else {
                        found = true
                        return nil
                    }
                } else {
                    return nil
                }
            }
        }
    }
    
    
    open func thenBy<K: Comparable>(_ key: @escaping (T) -> K) -> SinqOrderedSequence<T> {
        return orderBy(key)
    }
    
    open func thenByDescending<K: Comparable>(_ key: @escaping (T) -> K) -> SinqOrderedSequence<T> {
        return orderByDescending(key)
    }

    open func toArray() -> [T] {
        return [T](self)
    }
    
    open func toDictionary
        <K: Hashable, V>
        (_ keyValue: (T) -> (K, V)) -> Dictionary<K, V>
    {
        var dict = Dictionary<K, V>()
        for elem in self {
            let (k, v) = keyValue(elem)
            dict[k] = v
        }
        return dict
    }
    
    open func toDictionary
        <K: Hashable, V>
        (_ key: (T) -> K, value: (T) -> V) -> Dictionary<K, V>
    {
        var dict = Dictionary<K, V>()
        for elem in self {
            dict[key(elem)] = value(elem)
        }
        return dict
    }

    open func toDictionary
        <K: Hashable>
        (_ key: (T) -> K) -> Dictionary<K, T>
    {
        var dict = Dictionary<K, T>()
        for elem in self {
            dict[key(elem)] = elem
        }
        return dict
    }

    open func toLookupDictionary
        <K: Hashable, V>
        (_ keyValue: @escaping (T) -> (K, V)) -> Dictionary<K, SinqSequence<V>>
    {
        return groupBy({ keyValue($0).0 }, element: { keyValue($0).1 }).toDictionary{ ($0.key, $0.values) }
    }

    open func toLookupDictionary
        <K: Hashable>
        (_ key: @escaping (T) -> K) -> Dictionary<K, SinqSequence<T>>
    {
        return groupBy(key).toDictionary{ ($0.key, $0.values) }
    }
    
    open func toLookupDictionary
        <K: Hashable, V>
        (_ key: @escaping (T) -> K, element: @escaping (T) -> V) -> Dictionary<K, SinqSequence<V>>
    {
        return groupBy(key, element: element).toDictionary{ ($0.key, $0.values) }
    }
    
    //TODO: sequence equal
 
    // O(N*(N+M)) :(
    open func union
        <S: Sequence>
        (_ sequence: S, equality: @escaping (T, T) -> Bool) -> SinqSequence<T> where S.Iterator.Element == T
    {
        return self.distinct(equality).concat(sinq(sequence).distinct(equality).except(self, equality: equality))
    }
    
    open func union
        <S: Sequence, K: Hashable>
        (_ sequence: S, key: @escaping (T) -> K) -> SinqSequence<T> where S.Iterator.Element == T
    {
        return self.distinct(key).concat(sinq(sequence).distinct(key).except(self, key: key))
    }

    open func zip<S: Sequence, R>(_ sequence: S, result: @escaping (T, S.Iterator.Element) -> R) -> SinqSequence<R> {
        return SinqSequence<R> { () -> AnyIterator<R> in
            let gen1 = self.makeIterator()
            var gen2 = sequence.makeIterator()
            return AnyIterator {
                switch (gen1.next(), gen2.next()) {
                case (.some(let e1), .some(let e2)): return result(e1, e2)
                case (_, _): return nil
                }
            }
        }
    }
    
    open func whereTrue(_ predicate: @escaping (T) -> Bool) -> SinqSequence<T> {
        return SinqSequence { () -> AnyIterator<T> in
            let gen = self.makeIterator()
            return AnyIterator {
                while let e = gen.next() {
                    if predicate(e) {
                        return e
                    }
                }
                return nil
            }
        }
    }
    
    public final func filter(_ predicate: @escaping (T) -> Bool) -> SinqSequence<T> {
        return whereTrue(predicate)
    }

}

open class SinqOrderedSequence<T> : SinqSequence<T> {
    
    open override func makeIterator() -> AnyIterator<T> {
        var array = sinq(sequence).toArray()
        array.sort {
            (a: T, b: T) in
            for comparator in self.comparators {
                if comparator(a, b) {
                    return true
                }
                if comparator(b, a) {
                    return false
                }
            }
            return false
        }
        return AnyIterator(array.makeIterator())
    }

    public init<S: Sequence>(source: S, comparators: Array<(T, T) -> Bool>) where S.Iterator.Element == T {
        self.comparators = comparators
        super.init(source)
    }
    
    fileprivate let comparators : Array<(T, T) -> Bool>
    
    open override func orderBy<K: Comparable>(_ key: @escaping (T) -> K) -> SinqOrderedSequence<T> {
        let comparator = { key($0) < key($1) }
        return SinqOrderedSequence(source: sequence, comparators: [ comparator ])
    }
    
    open override func orderByDescending<K: Comparable>(_ key: @escaping (T) -> K) -> SinqOrderedSequence<T> {
        let comparator = { key($0) > key($1) }
        return SinqOrderedSequence(source: sequence, comparators: [ comparator ])
    }

    open override func thenBy<K: Comparable>(_ key: @escaping (T) -> K) -> SinqOrderedSequence<T> {
        var newComparators = comparators
        newComparators.append { key($0) < key($1) }
        return SinqOrderedSequence(source: sequence, comparators: newComparators)
    }
    
    open override func thenByDescending<K: Comparable>(_ key: @escaping (T) -> K) -> SinqOrderedSequence<T> {
        var newComparators = comparators
        newComparators.append { key($0) > key($1) }
        return SinqOrderedSequence(source: sequence, comparators: newComparators)
    }
    
    // override to filter before sorting...
    open override func whereTrue(_ predicate: @escaping (T) -> Bool) -> SinqSequence<T> {
        return SinqOrderedSequence(source: sinq(sequence).whereTrue(predicate), comparators: comparators)
    }
    
}

public func from <S: Sequence> (_ sequence: S) -> SinqSequence<S.Iterator.Element> {
    return SinqSequence(sequence)
}

public func sinq <S: Sequence> (_ sequence: S) -> SinqSequence<S.Iterator.Element> {
    return SinqSequence(sequence)
}

public struct Grouping<K, V> {
    public let key: K
    public let values: SinqSequence<V>
}

extension Grouping: Sequence {
    public typealias Iterator = SinqSequence<V>.Iterator
    public func makeIterator() -> Iterator { return values.makeIterator() }
}

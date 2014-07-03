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
class SinqSequence<T>: Sequence {

    let _seq : SequenceOf<T>

    typealias GeneratorType = SequenceOf<T>.GeneratorType
    func generate() -> GeneratorType { return _seq.generate() }
    
    init<G : Generator where G.Element == T>(_ generate: () -> G) {
        _seq = SequenceOf(generate)
    }
    
    init<S : Sequence where S.GeneratorType.Element == T>(_ self_: S) {
        _seq = SequenceOf(self_)
    }
    
    func aggregate(combine: (T, T) -> T) -> T {
        return reduce(combine)
    }
    
    func aggregate<R>(initial: R, combine: (R, T) -> R) -> R {
        return reduce(initial, combine: combine)
    }

    func aggregate<C, R>(initial: C, combine: (C, T) -> C, result: C -> R) -> R {
        return reduce(initial, combine: combine, result: result)
    }
    
    func reduce(combine: (T, T) -> T) -> T {
        var g = self.generate()
        var r = g.next()!
        while let e = g.next() {
            r = combine(r, e)
        }
        return r
    }
    
    func reduce<R>(initial: R, combine: (R, T) -> R) -> R {
        return Swift.reduce(_seq, initial, combine)
    }

    func reduce<C, R>(initial: C, combine: (C, T) -> C, result: C -> R) -> R {
        return result(Swift.reduce(_seq, initial, combine))
    }
    
    func all(predicate: T -> Bool) -> Bool {
        for elem in self {
            if !predicate(elem) {
                return false
            }
        }
        return true
    }
    
    func any() -> Bool {
        var g = self.generate()
        return g.next() != nil
    }
    
    func any(predicate: T -> Bool) -> Bool {
        for elem in self {
            if predicate(elem) {
                return true
            }
        }
        return false
    }
    
    func concat
        <S: Sequence where S.GeneratorType.Element == T>
        (other: S) -> SinqSequence<T>
    {
        return SinqSequence { () -> GeneratorOf<T> in
            var g1 = self.generate()
            var g2 = other.generate()
            return GeneratorOf {
                switch g1.next() {
                case .Some(let e): return e
                case _: return g2.next()
                }
            }
            
        }
    }
    
    func contains(value: T, equality: (T, T) -> Bool) -> Bool {
        for e in self {
            if equality(e, value) {
                return true
            }
        }
        return false
    }

    func contains<K: Equatable>(value: T, key: T -> K) -> Bool {
        return self.contains(value, equality: { key($0)==key($1) })
    }
    
//    func contains<T: Equatable> (value: T) -> Bool {
//        return self.contains(value, equality: { $0 == $1 })
//    }
    
    func count() -> Int {
        var counter = 0
        var gen = self.generate()
        while gen.next() {
            counter += 1
        }
        return counter
    }
    
    // O(N^2) :(
    func distinct(equality: (T, T) -> Bool) -> SinqSequence<T> {
        return SinqSequence { () -> GeneratorOf<T> in
            var uniq = T[]()
            var g = self.generate()
            return GeneratorOf {
                while let e = g.next() {
                    if !sinq(uniq).contains(e, equality: equality) {
                        uniq += e
                        return e
                    }
                }
                return nil
            }
        }
    }
    
    func distinct<K: Hashable>(key: T -> K) -> SinqSequence<T> {
        return SinqSequence { () -> GeneratorOf<T> in
            var uniq = Dictionary<K, Bool>()
            var g = self.generate()
            return GeneratorOf {
                while let e = g.next() {
                    if !uniq.updateValue(true, forKey: key(e)) {
                        return e
                    }
                }
                return nil
            }
        }
    }
    
//    func distinct<T: Equatable>() -> SinqSequence<T> {
//        return distinct({ $0 == $1 })
//    }
    
    func elementAtOrNil(index: Int) -> T? {
        if (index < 0) {
            return nil
        }
        var g = self.generate()
        for _ in 0..index {
            g.next()
        }
        return g.next()
    }
    
    func elementAt(index: Int) -> T {
        return elementAtOrNil(index)!
    }
    
    func elementAt(index: Int, orDefault def: T) -> T {
        switch elementAtOrNil(index) {
        case .Some(let e): return e
        case .None: return def
        }
    }
    
    // O(N*M) :(
    func except
        <S: Sequence where T == S.GeneratorType.Element>
        (sequence: S, equality: (T, T) -> Bool) -> SinqSequence<T>
    {
        return SinqSequence { () -> GeneratorOf<T> in
            var g = self.distinct(equality).generate()
            let sinqSequence: SinqSequence<T> = sinq(sequence)
            return GeneratorOf {
                while let e = g.next() {
                    if !sinqSequence.contains(e, equality: equality) {
                        return e
                    }
                }
                return nil
            }
        }
    }
    
    func except
        <S: Sequence, K: Hashable where T == S.GeneratorType.Element>
        (sequence: S, key: T -> K) -> SinqSequence<T>
    {
        return SinqSequence { () -> GeneratorOf<T> in
            var g = self.generate()
            var uniq = sinq(sequence).toDictionary{(key($0), true)}
            return GeneratorOf {
                while let e = g.next() {
                    if !uniq.updateValue(true, forKey: key(e)) {
                        return e
                    }
                }
                return nil
            }
        }
    }
    
//    func except
//        <S: Sequence, T: Equatable where T == S.GeneratorType.Element>
//        (sequence: S) -> SinqSequence<T>
//    {
//        return self.except(sequence, equality: { $0 == $1 })
//    }
    
    func first() -> T {
        return self.firstOrNil()!
    }
    
    func firstOrNil() -> T? {
        var g = self.generate()
        return g.next()
    }

    func firstOrDefault(defaultElement: T) -> T {
        switch(self.firstOrNil()) {
        case .Some(let e): return e
        case .None: return defaultElement
        }
    }
    
    func first(predicate: T -> Bool) -> T {
        return self.firstOrNil(predicate)!
    }
    
    func firstOrNil(predicate: T -> Bool) -> T? {
        var g = self.generate()
        while let e = g.next() {
            if predicate(e) {
                return e
            }
        }
        return nil
    }
    
    func firstOrDefault(defaultElement: T, predicate: T -> Bool) -> T {
        switch firstOrNil(predicate) {
        case .Some(let e): return e
        case .None: return defaultElement
        }
    }
    
    func groupBy
        <K: Hashable>
        (key: T -> K) -> SinqSequence<Grouping<K, T>>
    {
        return self.groupBy(key, element: { $0 })
    }

    func groupBy
        <K: Hashable, V>
        (key: T -> K, element: T -> V) -> SinqSequence<Grouping<K, V>>
    {
        return SinqSequence<Grouping<K,V>> { () -> GeneratorOf<Grouping<K,V>> in
            var groups = Dictionary<K, T[]>()
            for element in self {
                let elemKey = key(element)
                if var group = groups[elemKey] {
                    group += element
                    groups[elemKey] = group
                } else {
                    groups[elemKey] = [ element ]
                }
            }
            
            var keysGen = groups.keys.generate()

            return GeneratorOf {
                if let key = keysGen.next() {
                    let values = sinq(groups[key]!).select(element)
                    return Grouping(key: key, values: values)
                } else {
                    return nil
                }
            }
        }
    }
    
    func groupBy
        <K: Hashable, V, R>
        (   key: T -> K,
            element: T -> V,
            result: (K, SinqSequence<V>) -> R
        ) -> SinqSequence<R>
    {
        return self.groupBy(key, element)
            .select{ result($0.key, $0.values) }
    }
    
    func groupJoin
        <S: Sequence, K: Hashable, R>
        (   #inner: S,
            outerKey: T -> K,
            innerKey: S.GeneratorType.Element -> K,
            result: (T, SinqSequence<S.GeneratorType.Element>) -> R
        ) -> SinqSequence<R>
    {
        return SinqSequence<R> { () -> GeneratorOf<R> in

            var innerGrouping = Dictionary<K, S.GeneratorType.Element[]>()
            for element in inner {
                let key = innerKey(element)
                if var group = innerGrouping[key] {
                    group += element
                    innerGrouping[key] = group
                } else {
                    innerGrouping[key] = [ element ]
                }
            }
            var gen = self.generate()
            
            return GeneratorOf {
                if let element = gen.next() {
                    let key = outerKey(element)
                    if let group = innerGrouping[key] {
                        return result(element, sinq(group))
                    } else {
                        return result(element, sinq(Array<S.GeneratorType.Element>()))
                    }
                } else {
                    return nil
                }
            }
        }
    }
    
    func groupJoin
        <S: Sequence, K: Hashable>
        (   #inner: S,
            outerKey: T -> K,
            innerKey: S.GeneratorType.Element -> K
        ) -> SinqSequence<Grouping<T, S.GeneratorType.Element>>
    {
        return groupJoin(inner: inner,
                         outerKey: outerKey,
                         innerKey: innerKey,
                         result: { Grouping(key: $0, values: $1) })
    }
    
    // O(N*M) :(
    func intersect
        <S: Sequence where S.GeneratorType.Element == T>
        (sequence: S, equality: (T, T) -> Bool) -> SinqSequence<T>
    {
        return SinqSequence { () -> GeneratorOf<T> in
            var g = self.distinct(equality).generate()
            let sinqSequence : SinqSequence<T> = sinq(sequence)
            return GeneratorOf {
                while let e = g.next() {
                    if sinqSequence.contains(e, equality: equality) {
                        return e
                    }
                }
                return nil
            }
        }
    }
    
    func intersect
        <S: Sequence, K: Hashable where S.GeneratorType.Element == T>
        (sequence: S, key: T -> K) -> SinqSequence<T>
    {
        return SinqSequence { () -> GeneratorOf<T> in
            var g = self.generate()
            var uniq = sinq(sequence).toDictionary{(key($0), true)}
            return GeneratorOf {
                while let e = g.next() {
                    if uniq.removeValueForKey(key(e)) {
                        return e
                    }
                }
                return nil
            }
        }
    }
    
    func join
        <S: Sequence, K: Hashable, R>
        (   #inner: S,
            outerKey: T -> K,
            innerKey: S.GeneratorType.Element -> K,
            result: (T, S.GeneratorType.Element) -> R
        ) -> SinqSequence<R>
    {
        return SinqSequence<R> { () -> GeneratorOf<R> in
            var innerGrouping = Dictionary<K, S.GeneratorType.Element[]>()
            for element in inner {
                let key = innerKey(element)
                if var group = innerGrouping[key] {
                    group += element
                    innerGrouping[key] = group
                } else {
                    innerGrouping[key] = [ element ]
                }
            }
            
            var gen1 = self.generate()
            var innerElem: T? = nil
            var gen2: Array<S.GeneratorType.Element>.GeneratorType = Array<S.GeneratorType.Element>().generate()

            return GeneratorOf {
                while let element = gen2.next() {
                    return result(innerElem!, element)
                }
                while let element = gen1.next() {
                    let key = outerKey(element)
                    if let group = innerGrouping[key] {
                        gen2 = group.generate()
                        innerElem = element
                        return result(element, gen2.next()!)
                    }
                }
                return nil
            }
        }
    }
    
    func join
        <S: Sequence, K: Hashable>
        (   #inner: S,
            outerKey: T -> K,
            innerKey: S.GeneratorType.Element -> K
        ) -> SinqSequence<(T, S.GeneratorType.Element)>
    {
        return join(inner: inner,
                    outerKey: outerKey,
                    innerKey: innerKey,
                    result: { ($0, $1) })
    }
    
    func last(predicate: T -> Bool) -> T {
        return self.lastOrNil(predicate)!
    }
    
    func lastOrNil(predicate: T -> Bool) -> T? {
        var eOrNil: T? = nil
        var g = self.generate()
        while let e = g.next() {
            if predicate(e) {
                eOrNil = e
            }
        }
        return eOrNil
    }
    
    func lastOrDefault(defaultElement: T, predicate: T -> Bool) -> T {
        switch self.lastOrNil(predicate) {
        case .Some(let e): return e
        case .None: return defaultElement
        }
    }

    func lastOrNil() -> T? {
        var eOrNil: T? = nil
        var g = self.generate()
        while let e = g.next() {
            eOrNil = e
        }
        return eOrNil
    }
    
    func last() -> T {
        return self.lastOrNil()!
    }
    
    func lastOrDefault(defaultElement: T) -> T {
        switch (self.lastOrNil()) {
        case .Some(let e): return e
        case .None: return defaultElement
        }
    }
    
    func max<R: Comparable>(key: T -> R) -> R {
        var gen = self.generate()
        var ret = key(gen.next()!)
        while let elem = gen.next().map(key) {
            if elem > ret {
                ret = elem
            }
        }
        return ret
    }
    
    func min<R: Comparable>(key: T -> R) -> R {
        var gen = self.generate()
        var ret = key(gen.next()!)
        while let elem = gen.next().map(key) {
            if elem < ret {
                ret = elem
            }
        }
        return ret
    }
    
    func argmax<R: Comparable>(key: T -> R) -> T {
        var gen = self.generate()
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
    
    func argmin<R: Comparable>(key: T -> R) -> T {
        var gen = self.generate()
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
    
    func orderBy<K: Comparable>(key: T -> K) -> SinqOrderedSequence<T> {
        let comparator = { key($0) < key($1) }
        return SinqOrderedSequence(source: _seq, comparators: [ comparator ])
    }
    
    func orderByDescending<K: Comparable>(key: T -> K) -> SinqOrderedSequence<T> {
        let comparator = { key($0) > key($1) }
        return SinqOrderedSequence(source: _seq, comparators: [ comparator ])
    }

    func reverse() -> SinqSequence<T> {
        return SinqSequence { () -> IndexingGenerator<T[]> in
            self.toArray().reverse().generate()
        }
    }
    
    func select<V>(selector: T -> V) -> SinqSequence<V> {
        return self.select({ (x, _) in selector(x) })
    }

    func select<V>(selector: (T, Int) -> V) -> SinqSequence<V> {
        return SinqSequence<V> { () -> GeneratorOf<V> in
            var g = self.generate()
            var counter = 0
            return GeneratorOf {
                if let e = g.next() {
                    return selector(e, counter++)
                }
                return nil
            }
        }
    }
    
    func map<V>(selector: T -> V) -> SinqSequence<V> {
        return select(selector)
    }
    
    func map<V>(selector: (T, Int) -> V) -> SinqSequence<V> {
        return select(selector)
    }

    func selectMany<S: Sequence, R>(selector: (T, Int) -> S, result: S.GeneratorType.Element -> R) -> SinqSequence<R> {
        return SinqSequence<R> { () -> GeneratorOf<R> in
            typealias C = S.GeneratorType.Element
            
            var gen1 = self.generate()
            var gen2: SequenceOf<C>.GeneratorType = SinqSequence<C>(C[]()).generate()
            var counter = 0
            
            return GeneratorOf {
                while let element = gen2.next() {
                    return result(element)
                }
                while let element = gen1.next() {
                    let many = sinq(selector(element, counter++))
                    gen2 = many.generate()
                    if let inner = gen2.next() {
                        return result(inner)
                    }
                }
                return nil
            }
        }
    }
    
    func selectMany<S: Sequence, R>(selector: T -> S, result: S.GeneratorType.Element -> R) -> SinqSequence<R> {
        return selectMany({ (x, _) in selector(x) }, result)
    }

    func selectMany<S: Sequence>(selector: (T, Int) -> S) -> SinqSequence<S.GeneratorType.Element> {
        return selectMany(selector, result: { $0 })
    }
    
    func selectMany<S: Sequence>(selector: T -> S) -> SinqSequence<S.GeneratorType.Element> {
        return selectMany({ (x, _) in selector(x) }, result: { $0 })
    }
    
    // TODO: single
    
    func skip(count: Int) -> SinqSequence<T> {
        return SinqSequence { () -> GeneratorOf<T> in
            var gen = self.generate()
            for _ in 0..count {
                gen.next()
            }
            return gen
        }
    }

    func skipWhile(predicate: T -> Bool) -> SinqSequence<T> {
        return SinqSequence { () -> GeneratorOf<T> in
            var found = false
            var gen = self.generate()
            
            return GeneratorOf {
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
    
    func take(count: Int) -> SinqSequence<T> {
        return SinqSequence { () -> GeneratorOf<T> in
            var gen = self.generate()
            var counter = 0

            return GeneratorOf {
                if counter >= count {
                    return nil
                }
                counter += 1
                return gen.next()
            }
        }
    }
    
    func takeWhile(predicate: T -> Bool) -> SinqSequence<T> {
        return SinqSequence { () -> GeneratorOf<T> in
            var found = false
            var gen = self.generate()
        
            return GeneratorOf {
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
    
    
    func thenBy<K: Comparable>(key: T -> K) -> SinqOrderedSequence<T> {
        return orderBy(key)
    }
    
    func thenByDescending<K: Comparable>(key: T -> K) -> SinqOrderedSequence<T> {
        return orderByDescending(key)
    }

    func toArray() -> T[] {
        return T[](self)
    }
    
    func toDictionary
        <K: Hashable, V>
        (keyValue: T -> (K, V)) -> Dictionary<K, V>
    {
        var dict = Dictionary<K, V>()
        for elem in self {
            let (k, v) = keyValue(elem)
            dict[k] = v
        }
        return dict
    }
    
    func toDictionary
        <K: Hashable, V>
        (key: T -> K, value: T -> V) -> Dictionary<K, V>
    {
        var dict = Dictionary<K, V>()
        for elem in self {
            dict[key(elem)] = value(elem)
        }
        return dict
    }

    func toDictionary
        <K: Hashable>
        (key: T -> K) -> Dictionary<K, T>
    {
        var dict = Dictionary<K, T>()
        for elem in self {
            dict[key(elem)] = elem
        }
        return dict
    }

    //TODO: sequence equal
 
    // O(N*(N+M)) :(
    func union
        <S: Sequence where S.GeneratorType.Element == T>
        (sequence: S, equality: (T, T) -> Bool) -> SinqSequence<T>
    {
        return self.distinct(equality).concat(sinq(sequence).distinct(equality).except(self, equality: equality))
    }
    
    func union
        <S: Sequence, K: Hashable where S.GeneratorType.Element == T>
        (sequence: S, key: T -> K) -> SinqSequence<T>
    {
        return self.distinct(key).concat(sinq(sequence).distinct(key).except(self, key: key))
    }

    func zip<S: Sequence, R>(sequence: S, result: (T, S.GeneratorType.Element) -> R) -> SinqSequence<R> {
        return SinqSequence<R> { () -> GeneratorOf<R> in
            var gen1 = self.generate()
            var gen2 = sequence.generate()
            return GeneratorOf {
                switch (gen1.next(), gen2.next()) {
                case (.Some(let e1), .Some(let e2)): return result(e1, e2)
                case (_, _): return nil
                }
            }
        }
    }
    
    func whereTrue(predicate: T -> Bool) -> SinqSequence<T> {
        return SinqSequence(Swift.filter(self, predicate))
    }
    
    func filter(predicate: T -> Bool) -> SinqSequence<T> {
        return whereTrue(predicate)
    }

    
}

class SinqOrderedSequence<T> : SinqSequence<T>, Sequence {
    
    override func generate() -> GeneratorType {
        let sorted = sort(sinq(_seq).toArray()) {
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
        return GeneratorOf(sorted.generate())
    }

    init<S: Sequence where S.GeneratorType.Element == T>(source: S, comparators: Array<(T, T) -> Bool>) {
        self.comparators = comparators
        super.init(source)
    }
    
    let comparators : Array<(T, T) -> Bool>
    
    override func orderBy<K: Comparable>(key: T -> K) -> SinqOrderedSequence<T> {
        let comparator = { key($0) < key($1) }
        return SinqOrderedSequence(source: _seq, comparators: [ comparator ])
    }
    
    override func orderByDescending<K: Comparable>(key: T -> K) -> SinqOrderedSequence<T> {
        let comparator = { key($0) > key($1) }
        return SinqOrderedSequence(source: _seq, comparators: [ comparator ])
    }

    override func thenBy<K: Comparable>(key: T -> K) -> SinqOrderedSequence<T> {
        var newComparators = comparators
        newComparators += { key($0) < key($1) }
        return SinqOrderedSequence(source: _seq, comparators: newComparators)
    }
    
    override func thenByDescending<K: Comparable>(key: T -> K) -> SinqOrderedSequence<T> {
        var newComparators = comparators
        newComparators += { key($0) > key($1) }
        return SinqOrderedSequence(source: _seq, comparators: newComparators)
    }
    
    // override to filter before sorting...
    override func whereTrue(predicate: T -> Bool) -> SinqSequence<T> {
        return SinqOrderedSequence(source: sinq(_seq).whereTrue(predicate), comparators: comparators)
    }
    
}

func from <S: Sequence> (sequence: S) -> SinqSequence<S.GeneratorType.Element> {
    return SinqSequence(sequence)
}

func sinq <S: Sequence> (sequence: S) -> SinqSequence<S.GeneratorType.Element> {
    return SinqSequence(sequence)
}

struct Grouping<K, V> {
    let key: K
    let values: SinqSequence<V>
}

extension Grouping: Sequence {
    typealias GeneratorType = SinqSequence<V>.GeneratorType
    func generate() -> GeneratorType { return values.generate() }
}

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
public class SinqSequence<T>: SequenceType {

    private let sequence : SequenceOf<T>

    public func generate() -> GeneratorOf<T> { return sequence.generate() }
    
    public init<G : GeneratorType where G.Element == T>(_ generate: () -> G) {
        sequence = SequenceOf(generate)
    }
    
    public init<S : SequenceType where S.Generator.Element == T>(_ self_: S) {
        sequence = SequenceOf(self_)
    }
    
    public final func aggregate(combine: (T, T) -> T) -> T {
        return reduce(combine)
    }
    
    public final func aggregate<R>(initial: R, combine: (R, T) -> R) -> R {
        return reduce(initial, combine: combine)
    }

    public final func aggregate<C, R>(initial: C, combine: (C, T) -> C, result: C -> R) -> R {
        return reduce(initial, combine: combine, result: result)
    }
    
    public func reduce(combine: (T, T) -> T) -> T {
        var g = self.generate()
        var r = g.next()!
        while let e = g.next() {
            r = combine(r, e)
        }
        return r
    }
    
    public func reduce<R>(initial: R, combine: (R, T) -> R) -> R {
        return Swift.reduce(sequence, initial, combine)
    }

    public func reduce<C, R>(initial: C, combine: (C, T) -> C, result: C -> R) -> R {
        return result(reduce(initial, combine: combine))
    }
    
    public func all(predicate: T -> Bool) -> Bool {
        for elem in self {
            if !predicate(elem) {
                return false
            }
        }
        return true
    }
    
    public func any() -> Bool {
        var g = self.generate()
        return g.next() != nil
    }
    
    public func any(predicate: T -> Bool) -> Bool {
        for elem in self {
            if predicate(elem) {
                return true
            }
        }
        return false
    }
    
    public func concat
        <S: SequenceType where S.Generator.Element == T>
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
    
    public func contains(value: T, equality: (T, T) -> Bool) -> Bool {
        for e in self {
            if equality(e, value) {
                return true
            }
        }
        return false
    }

    public func contains<K: Equatable>(value: T, key: T -> K) -> Bool {
        return contains(value, equality: { key($0)==key($1) })
    }
    
//    public func contains<T: Equatable> (value: T) -> Bool {
//        return self.contains(value, equality: { $0 == $1 })
//    }
    
    public func count() -> Int {
        var counter = 0
        var gen = self.generate()
        while gen.next() != nil {
            counter += 1
        }
        return counter
    }
    
    // O(N^2) :(
    public func distinct(equality: (T, T) -> Bool) -> SinqSequence<T> {
        return SinqSequence { () -> GeneratorOf<T> in
            var uniq = [T]()
            var g = self.generate()
            return GeneratorOf {
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
    
    public func distinct<K: Hashable>(key: T -> K) -> SinqSequence<T> {
        return SinqSequence { () -> GeneratorOf<T> in
            var uniq = Dictionary<K, Bool>()
            var g = self.generate()
            return GeneratorOf {
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
    
    public func each(function: T -> ()) {
        for elem in self {
            function(elem)
        }
    }
    
    public func elementAtOrNil(index: Int) -> T? {
        if (index < 0) {
            return nil
        }
        var g = self.generate()
        for _ in 0..<index {
            g.next()
        }
        return g.next()
    }
    
    public func elementAt(index: Int) -> T {
        return elementAtOrNil(index)!
    }
    
    public func elementAt(index: Int, orDefault def: T) -> T {
        switch elementAtOrNil(index) {
        case .Some(let e): return e
        case .None: return def
        }
    }
    
    // O(N*M) :(
    public func except
        <S: SequenceType where T == S.Generator.Element>
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
    
    public func except
        <S: SequenceType, K: Hashable where T == S.Generator.Element>
        (sequence: S, key: T -> K) -> SinqSequence<T>
    {
        return SinqSequence { () -> GeneratorOf<T> in
            var g = self.generate()
            var uniq = sinq(sequence).toDictionary{(key($0), true)}
            return GeneratorOf {
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
    
    public func first() -> T {
        return self.firstOrNil()!
    }
    
    public func firstOrNil() -> T? {
        var g = self.generate()
        return g.next()
    }

    public func firstOrDefault(defaultElement: T) -> T {
        switch(self.firstOrNil()) {
        case .Some(let e): return e
        case .None: return defaultElement
        }
    }
    
    public func first(predicate: T -> Bool) -> T {
        return self.firstOrNil(predicate)!
    }
    
    public func firstOrNil(predicate: T -> Bool) -> T? {
        var g = self.generate()
        while let e = g.next() {
            if predicate(e) {
                return e
            }
        }
        return nil
    }
    
    public func firstOrDefault(defaultElement: T, predicate: T -> Bool) -> T {
        switch firstOrNil(predicate) {
        case .Some(let e): return e
        case .None: return defaultElement
        }
    }
    
    public func groupBy
        <K: Hashable>
        (key: T -> K) -> SinqSequence<Grouping<K, T>>
    {
        return self.groupBy(key, element: { $0 })
    }

    public func groupBy
        <K: Hashable, V>
        (key: T -> K, element: T -> V) -> SinqSequence<Grouping<K, V>>
    {
        return SinqSequence<Grouping<K,V>> { () -> GeneratorOf<Grouping<K,V>> in
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
    
    public func groupBy
        <K: Hashable, V, R>
        (   key: T -> K,
            element: T -> V,
            result: (K, SinqSequence<V>) -> R
        ) -> SinqSequence<R>
    {
        return self.groupBy(key, element: element)
            .select{ result($0.key, $0.values) }
    }
    
    public func groupJoin
        <S: SequenceType, K: Hashable, R>
        (   #inner: S,
            outerKey: T -> K,
            innerKey: S.Generator.Element -> K,
            result: (T, SinqSequence<S.Generator.Element>) -> R
        ) -> SinqSequence<R>
    {
        return SinqSequence<R> { () -> GeneratorOf<R> in

            var innerGrouping = Dictionary<K, [S.Generator.Element]>()
            for element in inner {
                let key = innerKey(element)
                if var group = innerGrouping[key] {
                    group.append(element)
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
                        return result(element, sinq(Array<S.Generator.Element>()))
                    }
                } else {
                    return nil
                }
            }
        }
    }
    
    public func groupJoin
        <S: SequenceType, K: Hashable>
        (   #inner: S,
            outerKey: T -> K,
            innerKey: S.Generator.Element -> K
        ) -> SinqSequence<Grouping<T, S.Generator.Element>>
    {
        return groupJoin(inner: inner,
                         outerKey: outerKey,
                         innerKey: innerKey,
                         result: { Grouping(key: $0, values: $1) })
    }
    
    // O(N*M) :(
    public func intersect
        <S: SequenceType where S.Generator.Element == T>
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
    
    public func intersect
        <S: SequenceType, K: Hashable where S.Generator.Element == T>
        (sequence: S, key: T -> K) -> SinqSequence<T>
    {
        return SinqSequence { () -> GeneratorOf<T> in
            var g = self.generate()
            var uniq = sinq(sequence).toDictionary{(key($0), true)}
            return GeneratorOf {
                while let e = g.next() {
                    if uniq.removeValueForKey(key(e)) != nil {
                        return e
                    }
                }
                return nil
            }
        }
    }
    
    public func join
        <S: SequenceType, K: Hashable, R>
        (   #inner: S,
            outerKey: T -> K,
            innerKey: S.Generator.Element -> K,
            result: (T, S.Generator.Element) -> R
        ) -> SinqSequence<R>
    {
        return SinqSequence<R> { () -> GeneratorOf<R> in
            var innerGrouping = Dictionary<K, [S.Generator.Element]>()
            for element in inner {
                let key = innerKey(element)
                if var group = innerGrouping[key] {
                    group.append(element)
                    innerGrouping[key] = group
                } else {
                    innerGrouping[key] = [ element ]
                }
            }
            
            var gen1 = self.generate()
            var innerElem: T? = nil
            var gen2: Array<S.Generator.Element>.Generator = Array<S.Generator.Element>().generate()

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
    
    public func join
        <S: SequenceType, K: Hashable>
        (   #inner: S,
            outerKey: T -> K,
            innerKey: S.Generator.Element -> K
        ) -> SinqSequence<(T, S.Generator.Element)>
    {
        return join(inner: inner,
                    outerKey: outerKey,
                    innerKey: innerKey,
                    result: { ($0, $1) })
    }
    
    public func last(predicate: T -> Bool) -> T {
        return self.lastOrNil(predicate)!
    }
    
    public func lastOrNil(predicate: T -> Bool) -> T? {
        var eOrNil: T? = nil
        var g = self.generate()
        while let e = g.next() {
            if predicate(e) {
                eOrNil = e
            }
        }
        return eOrNil
    }
    
    public func lastOrDefault(defaultElement: T, predicate: T -> Bool) -> T {
        switch self.lastOrNil(predicate) {
        case .Some(let e): return e
        case .None: return defaultElement
        }
    }

    public func lastOrNil() -> T? {
        var eOrNil: T? = nil
        var g = self.generate()
        while let e = g.next() {
            eOrNil = e
        }
        return eOrNil
    }
    
    public func last() -> T {
        return self.lastOrNil()!
    }
    
    public func lastOrDefault(defaultElement: T) -> T {
        switch (self.lastOrNil()) {
        case .Some(let e): return e
        case .None: return defaultElement
        }
    }
    
    public func max<R: Comparable>(key: T -> R) -> R {
        var gen = self.generate()
        var ret = key(gen.next()!)
        while let elem = gen.next().map(key) {
            if elem > ret {
                ret = elem
            }
        }
        return ret
    }
    
    public func min<R: Comparable>(key: T -> R) -> R {
        var gen = self.generate()
        var ret = key(gen.next()!)
        while let elem = gen.next().map(key) {
            if elem < ret {
                ret = elem
            }
        }
        return ret
    }
    
    public func argmax<R: Comparable>(key: T -> R) -> T {
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
    
    public func argmin<R: Comparable>(key: T -> R) -> T {
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
    
    public func orderBy<K: Comparable>(key: T -> K) -> SinqOrderedSequence<T> {
        let comparator = { key($0) < key($1) }
        return SinqOrderedSequence(source: sequence, comparators: [ comparator ])
    }
    
    public func orderByDescending<K: Comparable>(key: T -> K) -> SinqOrderedSequence<T> {
        let comparator = { key($0) > key($1) }
        return SinqOrderedSequence(source: sequence, comparators: [ comparator ])
    }

    public func reverse() -> SinqSequence<T> {
        return SinqSequence { () -> IndexingGenerator<[T]> in
            self.toArray().reverse().generate()
        }
    }
    
    public func select<V>(selector: T -> V) -> SinqSequence<V> {
        return self.select({ (x, _) in selector(x) })
    }

    public func select<V>(selector: (T, Int) -> V) -> SinqSequence<V> {
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
    
    public final func map<V>(selector: T -> V) -> SinqSequence<V> {
        return select(selector)
    }
    
    public final func map<V>(selector: (T, Int) -> V) -> SinqSequence<V> {
        return select(selector)
    }

    public func selectMany<S: SequenceType, R>(selector: (T, Int) -> S, result: S.Generator.Element -> R) -> SinqSequence<R> {
        return SinqSequence<R> { () -> GeneratorOf<R> in
            typealias C = S.Generator.Element
            
            var gen1 = self.generate()
            var gen2: SequenceOf<C>.Generator = SinqSequence<C>([C]()).generate()
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
    
    public func selectMany<S: SequenceType, R>(selector: T -> S, result: S.Generator.Element -> R) -> SinqSequence<R> {
        return selectMany({ (x, _) in selector(x) }, result: result)
    }

    public func selectMany<S: SequenceType>(selector: (T, Int) -> S) -> SinqSequence<S.Generator.Element> {
        return selectMany(selector, result: { $0 })
    }
    
    public func selectMany<S: SequenceType>(selector: T -> S) -> SinqSequence<S.Generator.Element> {
        return selectMany({ (x, _) in selector(x) }, result: { $0 })
    }
    
    public func single() -> T {
        return self.singleOrNil()!
    }
    
    public func singleOrNil() -> T? {
        var gen = self.generate()
        switch (gen.next(), gen.next()) {
        case (.Some(let e), .None): return e
        case _: return nil
        }
    }
    
    public func singleOrDefault(defaultElement: T) -> T {
        switch self.singleOrNil() {
        case .Some(let e): return e
        case .None: return defaultElement
        }
    }
    
    public func single(predicate: T -> Bool) -> T {
        return whereTrue(predicate).single()
    }
    
    public func singleOrNil(predicate: T -> Bool) -> T? {
        return whereTrue(predicate).singleOrNil()
    }
    
    public func singleOrDefault(defaultElement: T, predicate: T -> Bool) -> T {
        return whereTrue(predicate).singleOrDefault(defaultElement)
    }
    
    public func skip(count: Int) -> SinqSequence<T> {
        return SinqSequence { () -> GeneratorOf<T> in
            var gen = self.generate()
            for _ in 0..<count {
                gen.next()
            }
            return gen
        }
    }

    public func skipWhile(predicate: T -> Bool) -> SinqSequence<T> {
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
    
    public func take(count: Int) -> SinqSequence<T> {
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
    
    public func takeWhile(predicate: T -> Bool) -> SinqSequence<T> {
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
    
    
    public func thenBy<K: Comparable>(key: T -> K) -> SinqOrderedSequence<T> {
        return orderBy(key)
    }
    
    public func thenByDescending<K: Comparable>(key: T -> K) -> SinqOrderedSequence<T> {
        return orderByDescending(key)
    }

    public func toArray() -> [T] {
        return [T](self)
    }
    
    public func toDictionary
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
    
    public func toDictionary
        <K: Hashable, V>
        (key: T -> K, value: T -> V) -> Dictionary<K, V>
    {
        var dict = Dictionary<K, V>()
        for elem in self {
            dict[key(elem)] = value(elem)
        }
        return dict
    }

    public func toDictionary
        <K: Hashable>
        (key: T -> K) -> Dictionary<K, T>
    {
        var dict = Dictionary<K, T>()
        for elem in self {
            dict[key(elem)] = elem
        }
        return dict
    }

    public func toLookupDictionary
        <K: Hashable, V>
        (keyValue: T -> (K, V)) -> Dictionary<K, SinqSequence<V>>
    {
        return groupBy({ keyValue($0).0 }, element: { keyValue($0).1 }).toDictionary{ ($0.key, $0.values) }
    }

    public func toLookupDictionary
        <K: Hashable>
        (key: T -> K) -> Dictionary<K, SinqSequence<T>>
    {
        return groupBy(key).toDictionary{ ($0.key, $0.values) }
    }
    
    public func toLookupDictionary
        <K: Hashable, V>
        (key: T -> K, element: T -> V) -> Dictionary<K, SinqSequence<V>>
    {
        return groupBy(key, element: element).toDictionary{ ($0.key, $0.values) }
    }
    
    //TODO: sequence equal
 
    // O(N*(N+M)) :(
    public func union
        <S: SequenceType where S.Generator.Element == T>
        (sequence: S, equality: (T, T) -> Bool) -> SinqSequence<T>
    {
        return self.distinct(equality).concat(sinq(sequence).distinct(equality).except(self, equality: equality))
    }
    
    public func union
        <S: SequenceType, K: Hashable where S.Generator.Element == T>
        (sequence: S, key: T -> K) -> SinqSequence<T>
    {
        return self.distinct(key).concat(sinq(sequence).distinct(key).except(self, key: key))
    }

    public func zip<S: SequenceType, R>(sequence: S, result: (T, S.Generator.Element) -> R) -> SinqSequence<R> {
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
    
    public func whereTrue(predicate: T -> Bool) -> SinqSequence<T> {
        return SinqSequence { () -> GeneratorOf<T> in
            var gen = self.generate()
            return GeneratorOf {
                while let e = gen.next() {
                    if predicate(e) {
                        return e
                    }
                }
                return nil
            }
        }
    }
    
    public final func filter(predicate: T -> Bool) -> SinqSequence<T> {
        return whereTrue(predicate)
    }

}

public class SinqOrderedSequence<T> : SinqSequence<T>, SequenceType {
    
    public override func generate() -> GeneratorOf<T> {
        var array = sinq(sequence).toArray()
        sort(&array) {
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
        return GeneratorOf(array.generate())
    }

    public init<S: SequenceType where S.Generator.Element == T>(source: S, comparators: Array<(T, T) -> Bool>) {
        self.comparators = comparators
        super.init(source)
    }
    
    private let comparators : Array<(T, T) -> Bool>
    
    public override func orderBy<K: Comparable>(key: T -> K) -> SinqOrderedSequence<T> {
        let comparator = { key($0) < key($1) }
        return SinqOrderedSequence(source: sequence, comparators: [ comparator ])
    }
    
    public override func orderByDescending<K: Comparable>(key: T -> K) -> SinqOrderedSequence<T> {
        let comparator = { key($0) > key($1) }
        return SinqOrderedSequence(source: sequence, comparators: [ comparator ])
    }

    public override func thenBy<K: Comparable>(key: T -> K) -> SinqOrderedSequence<T> {
        var newComparators = comparators
        newComparators.append { key($0) < key($1) }
        return SinqOrderedSequence(source: sequence, comparators: newComparators)
    }
    
    public override func thenByDescending<K: Comparable>(key: T -> K) -> SinqOrderedSequence<T> {
        var newComparators = comparators
        newComparators.append { key($0) > key($1) }
        return SinqOrderedSequence(source: sequence, comparators: newComparators)
    }
    
    // override to filter before sorting...
    public override func whereTrue(predicate: T -> Bool) -> SinqSequence<T> {
        return SinqOrderedSequence(source: sinq(sequence).whereTrue(predicate), comparators: comparators)
    }
    
}

public func from <S: SequenceType> (sequence: S) -> SinqSequence<S.Generator.Element> {
    return SinqSequence(sequence)
}

public func sinq <S: SequenceType> (sequence: S) -> SinqSequence<S.Generator.Element> {
    return SinqSequence(sequence)
}

public struct Grouping<K, V> {
    public let key: K
    public let values: SinqSequence<V>
}

extension Grouping: SequenceType {
    typealias GeneratorType = SinqSequence<V>.Generator
    public func generate() -> GeneratorType { return values.generate() }
}
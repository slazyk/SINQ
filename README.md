# SINQ - Swift Integrated Query

Swift has generic Collections and Sequences as well as some universal free functions to work with them. What is missing is a fluent interface that would make working with them easy¹ - like list comprehensions in many languages or LINQ in .NET. The operations should: require **no typecasts**, be **easily chained**, work on **any sequences**, be **performed lazily** where possible.

## Overview

SINQ (or LINQ for Swift) is a Swift library for working with sequences / collections. It is, as name suggests, modelled after LINQ, but it is not necessarily intended to be a LINQ port. The library is still under development, just as Swift is. Any contributions, both in terms of suggestions/ideas or actual code are welcome.

SINQ is brought to you by Leszek Ślażyński (slazyk), you can follow me on [twitter](https://twitter.com/slazyk) and [github](https://github.com/slazyk). Be sure to check out [Observable-Swift](https://github.com/slazyk/Observable-Swift) my other library that implements value observing and events. 

## Examples

The main goal of SINQ is to provide a *fluent* interface for working with collections. The way it tries to accomplish that is with **chaining of methods**. Most of the operations are **performed lazily**, i.e. computations are deferred and done only for the part of the result you enumerate. Everything is typed - **no typecasts required**. Examples:

```swift
let nums1 = from([1, 4, 2, 3, 5]).whereTrue{ $0 > 2 }.orderBy{ $0 }.select{ 2 * $0 }
// or less (linq | sql)-esque 
let nums2 = sinq([1, 4, 2, 3, 5]).filter{ $0 > 2 }.orderBy{ $0 }.map{ 2 * $0 }

// path1 : String = ..., path2: String = ...
let commonComponents = sinq(path1.pathComponents)
    .zip(path2.pathComponents) { ($0, $1) }
    .takeWhile { $0 == $1 }
    .count()

let prefixLength = sinq(path1).zip(path2){ ($0, $1) }.takeWhile{ $0 == $1 }.count()

// available : String[] = ..., blacklist : String[] = ...
let next = sinq(available).except(blacklist){ $0 }.firstOrDefault("unknown")

// employees : Employee[] = ...

let headCnt = sinq(employees).groupBy{ $0.manager }.map{ ($0.key, $0.values.count()) }

let allTasks = from(employees).selectMany{ $0.tasks }.orderBy{ $0.priority }

let elite1 = sinq(employees).whereTrue{ $0.salary > 1337 }.orderBy{ $0.salary }
let elite2 = from(employees).orderBy{ $0.salary }.takeWhile{ $0.salary > 1337 }

// products : Product[] = ..., categories : Category[] = ...

let breadcrumbs = sinq(categories).join(inner: products,
                                     outerKey: { $0.id },
                                     innerKey: { $0.categoryId },
                                       result: { "\($0.name) / \($1.name)" })

```

Please note that the results are not cached, i.e. looping twice over result of `orderBy(...)` will perform two sorts. If you want to use results multiple times, you can get always array with `toArray()`.

It uses `SinqSequence<T>` wrapper struct in order to do that, **you can wrap any `Sequence`** by simply `sinq(seq)`, `from(seq)`, or `SinqSequence(seq)`. This wrapper is introduced because Swift does not allow for adding methods to protocols (like `Sequence`) and because extending existing `SequenceOf<T>` causes linker errors.

*While I do try to follow cocoa-like naming and spelling conventions, while also keeping the LINQ naming where reasonable, I refuse to call the struct `SINQSequence<T>` or `SSequence<T>`.*

## Installation

You can use either [CocoaPods](https://cocoapods.org/) or [Carthage](https://github.com/Carthage/Carthage) to install SINQ.

Otherwise, the easiest option to use SINQ in your project is to clone this repo and add SINQ.xcodeproj to your project/workspace and then add SINQ.framework to frameworks for your target.

After that you just `import SINQ`.

## List of methods

##### `aggregate` / `reduce` - combine all the elements of the sequence into a result
```swift
aggregate(combine: (T, T) -> T) -> T
aggregate<R>(initial: R, combine: (R, T) -> R) -> R
aggregate<C, R>(initial: C, combine: (C, T) -> C, result: C -> R) -> R
```
##### `all` - check if a predicate is true for all the elements
```swift
all(predicate: T -> Bool) -> Bool
```
##### `any` - check if not empty, or if a predicate is true for any object
```swift
any() -> Bool      
any(predicate: T -> Bool) -> Bool
```
##### `concat` - create a sequence concatenating two sequences
```swift
concat<S: Sequence>(other: S) -> SinqSequence<T>
```
##### `contains` - check if the sequence contains an element
```swift
contains(value: T, equality: (T, T) -> Bool) -> Bool
contains<K: Equatable>(value: T, key: T -> K) -> Bool
```
##### `count` - count the elements in the sequence
```swift
func count() -> Int
```  
##### `distinct` - create a sequence with unique elements, in order
```swift
distinct(equality: (T, T) -> Bool) -> SinqSequence<T>
distinct<K: Hashable>(key: T -> K) -> SinqSequence<T>
```
##### `each` - iterate over the sequence
```swift
each(function: T -> ()) -> ()  
```
##### `elementAt` - get element at given index from the sequence
```swift
elementAtOrNil(index: Int) -> T?  
elementAt(index: Int) -> T
elementAt(index: Int, orDefault: T) -> T
```
##### `except` - create sequence with unique elements, excluding given
```swift
except<S: Sequence>(sequence: S, equality: (T, T) -> Bool) -> SinqSequence<T> 
except<S: Sequence, K: Hashable>(sequence: S, key: T -> K) -> SinqSequence<T>  
```
##### `first` - get first element of the sequence [satisfying a predicate]
```swift
first() -> T
firstOrNil() -> T?
first(predicate: T -> Bool) -> T
firstOrDefault(defaultElement: T) -> T
firstOrNil(predicate: T -> Bool) -> T?
firstOrDefault(defaultElement: T, predicate: T -> Bool) -> T
```
##### `groupBy` - create a sequence grouping elements by given key
```swift
groupBy<K: Hashable>(key: T -> K) -> SinqSequence<Grouping<K, T>>
groupBy<K: Hashable, V>(key: T -> K, element: T -> V) -> SinqSequence<Grouping<K, V>>
groupBy<K: Hashable, V, R>(key: T -> K, element: T -> V, result: (K, SinqSequence<V>) -> R) -> SinqSequence<R>
```
##### `groupJoin` - create a sequence joining two sequences with grouping
```swift
groupJoin<S: Sequence, K: Hashable>
	(#inner: S, outerKey: T -> K, innerKey: S.E -> K)
	-> SinqSequence<Grouping<T, S.E>>
groupJoin<S: Sequence, K: Hashable, R>
	(#inner: S, outerKey: T -> K, innerKey: S.E -> K,
 	 result: (T, SinqSequence<S.E>) -> R) -> SinqSequence<R>
```
##### `intersect` - create a sequence with unique elements present in both sequences
```swift
intersect<S: Sequence>(sequence: S, equality: (T, T) -> Bool) -> SinqSequence<T>
intersect<S: Sequence, K: Hashable>(sequence: S, key: T -> K) -> SinqSequence<T>
```
##### `join` - create a sequence joining two sequences without grouping
```swift
join<S: Sequence, K: Hashable, R>
	(#inner: S, outerKey: T -> K, innerKey: S.E -> K,
     result: (T, S.E) -> R) -> SinqSequence<R>
join<S: Sequence, K: Hashable>
    (#inner: S, outerKey: T -> K, innerKey: S.E -> K)
    -> SinqSequence<(T, S.E)>
```
##### `last` - return last element in the sequence [satisfying a predicate] 
```swift
last() -> T
lastOrNil() -> T?
last(predicate: T -> Bool) -> T
lastOrNil(predicate: T -> Bool) -> T?
lastOrDefault(defaultElement: T) -> T
lastOrDefault(defaultElement: T, predicate: T -> Bool) -> T
```
##### `min` / `max` - return the minimum/maximum value of a function for the sequence    
```swift
min<R: Comparable>(key: T -> R) -> R
max<R: Comparable>(key: T -> R) -> R
```
##### `argmin` / `argmax` - return the element for which the function has the minimum/maximum value
```swift
argmin<R: Comparable>(key: T -> R) -> T
argmax<R: Comparable>(key: T -> R) -> T
```
##### `orderBy` / `orderByDescending` - create a sequence sorted by given key 
```swift
orderBy<K: Comparable>(key: T -> K) -> SinqOrderedSequence<T>
orderByDescending<K: Comparable>(key: T -> K) -> SinqOrderedSequence<T>
```
##### `reverse` - create a sequence with reverse order
```swift
reverse() -> SinqSequence<T>
```    
##### `select` / `map` - create a sequence with results of applying given function
```swift
select<V>(selector: T -> V) -> SinqSequence<V>
select<V>(selector: (T, Int) -> V) -> SinqSequence<V>
```
##### `selectMany` - create a sequence by concatenating function results for each element
```swift
selectMany<S: Sequence>(selector: T -> S) -> SinqSequence<S.E>
selectMany<S: Sequence>(selector: (T, Int) -> S) -> SinqSequence<S.E>
selectMany<S: Sequence, R>(selector: T -> S, result: S.E -> R) -> SinqSequence<R>
selectMany<S: Sequence, R>(selector: (T, Int) -> S, result: S.E -> R) -> SinqSequence<R>
```
##### `single` - return the only element in a sequence containing exactly one element
```swift
single() -> T
singleOrNil() -> T?
singleOrDefault(defaultElement: T) -> T
single(predicate: T -> Bool) -> T
singleOrNil(predicate: T -> Bool) -> T?
singleOrDefault(defaultElement: T, predicate: T -> Bool) -> T
```

##### `skip` - create a sequence skipping (given number of elements | while predicate holds )
```swift
skip(count: Int) -> SinqSequence<T>
skipWhile(predicate: T -> Bool) -> SinqSequence<T>
```
##### `take` - create a sequence by taking (given number of elements | while predicate holds )
```swift
take(count: Int) -> SinqSequence<T>
takeWhile(predicate: T -> Bool) -> SinqSequence<T>
```
##### `thenBy` / `thenByDescending` - create a sequence by additionally sorting on given key
```swift
thenBy<K: Comparable>(key: T -> K) -> SinqOrderedSequence<T>
thenByDescending<K: Comparable>(key: T -> K) -> SinqOrderedSequence<T>
```
##### `toArray` - create an array from the sequence
```swift
toArray() -> T[]
```
##### `toDictionary` / `toLookupDictionary` - create a dictionary from the sequence
```swift
toDictionary<K: Hashable, V>(keyValue: T -> (K, V)) -> Dictionary<K, V>
toDictionary<K: Hashable, V>(key: T -> K, value: T -> V) -> Dictionary<K, V>
toDictionary<K: Hashable>(key: T -> K) -> Dictionary<K, T>
```
##### `union` - create a sequence with unique elements from either of the sequences
```swift
union<S: Sequence>(sequence: S, equality: (T, T) -> Bool) -> SinqSequence<T>
union<S: Sequence, K: Hashable>(sequence: S, key: T -> K) -> SinqSequence<T>
```
##### `whereTrue` / `filter` - create a sequence only with elements satisfying a predicate
```swift
whereTrue(predicate: T -> Bool) -> SinqSequence<T>
```
##### `zip` - create a sequence by combining pairs of elements from two sequences
```swift
zip<S: Sequence, R>(sequence: S, result: (T, S.E) -> R) -> SinqSequence<R>
```

## Troubleshooting

Due to bug in `swift` it *sometimes* happens that `swift` compiler and/or `SourceKitService` loop indefinitely while solving type constraints during compilation or indexing. If this happens, to help them solve the constraints, one might have to divide work for them into smaller pieces. For example this would cause inifinite loop:
```swift
func testAll() {
  XCTAssertTrue(sinq([11, 12, 15, 10]).all{ $0 >= 10 })
  XCTAssertFalse(sinq([11, 12, 15, 10]).all{ $0 > 10 })
}
```
While this does not:
```swift
func testAll() {
  let seq = sinq([11, 12, 15, 10])
  XCTAssertTrue(seq.all{ $0 >= 10 })
  XCTAssertFalse(seq.all{ $0 < 13 })
}
```
In this case it seems o be connected to `@auto_closure` arguments of `XCTAssert*`...

In case it happens for you, try to divide the statements like this or be more explicit in code about types and not depend as much on type inference.

---
¹ - this statement might become less true in the future, e.g. in Beta 4 Apple introduced `lazy()` which is similar to subset of `sinq()` in that it adds lazy chainable `.map` `.filter` `.reverse` `.array` and subscripting.

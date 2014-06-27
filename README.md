# SINQ - Swift Integrated Native Query

Swift has generic Collections and Sequences as well as some universal free functions to work with them. What is missing is a fluent interface for chaining subsequent operations that would make working with them easy - like LINQ for .NET. 

## Overview

SINQ (or LINQ for Swift) is a Swift library for working with sequences / collections. It is, as name suggests, modelled after LINQ, but it is not necessarily intended to be a LINQ port. The library is still under development, just as Swift is. Any contributions, both in terms of suggestions/ideas or actual code are welcome.

The main goal of SINQ is to provide a fluent interface for working with collections. The way it tries to accomplish that is with chaining of methods. Examples:

```swift
from([1, 4, 2, 3, 5]).whereTrue{ $0 > 2 }.orderBy{ $0 }.select{ 2 * $0 }

let employees : Employee[] = ...

from(employees).groupBy{ $0.manager }.select{ ($0.key, $0.values.count()) }

from(employees).selectMany{ $0.tasks }.orderBy{ $0.priority }

sinq(employees).whereTrue{ $0.salary > 1337 }.orderBy{ $0.salary }
from(employees).orderBy{ $0.salary }.takeWhile{ $0.salary > 1337 }

let products : Product[] = ...
let categories : Category[] = ...

sinq(categories).join(inner: products,
					  outerKey: { $0.id },
					  innerKey: { $0.categoryId },
					  result: { "\($0.name) / \($1.name)" })

```

Most of the operations themselves are performed *lazily*, i.e. not performed unless you actually enumerate the result. Please note that the results are not cached, i.e. looping twice over result of `orderBy(...)` will perform two sorts. If you want to use results multiple times, you can get always array with `toArray()`.

It uses `SinqSequence<T>` wrapper struct in order to do that, you can wrap any `Sequence` by simply `sinq(seq)`, `from(seq)`, or `SinqSequence(seq)`. This wrapper is introduced because Swift does not allow for adding methods to protocols (like `Sequence`) and because extending existing `SequenceOf<T>` causes linker errors.

*While I do try to follow cocoa-like naming and spelling conventions, while also keeping the LINQ naming where reasonable, i refuse to call the struct `SINQSequence<T>` or `SSequence<T>`.*

## Installation

As of writing, Xcode 6 beta 2 does not support Swift static libraries, and CocoaPods 0.33.1 does not support Frameworks...

Easiest option to use SINQ in your project is to clone this repo and add SINQ.xcodeproj to your project/workspace and then add SINQ.framework to frameworks for your target.

After that you just `import SINQ`.

## Troubleshooting

While the library compiles just fine and each one of the samples/tests  from `SINQTests.swift` runs fine, it seems that parsing / compiling all of them at once is sometimes too much for SourceKitService / swift compiler. If Xcode starts using 100% of your CPU for a long time, it might help to comment all of the samples/tests, kill/restart Xcode/SourceKitService/swift and uncomment selectively. And/or be more explicit in code about types and not depend on type inference.

## List of methods

| Method | Example | Variants / Aliases |
|--------|---------|--------------------|
| `all` | `if seq. all{ $0 > 0 }` | `all(_ predicate:)` |
| `any` | `if seq. any{ $0 > 0 }` | `any()` `any(_ predicate:)` |
| `concat` | `let seq3 = seq1.concat(seq2)` | `concat(_ sequence:)` |
| `contains` | `if seq1.contains(x, equality: { $0 == $1 })` | `contains(_ value: equality:)` |
| `count` | `let num = seq.count()` | `count()` |
| `distinct` | `let seq2 = seq.distinct{ $0 == $1 }` | `distinct(_ equality:)` |
| `except` | `let seq3 = seq1.except(seq2, equality: { $0 == $1 })` | `except(_ sequence: equality:)` |
| `first` `last` | `let e = seq.firstOrNil{ $0 > 10 }` | `first(_ predicate?:)` `firstOrNil(_ predicate?:)` `firstOrDefault(_: predicate?:)` `last...` |
| `groupBy` | `seq.groupBy{ $0.key }.select{ ... }` |  `groupBy(_ key: element?: result?:)` |
| `groupJoin` | `seq1.groupJoin(inner: seq2, outerKey: { $0.id }, innerKey: { $0.refId })`  | `groupJoin(inner: outerKey: innerKey: result?:)` |
| `iterate` `reduce` | `seq.iterate(0) { $0 + $1 }` | `iterate(_ initial: combine:)` `reduce(_ initial: combine:)` |
| `orderBy` `orderByDescending` | `seq.orderBy{ $0.value }` | `orderBy(_ key:)` `orderByDescending(_ key:)` |
| `reverse` | `seq.reverse()` | `reverse()` |
| `select` `map` | `from(x).select{ $0.value }` | `select(_: T -> V)` `select(_: (T, Int) -> V)`, `map...` |
| `selectMany` | `from(x).select{ $0.values }` | `selectMany(_: T -> Vs, result?:)` `selectMany(_: (T, Int) -> Vs, result?:)` |
| `skip` `take` | `seq.skipWhile{ $0 < 10 }` | `skip(_ count:)` `skipWhile(_ predicate:)` `take...` |
| `toArray` | `let a = seq.toArray()` | `toArray()` | `toDictionary` | `let d = seq.toDictionary{ $0.key }` | `toDictionary(_ key: value?:)` `toDictionary(_ keyValue:)` |
| `union` | `let all = seq1.union(seq2, equality: {$0 == $1 })` | `union(_ sequence: equality:)` |
| `whereTrue` `filter` | `let seq2 = seq.whereTrue{ $0 > 10 }` | `whereTrue(_ predicate:)` `filter(_ predicate:)` |

## Author

SINQ is brought to you by Leszek Ślażyński (slazyk), you can follow me on [twitter](https://twitter.com/slazyk) and [github](https://github.com/slazyk). 



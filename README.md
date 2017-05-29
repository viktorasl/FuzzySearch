# FuzzySearch

[![Build Status](https://travis-ci.org/viktorasl/FuzzySearch.svg)](https://travis-ci.org/viktorasl/FuzzySearch)
[![Swift Package Manager Compatible](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-4BC51D.svg?style=flat)](https://github.com/apple/swift-package-manager)
[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/SwiftHEXColors.svg)](https://img.shields.io/cocoapods/v/FuzzySearch.svg)
[![Platform](https://img.shields.io/cocoapods/p/SwiftHEXColors.svg?style=flat)](http://cocoadocs.org/docsets/FuzzySearch)
[![License](https://img.shields.io/cocoapods/l/SwiftHEXColors.svg)](https://raw.githubusercontent.com/viktorasl/FuzzySearch/master/LICENSE)

Lightweight Fuzzy evaluation protocol with CollectionType extension

## Requirements

iOS 8.0+
Swift 3.0

## Usage

### Implementing FuzzySearchable protocol

```swift
struct PlayerModel {
  let name: String
  let position: String
  let goals: Int
}
```

Implementation of `FuzzySearchable` protocol defines against what search patterns will be evaluated.
```swift
extension PlayerModel: FuzzySearchable {
  var fuzzyStringToMatch: String {
    return name
  }
}
```

### Evaluating single `FuzzySearchable` instance

```swift
let maradona = PlayerModel(name: "Diego Maradona", position: "F", goals: 16)
maradona.fuzzyMatch("diema") // FuzzySearchResult(weight: 15, parts: [(0,3), (6,2)])
```

#### `FuzzySearchResult`

Result of evaluation carries two properties:
- `weight` - weight of the match
- `parts` - `NSRange`'s of pattern matching against `fuzzyStringToMatch`

### Evaluating collection of `FuzzySearchable`s

When evaluating collection of `FuzzySearchable`s result is an array of tuples `(item: Generator.Element, result: FuzzySearchResult)` which is filtered and sorted depending on `weight`.

```swift

let players = [
  PlayerModel(name: "Diego Maradona", position: "CF", goals: 16),
  PlayerModel(name: "David Beckham", position: "CAM", goals: 8),
  PlayerModel(name: "Lionel Messi", position: "RW", goals: 15)
]
players.fuzzyMatch("di")
//[
// (
//  FuzzySearchTests.PlayerModel(name: "Diego Maradona", position: "CF", goals: 16),
//  FuzzySearch.FuzzySearchResult(weight: 4, parts: [(0,2)])
// ), (
//  FuzzySearchTests.PlayerModel(name: "David Beckham", position: "CAM", goals: 8),
//  FuzzySearch.FuzzySearchResult(weight: 2, parts: [(0,1), (3,1)])
// )
//]
```

#### `CachedFuzzySearchable<T: FuzzySearchable>`

Wraps over a `FuzzySearchable` instance, caching some underlying metadata generated while fuzzy-matching w/ `FuzzySearchable.fuzzyMatch`.

Use this cached wrapper over `FuzzySearchable` instances that are expected to be fuzzy-matched multiple times without mutation to `fuzzyStringToMatch`:

```swift
let players = [
  PlayerModel(name: "Diego Maradona", position: "CF", goals: 16),
  PlayerModel(name: "David Beckham", position: "CAM", goals: 8),
  PlayerModel(name: "Lionel Messi", position: "RW", goals: 15),
  // Many more players ...
]

let fuzzyCachedPlayers =
  players.map { player in 
    CachedFuzzySearchable(wrapping: player) 
  }

fuzzyCachedPlayers.fuzzyMatch("di")

// Subsequente calls to 'fuzzyMatch' over the array above cause less overhead when re-matching
fuzzyCachedPlayers.fuzzyMatch("di") // Runs in about half time

players.fuzzyMatch("di") // Will fuzzy-match against original, non-cached PlayerModel values.
```

`CachedFuzzySearchable` has storage needs of a little over 2x that of the `fuzzyStringToSearch` property of the wrapped `FuzzySearchable` value. Discarding a `CachedFuzzySearchable` value also discards the extra memory that was allocated.

Returning a different value from the wrapped `FuzzySearchable`'s `fuzzyStringToSearch` property resets the cache automatically during the next `fuzzyMatch` call and the overhead is reset to that of a fresh `CachedFuzzySearchable` instance, so implementers shouldn't worry about mantaining a stable `fuzzyStringToSearch` result.

## License

FuzzySearch is released under the [MIT](LICENSE) license.

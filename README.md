# SwiftRison

SwiftRison is a Swift encoder/decoder for the [Rison](https://github.com/Nanonid/rison) object encoding format. 

## Contents

- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
- [Credits](#credits)
- [License](#license)

## Requirements

- Xcode 14.1+
- Swift 5.7+

## Installation

Integrate SwiftRison into your Xcode project using the URL, `https://github.com/Geotab/mobile-swift-rison`. Or add it to the dependencies value of your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/Geotab/mobile-swift-rison", .upToNextMajor(from: "1.0.0"))
]
```
---

## Usage

### Decoding

```swift
import SwiftRison

struct Person: Codable {
    let name: String
    let email: String
}

let decoder = RisonDecoder(risonString: "(name:mock,email:test%40email.com)")

let person = try Person(from: decoder)

print(person)

> Person(name: "mock", email: "test%40email.com")
```

### Encoding

````swift
import SwiftRison

struct Person: Codable {
    let name: String
    let email: String
}

let person = Person(name: "mock", email: "test%40email.com")

let encoder = RisonEncoder()

try person.encode(to: encoder)

print(encoder.risonString)

> (name:mock,email:test%40email.com)

````

### O-Rison and A-Rison

````swift
struct Mock: Codable {
    var array: [Int]
    var email: String
}
let risonString = "array:!(1,2,3),email:mock%40email.com"
let decoder = RisonDecoder(mode: .oRison, risonString: risonString)
let obj = try Mock(from: decoder)
print(obj)

> Mock(array: [1, 2, 3], email: "mock%40email.com")

let value = Mock(array: [1,2,3], email: "mock@mock.com")
let encoder = RisonEncoder(mode: .oRison)
try value.encode(to: encoder)
print(encoder.risonString())

> email:mock@mock.com,array:!(1,2,3)
````

````swift
struct Mock: Codable {
    var name: String
}
let risonString = "(name:one),(name:two),(name:three)"
let decoder = RisonDecoder(mode: .aRison, risonString: risonString)
let array = try [Mock](from: decoder)
print(array)

> [Mock(name: "one"), Mock(name: "two"), Mock(name: "three")]

let encoder = RisonEncoder(mode: .aRison)
try [Mock(name:"one"), Mock(name: "two"), Mock(name: "three")].encode(to: encoder)
print(encoder.risonString())

> (name:one),(name:two),(name:three)
````

## License

SwiftRison is available under the MIT license. See the LICENSE file for more info.

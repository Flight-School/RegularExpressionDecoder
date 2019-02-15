# Regular Expression Decoder

A decoder that constructs objects from regular expression matches.

This is experimental, and not intended for production use.

---

For more information about creating your own custom decoders,
consult Chapter 7 of the
[Flight School Guide to Swift Codable](https://flight.school/books/codable).
For more information about using regular expressions in Swift,
check out Chapter 6 of the
[Flight School Guide to Swift Strings](https://flight.school/books/strings).

## Requirements

- Swift 5+
- iOS 11+ or macOS 10.13+

## Usage

```swift
import RegularExpressionDecoder

struct Stock: Decodable {
    let symbol: String
    var price: Double

    enum Sign: String, Decodable {
        case gain = "🞁"
        case unchanged = "="
        case loss = "🞃"
    }

    private var sign: Sign
    private var change: Double = 0.0
    var movement: Double {
        switch sign {
        case .gain: return +change
        case .unchanged: return 0.0
        case .loss: return -change
        }
    }
}

let pattern = #"""
(?x)
\b
(?<symbol>[A-Z]{1,4}) \s+
(?<price>\d{1,}\.\d{2}) \s*
(?<sign>([🞁🞃](?!0\.00))|(=(?=0\.00)))
(?<change>\d{1,}\.\d{2})
\b
"""#

let ticker = """
AAPL 170.69🞁0.51
GOOG 1122.57🞁2.41
AMZN 1621.48🞃18.52
MSFT 106.57🞃0.24
SWIFT 5.0.0🞁1.0.0 // Invalid
"""

let decoder = try RegularExpressionDecoder(pattern: pattern)
try decoder.decode([Stock].self, from: ticker)
// Decodes [AAPL, GOOG, AMZN, MSFT]
```

## License

MIT

## Contact

Mattt ([@mattt](https://twitter.com/mattt))

# Regular Expression Decoder

[![Build Status][build status badge]][build status]
[![License][license badge]][license]
[![Swift Version][swift version badge]][swift version]

A decoder that constructs objects from regular expression matches.

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

let ticker = """
AAPL 170.69▲0.51
GOOG 1122.57▲2.41
AMZN 1621.48▼18.52
MSFT 106.57=0.00
SWIFT 5.0.0▲1.0.0
"""

let pattern: RegularExpressionPattern<Stock, Stock.CodingKeys> = #"""
\b
(?<\#(.symbol)>[A-Z]{1,4}) \s+
(?<\#(.price)>\d{1,}\.\d{2}) \s*
(?<\#(.sign)>([▲▼=])
(?<\#(.change)>\d{1,}\.\d{2})
\b
"""#

let decoder = try RegularExpressionDecoder<Stock>(
                    pattern: pattern,
                    options: .allowCommentsAndWhitespace
                  )

try decoder.decode([Stock].self, from: ticker)
// Decodes [AAPL, GOOG, AMZN, MSFT] (but not SWIFT, which is invalid)
```

## Explanation

Let's say that you're building an app that parses stock quotes
from a text-based stream of price changes.

```swift
let ticker = """
AAPL 170.69▲0.51
GOOG 1122.57▲2.41
AMZN 1621.48▼18.52
MSFT 106.57=0.00
"""
```

Each stock is represented by the following structure:

- The **symbol**, consisting of 1 to 4 uppercase letters, followed by a space
- The **price**, formatted as a number with 2 decimal places
- A **sign**, indicating a price gain (`▲`), loss (`▼`), or no change (`=`)
- The **magnitude** of the gain or loss, formatted the same as the price

These format constraints lend themselves naturally
to representation by a <dfn>regular expression</dfn>,
such as:

```perl
/\b[A-Z]{1,4} \d{1,}\.\d{2}[▲▼=]\d{1,}\.\d{2}\b/
```

> Note:
> The `\b` metacharacter anchors matches to word boundaries.

This regular expression can distinguish between
valid and invalid stock quotes.

```swift
"AAPL 170.69▲0.51" // valid
"SWIFT 5.0.0▲1.0.0" // invalid
```

However, to extract individual components from a quote
(symbol, price, etc.)
the regular expression must contain <dfn>capture groups</dfn>,
of which there are two varieties:
<dfn>positional capture groups</dfn> and
<dfn>named capture groups</dfn>.

Positional capture groups are demarcated in the pattern
by enclosing parentheses (`(___)`).
With some slight modifications,
we can make original regular expression capture each part of the stock quote:

```perl
/\b([A-Z]{1,4}) (\d{1,}\.\d{2})([▲▼=])(\d{1,}\.\d{2})\b/
```

When matched,
the symbol can be accessed by the first capture group,
the price by the second,
and so on.

For large numbers of capture groups ---
especially in patterns with nested groups ---
one can easily lose track of which parts correspond to which positions.
So another approach is to assign names to capture groups,
which are denoted by the syntax `(?<NAME>___)`.

```perl
/\b
(?<symbol>[A-Z]{1,4}) \s+
(?<price>\d{1,}\.\d{2}) \s*
(?<sign>([▲▼=])
(?<change>\d{1,}\.\d{2})
\b/
```

> Note:
> Most regular expression engines ---
> including the one used by `NSRegularExpression` ---
> provide a mode to ignore whitespace;
> this lets you segment long patterns over multiple lines,
> making them easier to read and understand.

Theoretically, this approach allows you to access each group by name
for each match of the regular expression.
In practice, doing this in Swift can be inconvenient,
as it requires you to interact with cumbersome `NSRegularExpression` APIs
and somehow incorporate it into your model layer.

`RegularExpressionDecoder` provides a convenient solution
to constructing `Decodable` objects from regular expression matches
by automatically matching coding keys to capture group names.
And it can do so safely,
thanks to the new `ExpressibleByStringInterpolation` protocol in Swift 5.

To understand how,
let's start by considering the following `Stock` model,
which adopts the `Decodable` protocol:

```swift
struct Stock: Decodable {
    let symbol: String
    var price: Double

    enum Sign: String, Decodable {
        case gain = "▲"
        case unchanged = "="
        case loss = "▼"
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
```

So far, so good.

Now, normally, the Swift compiler
automatically synthesizes conformance to `Decodable`,
including a nested `CodingKeys` type.
But in order to make this next part work correctly,
we'll have to do this ourselves:

```swift
extension Stock {
    enum CodingKeys: String, CodingKey {
        case symbol
        case price
        case sign
        case change
    }
}
```

Here's where things get really interesting:
remember our regular expression with named capture patterns from before?
_We can replace the hard-coded names
with interpolations of the `Stock` type's coding keys._

```swift
import RegularExpressionDecoder

let pattern: RegularExpressionPattern<Stock, Stock.CodingKeys> = #"""
\b
(?<\#(.symbol)>[A-Z]{1,4}) \s+
(?<\#(.price)>\d{1,}\.\d{2}) \s*
(?<\#(.sign)>[▲▼=])
(?<\#(.change)>\d{1,}\.\d{2})
\b
"""#
```

> Note:
> This example benefits greatly from another new feature in Swift 5:
> <dfn>raw string literals</dfn>.
> Those octothorps (`#`) at the start and end
> tell the compiler to ignore escape characters (`\`)
> unless they also include an octothorp (`\#( )`).
> Using raw string literals,
> we can write regular expression metacharacters like `\b`, `\d`, and `\s`
> without double escaping them (i.e. `\\b`).

Thanks to `ExpressibleByStringInterpolation`,
we can restrict interpolation segments to only accept those coding keys,
thereby ensuring a direct 1:1 match between capture groups
and their decoded properties.
And not only that ---
this approach lets us to verify that keys have valid regex-friendly names
and aren't captured more than once.
It's enormously powerful,
allowing code to be incredibly expressive
without compromising safety or performance.

When all is said and done,
`RegularExpressionDecoder` lets you decode types
from a string according to a regular expression pattern
much the same as you might from JSON or a property list
using a decoder:

```swift
let decoder = try RegularExpressionDecoder<Stock>(
                        pattern: pattern,
                        options: .allowCommentsAndWhitespace
                  )

try decoder.decode([Stock].self, from: ticker)
// Decodes [AAPL, GOOG, AMZN, MSFT]
```

## License

MIT

## Contact

Mattt ([@mattt](https://twitter.com/mattt))

[build status]: https://travis-ci.com/Flight-School/RegularExpressionDecoder
[build status badge]: https://api.travis-ci.com/Flight-School/RegularExpressionDecoder.svg?branch=master
[license]: http://img.shields.io/badge/license-MIT-blue.svg?style=flat
[license badge]: http://img.shields.io/badge/license-MIT-blue.svg?style=flat
[swift version]: https://swift.org/download/
[swift version badge]: http://img.shields.io/badge/swift%20version-5.0-orange.svg?style=flat

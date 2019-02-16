import RegularExpressionDecoder

let ticker = """
AAPL 170.69▲0.51
GOOG 1122.57▲2.41
AMZN 1621.48▼18.52
MSFT 106.57▼0.24
SWIFT 5.0.0▲1.0.0
"""

let pattern: RegularExpressionPattern<Stock, Stock.CodingKeys> = #"""
\b
(?<\#(.symbol)>[A-Z]{1,4}) \s+
(?<\#(.price)>\d{1,}\.\d{2}) \s*
(?<\#(.sign)>([▲▼](?!0\.00))|(=(?=0\.00)))
(?<\#(.change)>\d{1,}\.\d{2})
\b
"""#

let decoder = try RegularExpressionDecoder<Stock>(pattern: pattern, options: .allowCommentsAndWhitespace)

try decoder.decode([Stock].self, from: ticker)

import XCTest
import Foundation
@testable import RegularExpressionDecoder

@available(OSX 10.13, iOS 11, tvOS 11, watchOS 4, *)
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

    enum CodingKeys: String, CodingKey {
        case symbol
        case price
        case sign
        case change
    }
}

// swiftlint:disable force_try
@available(OSX 10.13, iOS 11, tvOS 11, watchOS 4, *)
class RegularExpressionDecodingTests: XCTestCase {
    var decoder: RegularExpressionDecoder<Stock>!

    override func setUp() {
        let pattern: RegularExpressionPattern<Stock, Stock.CodingKeys> = #"""
        \b
        (?<\#(.symbol)>[A-Z]{1,4}) \s+
        (?<\#(.price)>\d{1,}\.\d{2}) \s*
        (?<\#(.sign)>([▲▼](?!0\.00))|(=(?=0\.00)))
        (?<\#(.change)>\d{1,}\.\d{2})
        \b
        """#

        self.decoder = try! RegularExpressionDecoder<Stock>(pattern: pattern, options: .allowCommentsAndWhitespace)
    }

    func testDecodeSingle() {
        let string = "AAPL 170.69▲0.51"
        let stock = try! self.decoder.decode(Stock.self, from: string)

        XCTAssertEqual(stock.symbol, "AAPL")
        XCTAssertEqual(stock.price, 170.69, accuracy: 0.01)
        XCTAssertEqual(stock.movement, 0.51, accuracy: 0.01)
    }

    func testDecodeMultiple() {
        let string = """
        AAPL 170.69▲0.51
        GOOG 1122.57▲2.41
        AMZN 1621.48▼18.52
        MSFT 106.57=0.00
        SWIFT 5.0▲1.0.0
        """

        let stocks = try! self.decoder.decode([Stock].self, from: string)

        guard stocks.count == 4 else {
            XCTFail("decoded \(stocks.count) of 4 valid stocks")
            return
        }

        let AAPL = stocks[0]
        XCTAssertEqual(AAPL.symbol, "AAPL")
        XCTAssertEqual(AAPL.price, 170.69, accuracy: 0.01)
        XCTAssertEqual(AAPL.movement, 0.51, accuracy: 0.01)

        let GOOG = stocks[1]
        XCTAssertEqual(GOOG.symbol, "GOOG")
        XCTAssertEqual(GOOG.price, 1122.57, accuracy: 0.01)
        XCTAssertEqual(GOOG.movement, 2.41, accuracy: 0.01)

        let AMZN = stocks[2]
        XCTAssertEqual(AMZN.symbol, "AMZN")
        XCTAssertEqual(AMZN.price, 1621.48, accuracy: 0.01)
        XCTAssertEqual(AMZN.movement, -18.52, accuracy: 0.01)

        let MSFT = stocks[3]
        XCTAssertEqual(MSFT.symbol, "MSFT")
        XCTAssertEqual(MSFT.price, 106.57, accuracy: 0.01)
        XCTAssertEqual(MSFT.movement, 0.0, accuracy: 0.01)
    }

    func testDecodeInvalid() {
        let string = "AAPL 170.69" // missing sign and change

        XCTAssertThrowsError(try self.decoder.decode(Stock.self, from: string))
    }

    static var allTests = [
        (testDecodeSingle, "testDecodeSingle"),
        (testDecodeMultiple, "testDecodeMultiple"),
        (testDecodeInvalid, "testDecodeInvalid")
    ]
}

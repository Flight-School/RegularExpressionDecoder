public struct Stock: Decodable {
    public let symbol: String
    public var price: Double
    
    enum Sign: String, Decodable {
        case gain = "▲"
        case unchanged = "="
        case loss = "▼"
    }
    
    private var sign: Sign
    private var change: Double = 0.0
    public var movement: Double {
        switch sign {
        case .gain: return +change
        case .unchanged: return 0.0
        case .loss: return -change
        }
    }

    public enum CodingKeys: String, CodingKey {
        case symbol
        case price
        case sign
        case change
    }
}

extension Stock.Sign: CustomStringConvertible {
    var description: String {
        return self.rawValue
    }
}

extension Stock: CustomStringConvertible {
    public var description: String {
        return "\(self.symbol) \(self.price)\(self.sign)\(self.change)"
    }
}

public struct Stock: Decodable {
    static let pattern = #"""
    (?x)
    \b
    (?<symbol>[A-Z]{1,4}) \s+
    (?<price>\d{1,}\.\d{2}) \s*
    (?<sign>([🞁🞃](?!0\.00))|(=(?=0\.00)))
    (?<change>\d{1,}\.\d{2})
    \b
    """#
    
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

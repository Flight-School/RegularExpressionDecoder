public struct RegularExpressionPattern<T, CodingKeys>: LosslessStringConvertible, ExpressibleByStringInterpolation where T: Decodable, CodingKeys: CodingKey & Hashable {
    public var description: String
    public var captures: Set<CodingKeys>?
    
    public init?(_ description: String) {
        self.description = description
    }
    
    public init(stringLiteral value: String) {
        self.init(value)!
    }
    
    public init(stringInterpolation: StringInterpolation) {
        self.init(stringInterpolation.string)!
        self.captures = stringInterpolation.captures
    }
    
    public struct StringInterpolation: StringInterpolationProtocol {
        var string: String = ""
        var captures: Set<CodingKeys> = []
        
        public init(literalCapacity: Int, interpolationCount: Int) {
            self.string.reserveCapacity(literalCapacity)
        }
        
        public mutating func appendLiteral(_ literal: String) {
            self.string.append(literal)
        }
        
        public mutating func appendInterpolation(_ key: CodingKeys) {
            precondition(!self.captures.contains(key), "\(key) already captured")
            precondition(!key.stringValue.contains { !$0.isLetter }, "invalid capture name \(key.stringValue)")
            self.string.append(key.stringValue)
            self.captures.insert(key)
        }
    }
}

import Foundation

@available(OSX 10.13, iOS 11, tvOS 11, watchOS 4, *)
extension _RegularExpressionDecoder {
    final class UnkeyedContainer {
        let string: String
        let matches: [NSTextCheckingResult]
        var codingPath: [CodingKey]
        var userInfo: [CodingUserInfoKey: Any]

        var currentIndex: Int = 0

        init(string: String, matches: [NSTextCheckingResult], codingPath: [CodingKey], userInfo: [CodingUserInfoKey : Any]) {
            self.string = string
            self.matches = matches
            self.codingPath = codingPath
            self.userInfo = userInfo
        }
    }
}

@available(OSX 10.13, iOS 11, tvOS 11, watchOS 4, *)
extension _RegularExpressionDecoder.UnkeyedContainer: UnkeyedDecodingContainer {
    var count: Int? {
        return self.matches.count
    }

    var isAtEnd: Bool {
        return self.currentIndex >= self.count ?? 0
    }

    func decodeNil() throws -> Bool {
        return !isAtEnd
    }

    func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        guard !isAtEnd else {
            throw DecodingError.dataCorruptedError(in: self, debugDescription: "no more matches")
        }

        defer { self.currentIndex += 1 }

        let decoder = _RegularExpressionDecoder(string: self.string, matches: [self.matches[self.currentIndex]])

        return try T(from: decoder)
    }

    func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        defer { self.currentIndex += 1 }

        return _RegularExpressionDecoder.UnkeyedContainer(string: self.string, matches: [self.matches[self.currentIndex]], codingPath: self.codingPath, userInfo: self.userInfo)
    }

    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        defer { self.currentIndex += 1 }

        let container = _RegularExpressionDecoder.KeyedContainer<NestedKey>(string: self.string, match: self.matches[self.currentIndex], codingPath: self.codingPath, userInfo: self.userInfo)
        return KeyedDecodingContainer(container)
    }

    func superDecoder() throws -> Decoder {
        fatalError("Unimplemented")
    }
}

@available(OSX 10.13, iOS 11, tvOS 11, watchOS 4, *)
extension _RegularExpressionDecoder.UnkeyedContainer: RegularExpressionDecodingContainer {}

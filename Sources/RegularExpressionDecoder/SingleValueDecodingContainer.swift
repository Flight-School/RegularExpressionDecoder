import Foundation

@available(OSX 10.13, iOS 11, tvOS 11, watchOS 4, *)
extension _RegularExpressionDecoder {
    final class SingleValueContainer {
        let string: String
        let match: NSTextCheckingResult?
        var codingPath: [CodingKey]
        var userInfo: [CodingUserInfoKey: Any]

        init(string: String, match: NSTextCheckingResult?, codingPath: [CodingKey], userInfo: [CodingUserInfoKey : Any]) {
            self.string = string
            self.match = match
            self.codingPath = codingPath
            self.userInfo = userInfo
        }
    }
}

@available(OSX 10.13, iOS 11, tvOS 11, watchOS 4, *)
extension _RegularExpressionDecoder.SingleValueContainer: SingleValueDecodingContainer {
    func decodeNil() -> Bool {
        return self.match == nil
    }

    func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: "Cannot decode type \(type)")
        throw DecodingError.typeMismatch(type, context)
    }

    func decode<T>(_ type: T.Type) throws -> T where T: Decodable, T: LosslessStringConvertible {
        guard let value = T(self.string) else {
            let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: "Cannot decode type \(type)")
            throw DecodingError.typeMismatch(type, context)
        }
        return value
    }
}

@available(OSX 10.13, iOS 11, tvOS 11, watchOS 4, *)
extension _RegularExpressionDecoder.SingleValueContainer: RegularExpressionDecodingContainer {}

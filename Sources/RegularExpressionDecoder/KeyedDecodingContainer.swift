import Foundation

@available(OSX 10.13, iOS 11, tvOS 11, watchOS 4, *)
extension NSTextCheckingResult {
    func range<Key>(for key: Key) -> NSRange? where Key: CodingKey {
        if let position = key.intValue {
            return self.range(at: position)
        } else {
            return self.range(withName: key.stringValue)
        }
    }
}

@available(OSX 10.13, iOS 11, tvOS 11, watchOS 4, *)
extension _RegularExpressionDecoder {
    final class KeyedContainer<Key> where Key: CodingKey {
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

        func range(for key: Key) -> Range<String.Index>? {
            guard let nsrange = self.match?.range(for: key),
                nsrange.location != NSNotFound
                else {
                    return nil
            }

            return Range(nsrange, in: self.string)
        }

        func string(for key: Key) -> String? {
            guard let range = self.range(for: key) else {
                return nil
            }

            return String(self.string[range])
        }
    }
}

@available(OSX 10.13, iOS 11, tvOS 11, watchOS 4, *)
extension _RegularExpressionDecoder.KeyedContainer: KeyedDecodingContainerProtocol {
    var allKeys: [Key] {
        return [] // FIXME
    }

    func contains(_ key: Key) -> Bool {
        return self.range(for: key) != nil
    }

    func decodeNil(forKey key: Key) throws -> Bool {
        return self.match == nil || !contains(key)
    }

    func decode(_ type: String.Type, forKey key: Key) throws -> String {
        guard let string = self.string(for: key) else {
            let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: "String: \(self.string)")
            throw DecodingError.keyNotFound(key, context)
        }

        return string
    }

    func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T: Decodable, T: LosslessStringConvertible {
        let string = try self.decode(String.self, forKey: key)

        guard let value = T(string) else {
            let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: "String: \(self.string)")
            throw DecodingError.typeMismatch(type, context)
        }

        return value
    }

    func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T : Decodable {
        let string = try self.decode(String.self, forKey: key)

        let decoder = _RegularExpressionDecoder(string: string, matches: [self.match].compactMap {$0})
        let value = try T(from: decoder)

        return value
    }

    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        fatalError("Unimplemented")
    }

    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        fatalError("Unimplemented")
    }

    func superDecoder() throws -> Decoder {
        fatalError("Unimplemented")
    }

    func superDecoder(forKey key: Key) throws -> Decoder {
        fatalError("Unimplemented")
    }
}

@available(OSX 10.13, iOS 11, tvOS 11, watchOS 4, *)
extension _RegularExpressionDecoder.KeyedContainer: RegularExpressionDecodingContainer {}

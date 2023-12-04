import Foundation

public final class RisonDecoder: Decoder {
    public var codingPath: [CodingKey] = []
    public var userInfo: [CodingUserInfoKey: Any] = [:]

    var risonString: String?
    var risonValue: Any?

    public init(mode: RisonMode = .standard, risonString: String? = nil, risonValue: Any? = nil) {
        if let risonString {
            switch mode {
            case .standard:
                self.risonString = risonString
            case .aRison:
                self.risonString = "!(\(risonString))"
            case .oRison:
                self.risonString = "(\(risonString))"

            }
        }
        self.risonValue = risonValue
    }
    
    public func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key: CodingKey {
        let rison = try loadRisonValue()
        guard let risonObject = rison as? RisonObject else {
            throw RisonError.invalidArgument
        }
        let container = RisonKeyedDecodingContainer<Key>(risonObject: risonObject)
        container.codingPath = codingPath
        return KeyedDecodingContainer(container)
    }

    public func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        let rison = try loadRisonValue()
        guard let risonArray = rison as? RisonArray else {
            throw RisonError.invalidArgument
        }
        let container = RisonUnkeyedDecodingContainer(risonArray: risonArray)
        container.codingPath = codingPath
        return container
    }
    
    public func singleValueContainer() throws -> SingleValueDecodingContainer {
        let rison = try loadRisonValue()
        let container = RisonSingleValueDecodingContainer(risonValue: rison)
        container.codingPath = codingPath
        return container
    }
    
    private func loadRisonValue() throws -> Any {
        if let risonValue = risonValue {
            return risonValue
        }
        
        guard let risonString = risonString else {
            throw RisonError.invalidArgument
        }
        
        let parser = RisonParser(rison: risonString)
        let value  = try parser.parse()
        risonValue = value
        return value
    }
}

private class RisonKeyedDecodingContainer<Key: CodingKey>: KeyedDecodingContainerProtocol {
    let risonObject: RisonObject
    var codingPath: [CodingKey] = []
    var allKeys: [Key] = []

    init(risonObject: RisonObject) {
        self.risonObject = risonObject
    }

    func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T: Decodable {
        guard let risonValue = risonObject[key.stringValue] else {
            throw DecodingError.valueNotFound(T.self, DecodingError.Context(codingPath: codingPath, debugDescription: "No parsed value found for key"))
        }
        let decoder = RisonDecoder(risonValue: risonValue)
        decoder.codingPath = codingPath + [key]
        return try T(from: decoder)
    }

    func contains(_ key: Key) -> Bool {
        return risonObject[key.stringValue] != nil
    }
    
    func decodeNil(forKey key: Key) throws -> Bool {
        guard let risonValue = risonObject[key.stringValue] else {
            throw DecodingError.valueNotFound(Any.self, DecodingError.Context(codingPath: codingPath, debugDescription: "No parsed value found for key"))
        }
        return risonValue is RisonNil
    }
    
    private func decoder(for key: CodingKey) throws -> Decoder {
        guard let object = risonObject[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath, debugDescription: "No parsed value found for key"))
        }
        let decoder = RisonDecoder(risonValue: object)
        decoder.codingPath = codingPath + [key]
        return decoder
    }
    
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey {
        try decoder(for: key).container(keyedBy: type)
    }
    
    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        try decoder(for: key).unkeyedContainer()
    }
    
    func superDecoder() throws -> Decoder {
        try decoder(for: SuperCodingKey())
    }
    
    func superDecoder(forKey key: Key) throws -> Decoder {
        try decoder(for: key)
    }
}

private class RisonUnkeyedDecodingContainer: UnkeyedDecodingContainer {
    
    var codingPath: [CodingKey] = []
    let risonArray: RisonArray

    var currentIndex: Int = 0
    var count: Int? { risonArray.count }
    var isAtEnd: Bool { currentIndex >= (count ?? 0 - 1) }

    init(risonArray: RisonArray) {
        self.risonArray = risonArray
    }

    func decodeNil() throws -> Bool {
        guard !isAtEnd else {
            throw DecodingError.valueNotFound(Any.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Past end of container"))
        }
        let isNil = risonArray[currentIndex] is RisonNil
        if isNil {
            currentIndex += 1
        }
        return isNil
    }
    
    func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
        guard !isAtEnd else {
            throw DecodingError.valueNotFound(T.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Past end of container"))
        }
        let risonValue = risonArray[currentIndex]
        let decoder = RisonDecoder(risonValue: risonValue)
        decoder.codingPath = codingPath
        let value = try T(from: decoder)
        currentIndex += 1
        return value
    }

    private func decoderForNextValue() throws -> Decoder {
        guard !isAtEnd else {
            throw DecodingError.valueNotFound(Any.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Past end of container"))
        }
        let risonValue = risonArray[currentIndex]
        currentIndex += 1
        let decoder = RisonDecoder(risonValue: risonValue)
        decoder.codingPath = codingPath
        return decoder
    }
    
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey {
        try decoderForNextValue().container(keyedBy: type)
    }
    
    func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        try decoderForNextValue().unkeyedContainer()
    }
    
    func superDecoder() throws -> Decoder {
        try decoderForNextValue()
    }
}

private class RisonSingleValueDecodingContainer: SingleValueDecodingContainer {
    var codingPath: [CodingKey] = []
    let risonValue: Any

    init(risonValue: Any) {
        self.risonValue = risonValue
    }

    func decodeNil() -> Bool {
        risonValue is RisonNil
    }
    
    func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
        guard let value = risonValue as? T else {
            throw DecodingError.typeMismatch(T.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Incompatible type"))
        }
        return value
    }

    private func numberValue() throws -> RisonNumber {
        guard let value = risonValue as? RisonNumber else {
            throw DecodingError.typeMismatch(RisonNumber.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Incompatible type"))
        }
        return value
    }

    func decode(_ type: Double.Type) throws -> Double {
        let numberValue = try numberValue()
        return numberValue.doubleValue
    }
    
    func decode(_ type: Float.Type) throws -> Float {
        let numberValue = try numberValue()
        return numberValue.floatValue
    }
    
    func decode(_ type: Int.Type) throws -> Int {
        let numberValue = try numberValue()
        return numberValue.intValue
    }
    
    func decode(_ type: Int8.Type) throws -> Int8 {
        let numberValue = try numberValue()
        return numberValue.int8Value
    }
    
    func decode(_ type: Int16.Type) throws -> Int16 {
        let numberValue = try numberValue()
        return numberValue.int16Value
    }
    
    func decode(_ type: Int32.Type) throws -> Int32 {
        let numberValue = try numberValue()
        return numberValue.int32Value
    }
    
    func decode(_ type: Int64.Type) throws -> Int64 {
        let numberValue = try numberValue()
        return numberValue.int64Value
    }
    
    func decode(_ type: UInt.Type) throws -> UInt {
        let numberValue = try numberValue()
        return numberValue.uintValue
    }
    
    func decode(_ type: UInt8.Type) throws -> UInt8 {
        let numberValue = try numberValue()
        return numberValue.uint8Value
    }
    
    func decode(_ type: UInt16.Type) throws -> UInt16 {
        let numberValue = try numberValue()
        return numberValue.uint16Value
    }
    
    func decode(_ type: UInt32.Type) throws -> UInt32 {
        let numberValue = try numberValue()
        return numberValue.uint32Value
    }
    
    func decode(_ type: UInt64.Type) throws -> UInt64 {
        let numberValue = try numberValue()
        return numberValue.uint64Value
    }
    
}

import Foundation


public final class RisonEncoder: Encoder {
    public var codingPath: [CodingKey]  = []
    public var userInfo: [CodingUserInfoKey: Any] = [:]
    
    var rison: Any?
    let mode: RisonMode
    
    public init(mode: RisonMode = .standard) {
        self.mode = mode
    }
    
    public func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key: CodingKey {
        if rison == nil {
            let ref = Reference(RisonObject())
            rison = ref
        }
        
        guard let risonObject = rison as? Reference<RisonObject> else {
            fatalError("Cannot create container of a new type")
        }
        
        let container = RisonKeyedEncoding<Key>(to: risonObject)
        container.codingPath = codingPath
        return KeyedEncodingContainer(container)
    }
    
    public func unkeyedContainer() -> UnkeyedEncodingContainer {
        if rison == nil {
            let ref = Reference(RisonArray())
            rison = ref
        }
        
        guard let risonArray = rison as? Reference<RisonArray> else {
            fatalError("Cannot create container of a new type")
        }
        
        let container = RisonUnkeyedEncodingContainer(ref: risonArray)
        container.codingPath = codingPath
        return container
    }
    
    public func singleValueContainer() -> SingleValueEncodingContainer {
        return self
    }
}

extension RisonEncoder {
    
    public func risonString() -> String {
        var ret = ""
        if let rison {
            ret = toRisonString(rison)
        }
        
        switch mode {
        case .aRison:
            if ret.hasPrefix("!(") && ret.hasSuffix(")") {
                return String(ret.dropFirst(2).dropLast(1))
            }
        case .oRison:
            if ret.hasPrefix("(") && ret.hasSuffix(")") {
                return String(ret.dropFirst(1).dropLast(1))
            }
        case .standard:
            break
        }
        
        return ret
    }
    
    private func toRisonString(_ risonValue: Any) -> String {
        switch risonValue {
        case let objectRef as Reference<RisonObject>:
            let elements = objectRef.value.map { key, value in "\(key):\(toRisonString(value))" }
            return "(\(elements.joined(separator: ",")))"
        case let arrayRef as Reference<RisonArray>:
            let elements = arrayRef.value.map { toRisonString($0) }
            return "!(\(elements.joined(separator: ",")))"
        case let number as RisonNumber:
            if number.isBoolean() {
                return number.boolValue ? "!t" : "!f"
            } else {
                return number.stringValue
            }
        case _ as RisonNil:
            return "!n"
        case let string as String:
            return string
        default:
            return ""
        }
    }
}

extension RisonEncoder: SingleValueEncodingContainer {
    
    public func encodeNil() throws {
        rison = RisonNil()
    }
    
    public func encode<T>(_ value: T) throws where T : Encodable {
        switch value {
        case let stringValue as String:
            rison = stringValue
        case let intValue as Int:
            rison = RisonNumber(value: intValue)
        case let intValue as Int8:
            rison = RisonNumber(value: intValue)
        case let intValue as Int16:
            rison = RisonNumber(value: intValue)
        case let intValue as Int32:
            rison = RisonNumber(value: intValue)
        case let intValue as Int64:
            rison = RisonNumber(value: intValue)
        case let intValue as UInt:
            rison = RisonNumber(value: intValue)
        case let intValue as UInt8:
            rison = RisonNumber(value: intValue)
        case let intValue as UInt16:
            rison = RisonNumber(value: intValue)
        case let intValue as UInt32:
            rison = RisonNumber(value: intValue)
        case let intValue as UInt64:
            rison = RisonNumber(value: intValue)
        case let doubleValue as Double:
            rison = RisonNumber(value: doubleValue)
        case let floatValue as Float:
            rison = RisonNumber(value: floatValue)
        case let boolValue as Bool:
            rison = RisonNumber(value: boolValue)
        default:
            throw RisonError.cannotEncodeValue
        }
    }
}

private final class RisonKeyedEncoding<Key: CodingKey>: KeyedEncodingContainerProtocol {
    var codingPath: [CodingKey] = []
    private var ref: Reference<RisonObject>
    
    init(to ref: Reference<RisonObject>) {
        self.ref = ref
    }
    
    func encodeNil(forKey key: Key) throws {
        ref.value[key.stringValue] = RisonNil()
    }
    
    func encode<T>(_ value: T, forKey key: Key) throws where T: Encodable {
        let encoder = RisonEncoder()
        try value.encode(to: encoder)
        ref.value[key.stringValue] = encoder.rison
    }
    
    private func encoder(for key: CodingKey, rison: Any? = Reference(RisonObject())) -> RisonEncoder {
        ref.value[key.stringValue] = rison
        let encoder = RisonEncoder()
        encoder.rison = rison
        return encoder
    }

    func superEncoder() -> Encoder {
        encoder(for: SuperCodingKey())
    }
    
    func superEncoder(forKey key: Key) -> Encoder {
        encoder(for: key)
    }
        
    func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey {
        encoder(for: key).container(keyedBy: NestedKey.self)
    }
    
    func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        encoder(for: key, rison: Reference(RisonArray())).unkeyedContainer()
    }
}

private final class RisonUnkeyedEncodingContainer: UnkeyedEncodingContainer {
    var codingPath: [CodingKey] = []
    var count: Int {
        ref.value.count
    }
    
    var ref: Reference<RisonArray>
    init(ref: Reference<RisonArray>) {
        self.ref = ref
    }

    func encodeNil() throws {
        ref.value.append(RisonNil())
    }
    
    private func encoder(for rison: Any = Reference(RisonArray())) -> RisonEncoder {
        ref.value.append(rison)
        let encoder = RisonEncoder()
        encoder.rison = rison
        return encoder
    }

    func encode<T>(_ value: T) throws where T : Encodable {
        let encoder = RisonEncoder()
        try value.encode(to: encoder)
        guard let rison = encoder.rison else {
            throw RisonError.cannotEncodeValue
        }
        ref.value.append(rison)
    }
    
    func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        encoder(for: Reference(RisonObject())).container(keyedBy: keyType)
    }
    
    func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        encoder().unkeyedContainer()
    }
    
    func superEncoder() -> Encoder {
        encoder()
    }
}

// MARK: - Helpers

private extension NSNumber {
    func isBoolean() -> Bool {
        CFGetTypeID(self) == CFBooleanGetTypeID()
    }
}

private class Reference<T> {
    var value: T
    init(_ value: T) {
        self.value = value
    }
}

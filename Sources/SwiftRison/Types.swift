import Foundation

public enum RisonError: Error {
    case invalidArgument
    case cannotEncodeValue
    case parseEror(message: String)
}

public enum RisonMode {
    case standard, oRison, aRison
}

// MARK: - Internal types

typealias RisonObject = [String: Any]
typealias RisonArray = [Any]
typealias RisonNumber = NSNumber
typealias RisonNil = NSNull

struct SuperCodingKey: CodingKey {
    private static let superValue = "super"
    
    var intValue: Int? { return 0 }
    var stringValue: String { return SuperCodingKey.superValue }

    init?(intValue: Int) {
        if intValue != 0 {
            return nil
        }
    }
    
    init?(stringValue: String) {
        if stringValue != SuperCodingKey.superValue {
            return nil
        }
    }
    
    init() { }
}


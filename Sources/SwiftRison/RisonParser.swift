import Foundation

// MARK: - RisonParser
// ported from:  https://github.com/Nanonid/rison/blob/e64af6c096fd30950ec32cfd48526ca6ee21649d/js/rison.js#L306

class RisonParser {

    // to accept whitespace set rison.parser.WHITESPACE = " \t\n\r\f";
    private static let whiteSpace = ""
    
    private let rison: String
    private var index = 0

    private var regex: NSRegularExpression {
        get throws {
            let notIdChar = NSRegularExpression.escapedPattern(for: " '!:(),*@$")
            let notIdStart = NSRegularExpression.escapedPattern(for: "-0123456789")
            let pattern = "[^\(notIdStart)\(notIdChar)][^\(notIdChar)]*"
            return try NSRegularExpression(pattern: pattern)
        }
      }
    
    init(rison: String) {
        self.rison = rison
    }
    
    func parse() throws -> Any {
        return try readValue()
    }
    
    private func nextId(_ startIndex: Int, _ text: String) throws -> String? {
        let range = NSRange(location: startIndex, length: text.count - startIndex)
        let resultRange = try regex.rangeOfFirstMatch(in: text, range: range)
        return text.substring(with: resultRange)
    }
    
    private func readValue() throws -> Any {
        let c = next()
        
        if let c = c,
           let fn = try parser(controlChar: c) {
            return try fn()
        }
        
        let i = index - 1
        let id = try nextId(i, rison)
        
        if let id = id,
           !id.isEmpty {
            index = i + id.count
            return id
        }
        
        if let c = c {
            throw RisonError.parseEror(message: "invalid character: '\(c)'")
        }
        
        throw RisonError.parseEror(message: "empty expression")
    }

    private func parseArray() throws -> RisonArray {
        var array: RisonArray = []
        
        while let c = next() {
            if c == ")" {
                break
            }
            if !array.isEmpty {
                if c != "," {
                    throw RisonError.parseEror(message: "missing ','")
                }
            } else if c == "," {
                throw RisonError.parseEror(message: "extra ','")
            } else {
                index -= 1
            }
            let n = try readValue()
            array.append(n)
        }
        
        return array
    }
    
    private func bangs(controlChar: String) throws -> Any {
        switch controlChar {
        case "t":
            return true
        case "f":
            return false
        case "n":
            return RisonNil()
        case "(":
            return try parseArray()
        default:
            throw RisonError.parseEror(message: "unknown literal: \"!\(controlChar)\"")
        }
    }

    private func parser(controlChar: String) throws -> (() throws -> Any)? {
        switch controlChar {
        case "!":
            return {
                if self.index >= self.rison.count {
                    throw RisonError.parseEror(message: "\"!\" at end of input")
                }
                let c = self.rison[self.index]
                self.index += 1
                return try self.bangs(controlChar: c)
            }
        case "(":
            return {
                var object: RisonObject = [:]
                var count = 0
                while let c = self.next(),
                      c != ")" {
                    if count > 0 {
                        guard c == "," else {
                            throw RisonError.parseEror(message: "missing ','")
                        }
                    } else if c == "," {
                        throw RisonError.parseEror(message: "extra ','")
                    } else {
                        self.index -= 1
                    }
                    let key = try self.readValue()
                    guard let keyString = key as? String else {
                        throw RisonError.parseEror(message: "invalid key")
                    }
                    guard self.next() == ":" else {
                        throw RisonError.parseEror(message: "missing ':'")
                    }
                    let value = try self.readValue()
                    object[keyString] = value
                    count += 1
                }
                return object
            }
        case "'":
            return {
                var i = self.index
                var start = i
                var segments: [String] = []
                var c = ""
                while c != "'" {
                    guard i <= self.rison.count else {
                        throw RisonError.parseEror(message: "unmatched \"'\"")
                    }
                    c = self.rison[i]
                    i += 1
                    if c == "!" {
                        if start < i-1 {
                            segments.append(self.rison[start..<(i-1)])
                        }
                        c = self.rison[i]
                        i += 1
                        if c == "!" || c == "'" {
                            segments.append(c)
                        } else {
                            throw RisonError.parseEror(message: "invalid string escape: \"!\(c)\"")
                        }
                        start = i
                    }
                }
                if start < i-1 {
                    segments.append(self.rison[start..<(i-1)])
                }
                self.index = i
                return segments.count == 1 ? segments[0] : segments.joined(separator: ",")
            }
            
        case "-", "0"..."9":
            return {
                var s = self.rison
                var i = self.index
                let start = i - 1
                var state: String? = "int"
                var permittedSigns = "-"
                let transitions = [
                    "int+.": "frac",
                    "int+e": "exp",
                    "frac+e": "exp"
                ]
                
                repeat {
                    guard i < s.count else {
                        break
                    }
                    let c = s[i]
                    i += 1
                    if "0" <= c && c <= "9" {
                        continue
                    }
                    if permittedSigns.contains(c) {
                        permittedSigns = ""
                        continue
                    }
                    state = transitions["\(state ?? "")+\(c.lowercased())"]
                    if state == "exp" {
                        permittedSigns = "-"
                    }
                } while state != nil
                i -= 1
                self.index = i
                s = s[start..<i]
                if s == "-" {
                    throw RisonError.parseEror(message: "invalid number")
                }
                
                guard let number = NumberFormatter().number(from: s) else {
                    throw RisonError.parseEror(message: "could not convert \(s) to a numebr")
                }
                
                return number
            }
        default:
            return nil
        }
    }
    
    private func next() -> String? {
        var c = ""
        repeat {
            if index >= rison.count {
                return nil
            }
            c = rison[index]
            index += 1
        } while RisonParser.whiteSpace.contains(c)
        return c
    }
}

// MARK: - Helper extensions

private extension String {

    subscript (index: Int) -> String {
        let charIndex = self.index(self.startIndex, offsetBy: index)
        return String(self[charIndex])
    }

    subscript (range: Range<Int>) -> String {
        let startIndex = self.index(self.startIndex, offsetBy: range.startIndex)
        let stopIndex = self.index(self.startIndex, offsetBy: range.startIndex + range.count)
        return String(self[startIndex..<stopIndex])
    }

    func substring(with nsrange: NSRange) -> String? {
        guard let range = Range(nsrange, in: self) else { return nil }
        return String(self[range])
    }
}

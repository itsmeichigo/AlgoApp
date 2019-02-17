import Foundation

/// A string extension which provides easy functionality to decode
/// HTML entities.
extension String {
    
    /// Returns a new string made by removing in the `String`
    /// anything enclosed in HTML brackets <>
    public var stringByStrippingHTMLTags: String {
        return replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil);
    }
    /// Returns a new string made by replacing in the `String`
    /// all HTML character entity references with the corresponding
    /// character.
    public var stringByDecodingHTMLEntities: String {
        return decodeHTMLEntities().decodedString
    }
    /// Returns a tuple containing the string made by replacing in the
    /// `String` all HTML character entity references with the corresponding
    /// character. Also returned is an array of offset information describing
    /// the location and length offsets for each replacement. This allows
    /// for the correct adjustment of any attributes that may be associated with
    /// with substrings within the `String`
    func decodeHTMLEntities() -> (decodedString: String, replacementOffsets: [(index: String.Index, offset: String.IndexDistance)]) {
        // ===== Utility functions =====
        // Record the index offsets of each replacement
        // This allows anyone to correctly adjust any attributes that may be
        // associated with substrings within the string
        var replacementOffsets: [(index: String.Index, offset: String.IndexDistance)] = []
        // Convert the number in the string to the corresponding
        // Unicode character, e.g.
        //    decodeNumeric("64", 10)   --> "@"
        //    decodeNumeric("20ac", 16) --> "€"
        func decodeNumeric(string : String, base : Int32) -> Character? {
            let code = UInt32(strtoul(string, nil, base))
            guard let scalar = UnicodeScalar(code) else {
                return nil
            }
            return Character(scalar)
        }
        // Decode the HTML character entity to the corresponding
        // Unicode character, return `nil` for invalid input.
        //     decode("&#64;")    --> "@"
        //     decode("&#x20ac;") --> "€"
        //     decode("&lt;")     --> "<"
        //     decode("&foo;")    --> nil
        func decode(entity : String) -> Character? {
            if entity.hasPrefix("&#x") || entity.hasPrefix("&#X"){
                print(entity[entity.index(entity.startIndex, offsetBy: 3) ..< entity.index(entity.endIndex, offsetBy: -1)])
                
                return decodeNumeric(string: String(entity[entity.index(entity.startIndex, offsetBy: 3) ..< entity.index(entity.endIndex, offsetBy: -1)]), base:16)
                
            } else if entity.hasPrefix("&#") {
                return decodeNumeric(string: String(entity[entity.index(entity.startIndex, offsetBy: 2) ..< entity.index(entity.endIndex, offsetBy: -1)]), base:10)

            } else {
                return characterEntities[entity]
            }
        }
        // ===== Method starts here =====
        var result = ""
        var position = startIndex
        // Find the next '&' and copy the characters preceding it to `result`:
        while let ampRange = self.range(of: "&", range: position ..< endIndex) {
            result.append(String(self[position ..< ampRange.lowerBound]))
            position = ampRange.lowerBound
            // Find the next ';' and copy everything from '&' to ';' into `entity`
            if let semiRange = self.range(of: ";", range: position ..< endIndex) {
                let entity = self[position ..< semiRange.upperBound]
                if let decoded = decode(entity: String(entity)) {
                    // Replace by decoded character:
                    result.append(decoded)
                    // Record offset
                    let offset = (index: semiRange.upperBound, offset: 1 - self.distance(from: position, to: semiRange.upperBound))
                    replacementOffsets.append(offset)
                } else {
                    // Invalid entity, copy verbatim:
                    result.append(contentsOf: entity)
                }
                position = semiRange.upperBound
            } else {
                // No matching ';'.
                break
            }
        }
        // Copy remaining characters to `result`:
        result.append(String(self[position ..< endIndex]))
        // Return results
        return (decodedString: result, replacementOffsets: replacementOffsets)
    }
}

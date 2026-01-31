import Foundation

extension Data {
    func getUInt16(offset: Int) -> UInt16 {
        UInt16(self[offset]) << 8 | UInt16(self[offset + 1])
    }
    
    func getSubData(offset: Int, size: Int) -> Data {
        Data(self.subdata(in: offset..<(offset+size)))
    }

    func toString() -> String {
        map { String($0.char) }.joined()
    }

    func hexString() -> String {
        let format = "%02hhx"
        return map { String(format: format, $0) }.joined()
    }
}

extension UInt8 {
    var char: Character {
        Character(UnicodeScalar(self))
    }
}

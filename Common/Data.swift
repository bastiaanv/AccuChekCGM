import Foundation

extension Data {
    public init(hexString: String) {
        guard hexString.count.isMultiple(of: 2) else {
            fatalError("No a multiple of 2")
        }

        let chars = hexString.map { $0 }
        let bytes = stride(from: 0, to: chars.count, by: 2)
            .map { String(chars[$0]) + String(chars[$0 + 1]) }
            .compactMap { UInt8($0, radix: 16) }

        guard hexString.count / bytes.count == 2 else {
            fatalError("No a multiple of 2")
        }
        self.init(bytes)
    }

    func getUInt16(offset: Int) -> UInt16 {
        UInt16(self[offset + 1]) << 8 | UInt16(self[offset])
    }

    func getDouble(offset: Int) -> Double {
        let value = Int16(self[offset + 1]) << 8 | Int16(self[offset])
        return getMantissa(value) * pow(10.0, Double(getExponent(value)))
    }

    private func getExponent(_ value: Int16) -> Int8 {
        Int8(value >> 12)
    }

    private func getMantissa(_ value: Int16) -> Double {
        Double((value << 4) >> 4)
    }

    func getSubData(offset: Int, size: Int) -> Data {
        Data(subdata(in: offset ..< (offset + size)))
    }

    func toString() -> String {
        map { String($0.char) }.joined()
    }

    func hexString() -> String {
        let format = "%02hhx"
        return map { String(format: format, $0) }.joined()
    }

    static func randomSecure(length: Int) -> Data {
        var randomNumberGenerator = SecRandomNumberGenerator()
        return Data((0 ..< length).map { _ in UInt8.random(in: UInt8.min ... UInt8.max, using: &randomNumberGenerator) })
    }

    private func getExponent(value: UInt16) -> Double {
        // TODO: Fixme
        if value < 0 {
            return Double(((value >> 12) & 0x0F) | 0xF0)
        }

        return Double((value >> 12) & 0x0F)
    }

    private func getMantissa(value: UInt16) -> UInt16 {
        if (value & 0x0800) != 0 {
            return UInt16((value & 0x0FFF) | 0xF000)
        }

        return UInt16(value & 0x0FFF)
    }
}

extension UInt8 {
    var char: Character {
        Character(UnicodeScalar(self))
    }
}

struct SecRandomNumberGenerator: RandomNumberGenerator {
    func next() -> UInt64 {
        let size = MemoryLayout<UInt64>.size
        var data = Data(count: size)
        return data.withUnsafeMutableBytes {
            guard SecRandomCopyBytes(kSecRandomDefault, size, $0.baseAddress!) == 0 else { fatalError() }
            return $0.load(as: UInt64.self)
        }
    }
}

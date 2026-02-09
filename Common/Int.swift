import Foundation

extension UInt16 {
    func toData() -> Data {
        Data([
            UInt8(self & 0xFF),
            UInt8((self >> 8) & 0xFF)
        ])
    }
}

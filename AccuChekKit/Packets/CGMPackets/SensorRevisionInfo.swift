import Foundation

struct SensorInfo: Decodable, Encodable {
    let manufacturer: String
    let model: String
    let serialNumber: String
    let firmwareRevision: String
    let hardwareRevision: String
    let softwareRevision: String

    var describe: String {
        "[SensorInfo] manufacturer: \(manufacturer), model: \(model), serialNumber: \(serialNumber), firmwareRevision: \(firmwareRevision), hardwareRevision: \(hardwareRevision), softwareRevision: \(softwareRevision)"
    }

    static func `default`() -> SensorInfo {
        SensorInfo(
            manufacturer: "Roche-fake",
            model: "",
            serialNumber: "",
            firmwareRevision: "*",
            hardwareRevision: "*",
            softwareRevision: "*"
        )
    }
}

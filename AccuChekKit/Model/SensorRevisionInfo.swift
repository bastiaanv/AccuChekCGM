struct SensorRevisionInfo {
    let serialNumber: String
    let firmwareRevision: String
    let hardwareRevision: String
    let softwareRevision: String

    static func `default`() -> SensorRevisionInfo {
        SensorRevisionInfo(
            serialNumber: "",
            firmwareRevision: "*",
            hardwareRevision: "*",
            softwareRevision: "*"
        )
    }
}

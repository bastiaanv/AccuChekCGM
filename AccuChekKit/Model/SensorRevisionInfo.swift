struct SensorRevisionInfo {
    let serialNumber: String
    let firmwareRevision: String
    let hardwareRevision: String
    let softwareRevision: String

    static func `default`() -> SensorRevisionInfo {
        SensorRevisionInfo(
            serialNumber: "000667359",
            firmwareRevision: "*",
            hardwareRevision: "*",
            softwareRevision: "*"
        )
    }
}

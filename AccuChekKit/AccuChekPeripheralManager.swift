import CoreBluetooth
import CryptoKit

class AccuChekPeripheralManager: NSObject {
    private let logger = AccuChekLogger(category: "PeripheralManager")

    private var peripheral: CBPeripheral
    private let cgmManager: AccuChekCgmManager
    private var connecionCompletion: ((AccuChekError?) -> Void)?

    internal var pairingAdapter: PairingAdapter?

    private var readQueue: (NSCondition, CBUUID)?
    private var readData = Data()

    private var writeQueue: (NSCondition, CBUUID)?
    private var writeData = Data()

    internal var mtu: Int = 20
    internal var aesCgmKey: SymmetricKey?

    init(peripheral: CBPeripheral, cgmManager: AccuChekCgmManager, completion: ((AccuChekError?) -> Void)?) {
        self.peripheral = peripheral
        self.cgmManager = cgmManager
        connecionCompletion = completion

        if let key = cgmManager.state.aesKey {
            aesCgmKey = SymmetricKey(data: key)
            logger.debug("Constructed AES CGM Key!")
        }

        super.init()

        peripheral.delegate = self
    }

    func read(service serviceUUID: CBUUID, characteristic characteristicUUID: CBUUID) -> Data? {
        guard let characteristic = getCharacteristic(serviceUUID: serviceUUID, characteristicUUID: characteristicUUID) else {
            return nil
        }

        let readQ = NSCondition()
        readQueue = (readQ, characteristicUUID)
        peripheral.readValue(for: characteristic)

        readQ.lock()
        defer {
            readQ.unlock()
            readData = Data()
            readQueue = nil
        }

        // Wait for response or timeout timer...
        readQ.wait(until: Date.now.addingTimeInterval(15))
        return readData
    }

    func write(packet: AccuChekBasePacket, service serviceUUID: CBUUID, characteristic characteristicUUID: CBUUID) -> Bool {
        guard let characteristic = getCharacteristic(serviceUUID: serviceUUID, characteristicUUID: characteristicUUID) else {
            return false
        }

        var writeQ = NSCondition()
        writeQueue = (writeQ, characteristicUUID)

        for item in segmentData(data: packet.getRequest(), mtu: mtu) {
            logger.debug("Writing \(item.hexString()) to \(characteristic.uuid.uuidString)")
            peripheral.writeValue(
                item,
                for: characteristic,
                type: serviceUUID == CBUUID.CGM_SERVICE ? .withResponse : .withoutResponse
            )
            Thread.sleep(forTimeInterval: .milliseconds(100))
        }

        writeQ.lock()
        defer {
            writeQ.unlock()
            writeData = Data()
            writeQueue = nil
        }

        while !packet.isComplete() {
            // Wait for response or timeout timer...
            if !writeQ.wait(until: Date.now.addingTimeInterval(10)) || writeData.isEmpty {
                logger.error("Timeout has been hit...")
                return false
            }

            packet.parseResponse(data: writeData)
            writeData = Data()

            writeQ = NSCondition()
            writeQueue = (writeQ, characteristicUUID)
        }

        return true
    }

    func startNotify(service serviceUUID: CBUUID, characteristic characteristicUUID: CBUUID) {
        guard let characteristic = getCharacteristic(serviceUUID: serviceUUID, characteristicUUID: characteristicUUID) else {
            return
        }

        peripheral.setNotifyValue(true, for: characteristic)
    }

    private func getCharacteristic(serviceUUID: CBUUID, characteristicUUID: CBUUID) -> CBCharacteristic? {
        guard let service = peripheral.services?.first(where: { $0.uuid == serviceUUID }) else {
            logger.error("Failed to find service: \(serviceUUID.uuidString)")
            return nil
        }

        guard let characteristic = service.characteristics?.first(where: { $0.uuid == characteristicUUID }) else {
            logger.error("Failed to find characteristic: \(characteristicUUID.uuidString)")
            return nil
        }

        return characteristic
    }
}

extension AccuChekPeripheralManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: (any Error)?) {
        if let error = error {
            logger.error("Failed to discoverServices: \(error.localizedDescription)")
            connecionCompletion?(.discoveringFailed)
            return
        }

        logger.info("Discovered services: \(peripheral.services?.map(\.uuid.uuidString).joined(separator: ", ") ?? "none")")
        if let acsService = peripheral.services?.first(where: { $0.uuid == CBUUID.ACS_SERVICE }) {
            logger.debug("Discovering ACS Service...")
            peripheral.discoverCharacteristics(CBUUID.ACS_CHARACTERISTICS, for: acsService)
        }

        guard let rcsService = peripheral.services?.first(where: { $0.uuid == CBUUID.RCS_SERVICE }) else {
            logger.error("Couldnt find RCS nor ACS service")
            connecionCompletion?(.discoveringFailed)
            return
        }

        logger.debug("Discovering RCS servcice...")
        peripheral.discoverCharacteristics(CBUUID.ACS_CHARACTERISTICS, for: rcsService)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: (any Error)?) {
        if let error = error {
            logger
                .error(
                    "Failed to discoverCharacteristics - service: \(service.uuid.uuidString), error: \(error.localizedDescription)"
                )
            connecionCompletion?(.discoveringFailed)
            return
        }

        let serviceUUID = service.uuid
        let characteristics = service.characteristics?.map(\.uuid.uuidString).joined(separator: ", ") ?? "none"
        logger.info("Discovered characteristics of service \(serviceUUID.uuidString), chars: \(characteristics)")
        if serviceUUID == CBUUID.ACS_SERVICE {
            guard let rcsService = peripheral.services?.first(where: { $0.uuid == CBUUID.RCS_SERVICE }) else {
                logger.error("Couldnt find RCS service")
                connecionCompletion?(.discoveringFailed)
                return
            }

            peripheral.discoverCharacteristics(CBUUID.RCS_CHARACTERISTICS, for: rcsService)
            return
        }

        if serviceUUID == CBUUID.RCS_SERVICE {
            guard let rcsService = peripheral.services?.first(where: { $0.uuid == CBUUID.DIS_SERVICE }) else {
                logger.error("Couldnt find DIS service")
                connecionCompletion?(.discoveringFailed)
                return
            }

            peripheral.discoverCharacteristics(CBUUID.DIS_CHARACTERISTICS, for: rcsService)
            return
        }

        if serviceUUID == CBUUID.DIS_SERVICE {
            guard let rcsService = peripheral.services?.first(where: { $0.uuid == CBUUID.CGM_SERVICE }) else {
                logger.error("Couldnt find CGM service")
                connecionCompletion?(.discoveringFailed)
                return
            }

            peripheral.discoverCharacteristics(CBUUID.CGM_CHARACTERISTICS, for: rcsService)
            return
        }

        guard let services = peripheral.services else {
            logger.error("No services found on peripheral")
            return
        }

        self.peripheral = peripheral
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            let pairingAdapter: PairingAdapter
            if services.contains(where: { $0.uuid == CBUUID.ACS_SERVICE }) {
                pairingAdapter = AcsAdapter(cgmManager: cgmManager, peripheralManager: self)
            } else {
                pairingAdapter = LegacyPasskeyAdapater(cgmManager: cgmManager, peripheralManager: self)
            }
            self.pairingAdapter = pairingAdapter

            pairingAdapter.pair()
            if !pairingAdapter.initialize() {
                logger.error("Initialization failed...")
                return
            }

            pairingAdapter.configureSensor()
            connecionCompletion?(nil)
        }
    }

    func peripheral(_: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: (any Error)?) {
        if let error = error {
            logger.error("Received error in didUpdateValueFor: \(error.localizedDescription)")
            return
        }
        guard let data = characteristic.value else {
            let service = characteristic.service?.uuid.uuidString ?? ""
            let characteristic = characteristic.uuid.uuidString
            logger.warning("Empty data -> characteristic: \(characteristic), service: \(service)")

            return
        }

        logger.debug("Recieved data: \(data.hexString()), characteristic: \(characteristic.uuid.uuidString)")
        if let (readQueue, readCharacteristic) = readQueue, readCharacteristic == characteristic.uuid {
            readData = data
            readQueue.signal()
            return
        }

        if let (writeQueue, writeCharacteristic) = writeQueue, writeCharacteristic == characteristic.uuid {
            writeData.append(data)
            writeQueue.signal()
            return
        }

        if characteristic.uuid == CBUUID.CGM_MEASUREMENT {
            let measurement = CgmMeasurement(data)
            logger.info(measurement.describe)

            cgmManager.notifyNewData(measurements: [measurement])
            return
        }

        if characteristic.uuid == CBUUID.CGM_STATUS {
            let status = SensorStatus(data: data)
            logger.info(status.describe)

            cgmManager.notifyNewStatus(status)
            return
        }

        logger.warning("Not handled above message...")
    }
}

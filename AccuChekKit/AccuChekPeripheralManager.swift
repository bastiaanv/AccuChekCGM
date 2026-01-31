import CoreBluetooth

class AccuChekPeripheralManager: NSObject {
    private let logger = AccuChekLogger(category: "PeripheralManager")

    private let peripheral: CBPeripheral
    private let cgmManager: AccuChekCgmManager
    private var connecionCompletion: ((AccuChekError?) -> Void)?

    private var pairingAdapter: PairingAdapter?

    private var readQueue: NSCondition?
    private var readData = Data()

    private var writeQueue: NSCondition?
    private var writeData = Data()

    init(peripheral: CBPeripheral, cgmManager: AccuChekCgmManager, completion: ((AccuChekError?) -> Void)?) {
        self.peripheral = peripheral
        self.cgmManager = cgmManager
        connecionCompletion = completion
        super.init()

        peripheral.delegate = self
    }

    func read(service serviceUUID: CBUUID, characteristic characteristicUUID: CBUUID) -> Data? {
        guard let characteristic = getCharacteristic(serviceUUID: serviceUUID, characteristicUUID: characteristicUUID) else {
            return nil
        }

        let readQ = NSCondition()
        readQueue = readQ
        peripheral.readValue(for: characteristic)

        readQ.lock()
        defer {
            readQ.unlock()
            readData = Data()
            readQueue = nil
        }

        // Wait for response or timeout timer...
        readQ.wait(until: Date.now.addingTimeInterval(10))

        return readData
    }

    func write(packet: AcsBasePacket, service serviceUUID: CBUUID, characteristic characteristicUUID: CBUUID) -> Bool {
        guard let characteristic = getCharacteristic(serviceUUID: serviceUUID, characteristicUUID: characteristicUUID) else {
            return false
        }

        let writeQ = NSCondition()
        writeQueue = writeQ

        for item in packet.getRequest() {
            peripheral.writeValue(item, for: characteristic, type: .withoutResponse)
            Thread.sleep(forTimeInterval: .milliseconds(100))
        }

        writeQ.lock()
        defer {
            writeQ.unlock()
            writeData = Data()
            writeQueue = nil
        }

        for i in 0 ..< packet.numberOfResponses {
            // Wait for response or timeout timer...
            writeQ.wait(until: Date.now.addingTimeInterval(10))
            if writeData.isEmpty {
                logger.error("Timeout has been hit...")
                return false
            }

            packet.parseResponse(data: writeData)
            writeData = Data()
        }

        return packet.isComplete()
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

        guard let acsService = peripheral.services?.first(where: { $0.uuid == CBUUID.ACS_SERVICE }) else {
            logger.error("Couldnt find ACS service")
            connecionCompletion?(.discoveringFailed)
            return
        }

        peripheral.discoverCharacteristics(CBUUID.ACS_CHARACTERISTICS, for: acsService)
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

        logger.info("Discovered characteristics of service \(service.uuid.uuidString)")
        if service.uuid == CBUUID.ACS_SERVICE {
            guard let rcsService = peripheral.services?.first(where: { $0.uuid == CBUUID.RCS_SERVICE }) else {
                logger.error("Couldnt find RCS service")
                connecionCompletion?(.discoveringFailed)
                return
            }

            peripheral.discoverCharacteristics(CBUUID.RCS_CHARACTERISTICS, for: rcsService)
            return
        }

        if service.uuid == CBUUID.RCS_SERVICE {
            guard let rcsService = peripheral.services?.first(where: { $0.uuid == CBUUID.DIS_SERVICE }) else {
                logger.error("Couldnt find DIS service")
                connecionCompletion?(.discoveringFailed)
                return
            }

            peripheral.discoverCharacteristics(CBUUID.DIS_CHARACTERISTICS, for: rcsService)
            return
        }

        if service.uuid == CBUUID.DIS_SERVICE {
            guard let rcsService = peripheral.services?.first(where: { $0.uuid == CBUUID.CGM_SERVICE }) else {
                logger.error("Couldnt find CGM service")
                connecionCompletion?(.discoveringFailed)
                return
            }

            peripheral.discoverCharacteristics(CBUUID.CGM_CHARACTERISTICS, for: rcsService)
            return
        }

        if cgmManager.state.hasAcs {
            pairingAdapter = AcsAdapter(cgmManager: cgmManager, peripheralManager: self)
            pairingAdapter?.pair()
            pairingAdapter?.initialize()
        } else {
            logger.error("LegacyPasskeyAdapter not implemented...")
            connecionCompletion?(.discoveringFailed)
            return
        }
    }

    func peripheral(_: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: (any Error)?) {
        if let error = error {
            logger.error("Received error in didUpdateValueFor: \(error.localizedDescription)")
            return
        }
        guard let data = characteristic.value else {
            logger
                .warning(
                    "Empty data -> characteristic: \(characteristic.uuid.uuidString), service: \(characteristic.service?.uuid.uuidString ?? "nil")"
                )
            return
        }

        if let readQueue = readQueue {
            readData = data
            readQueue.signal()
            return
        }

        if let writeQueue = writeQueue {
            writeData.append(data)
            // TODO: Are we ready to signal?

            writeQueue.signal()
            return
        }
    }
}

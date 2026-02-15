import CoreBluetooth

class AccuChekBluetoothManager: NSObject {
    private let logger = AccuChekLogger(category: "BluetoothManager")
    private let managerQueue = DispatchQueue(label: "com.bastiaanv.accuchek.bluetoothManagerQueue", qos: .unspecified)

    private var manager: CBCentralManager?
    private var peripheral: CBPeripheral?
    private var peripheralManager: AccuChekPeripheralManager?
    public var cgmManager: AccuChekCgmManager?

    private var scanCompletion: ((ScanResult) -> Void)?
    private var connectCompletion: ((AccuChekError?) -> Void)?

    override init() {
        super.init()

        managerQueue.sync {
            self.manager = CBCentralManager(
                delegate: self,
                queue: self.managerQueue,
                options: [CBCentralManagerOptionRestoreIdentifierKey: "com.bastiaanv.accuchek"]
            )
        }
    }

    func startScan(completion: @escaping (ScanResult) -> Void) {
        guard let manager else {
            logger.error("No CBCentralManager available...")
            return
        }

        scanCompletion = completion
        manager.scanForPeripherals(withServices: [CBUUID.CGM_SERVICE])
        logger.info("Started scan!")
    }

    func stopScan() {
        guard let manager else {
            logger.error("No CBCentralManager available...")
            return
        }

        if manager.isScanning {
            manager.stopScan()
        }

        logger.info("Stop scan!")
    }

    func connect(to peripheral: CBPeripheral, completion: @escaping (AccuChekError?) -> Void) {
        guard let manager else {
            logger.error("No CBCentralManager available...")
            return
        }

        stopScan()

        self.peripheral = peripheral
        connectCompletion = completion
        manager.connect(peripheral, options: nil)
        logger.info("Connecting to \(peripheral.name ?? "Unknown")...")
    }

    func disconnect() {
        guard let manager, let peripheral else {
            logger.error("No CBCentralManager or peripheral available...")
            return
        }

        manager.cancelPeripheralConnection(peripheral)

        self.peripheral = nil
        peripheralManager = nil
    }
    
    func read(service: CBUUID, characteristic: CBUUID) -> Data? {
        guard let peripheralManager else {
            logger.error("No peripheralManager...")
            return nil
        }
        
        return peripheralManager.read(service: service, characteristic: characteristic)
    }
    
    func write(packet: AccuChekBasePacket, service: CBUUID, characteristic: CBUUID) -> Bool {
        guard let peripheralManager else {
            logger.error("No peripheralManager...")
            return false
        }
        
        return peripheralManager.write(packet: packet, service: service, characteristic: characteristic)
    }

    private func restoreConnection() {
        guard let deviceName = cgmManager?.state.deviceName else {
            logger.error("Cannot start ensureConnected - No device name available...")
            return
        }

        startScan { result in
            guard result.deviceName == deviceName else {
                self.logger.debug("Found wrong CGM - name: \(result.describe)")
                return
            }

            self.connect(to: result.peripheral) { error in
                if let error = error {
                    self.logger.error("Failed to restore: \(error)")
                }
            }
        }
    }
}

extension AccuChekBluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        logger.info("State: \(central.state.rawValue)")

        guard central.state == .poweredOn else {
            return
        }

        if let peripheral = peripheral {
            connect(to: peripheral) { error in
                if let error = error {
                    self.logger.error("Failed to restore: \(error)")
                }
            }
            return
        }

        restoreConnection()
    }

    func centralManager(_ manager: CBCentralManager, willRestoreState dict: [String: Any]) {
        if let cgmService = UUID(uuidString: CBUUID.CGM_SERVICE.uuidString),
           let peripheral = manager.retrievePeripherals(withIdentifiers: [cgmService]).first
        {
            self.peripheral = peripheral
        }

        guard let deviceName = cgmManager?.state.deviceName else {
            logger.warning("No device name available...")
            return
        }

        guard let peripherals = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral],
              let peripheral = peripherals.first(where: { $0.name == deviceName })
        else {
            logger.warning("Restore state but no peripheral found")
            return
        }

        self.peripheral = peripheral
    }

    func centralManager(
        _: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi _: NSNumber
    ) {
        guard let result = ScanResult(peripheral: peripheral, advertismentData: advertisementData) else {
            return
        }

        logger.info(result.describe)
        scanCompletion?(result)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        logger.info("Connected to \(peripheral.name ?? "")")

        guard let cgmManager else {
            logger.error("No CGMManager -> Disconnecting...")
            central.cancelPeripheralConnection(peripheral)
            return
        }

        cgmManager.state.isConnected = true
        cgmManager.notifyStateDidChange()

        peripheralManager = AccuChekPeripheralManager(
            peripheral: peripheral,
            cgmManager: cgmManager,
            completion: connectCompletion
        )
        peripheral.discoverServices([CBUUID.ACS_SERVICE, CBUUID.RCS_SERVICE, CBUUID.DIS_SERVICE, CBUUID.CGM_SERVICE])
    }

    func centralManager(_: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: (any Error)?) {
        if let error = error {
            logger.error("Received error during disconnect: \(error.localizedDescription)")
        } else {
            logger.warning("\(peripheral.name ?? "") disconnected")
        }

        guard let cgmManager else {
            logger.error("No CGMManager...")
            return
        }

        cgmManager.state.isConnected = false
        cgmManager.notifyStateDidChange()

        if cgmManager.state.deviceName == nil {
            logger.warning("Prevent auto-reconnect -> unpaired device...")
            return
        }

        connect(to: peripheral) { error in
            if let error {
                self.logger.error("Failed to reconnect: \(error)")
            }
        }
    }
}

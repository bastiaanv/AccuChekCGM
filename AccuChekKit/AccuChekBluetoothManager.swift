import CoreBluetooth

class AccuChekBluetoothManager: NSObject {
    private let logger = AccuChekLogger(category: "BluetoothManager")
    private let managerQueue = DispatchQueue(label: "com.bastiaanv.accuchek.bluetoothManagerQueue", qos: .unspecified)

    private var manager: CBCentralManager?
    private var peripheralManager: AccuChekPeripheralManager?
    public var cgmManager: AccuChekCgmManager?

    private var scanCompletion: ((ScanResult) -> Void)?
    private var connectCompletion: ((AccuChekError?) -> Void)?

    override init() {
        super.init()
        manager = CBCentralManager(delegate: self, queue: managerQueue)
    }

    func startScan(completion: @escaping (ScanResult) -> Void) {
        guard let manager else {
            logger.error("No CBCentralManager available...")
            return
        }

        scanCompletion = completion
        manager.scanForPeripherals(withServices: [CBUUID.CGM_SERVICE])
    }

    func connect(to peripheral: CBPeripheral, completion: @escaping (AccuChekError?) -> Void) {
        guard let manager else {
            logger.error("No CBCentralManager available...")
            return
        }

        if manager.isScanning {
            manager.stopScan()
        }

        connectCompletion = completion
        manager.connect(peripheral, options: nil)
    }
}

extension AccuChekBluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        logger.info("State: \(central.state.rawValue)")
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

        scanCompletion?(result)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        logger.info("Connected to \(peripheral.name ?? "")")

        guard let cgmManager else {
            logger.error("No CGMManager -> Disconnecting...")
            central.cancelPeripheralConnection(peripheral)
            return
        }

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

        connect(to: peripheral) { error in
            if let error {
                self.logger.error("Failed to reconnect: \(error)")
            }
        }
    }
}

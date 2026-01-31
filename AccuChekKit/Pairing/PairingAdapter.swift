import CoreBluetooth

protocol PairingAdapter {
    var peripheralManager: AccuChekPeripheralManager { get }
    var cgmManager: AccuChekCgmManager { get }

    func pair()
    func initialize() -> Bool
    func configureSensor()
}

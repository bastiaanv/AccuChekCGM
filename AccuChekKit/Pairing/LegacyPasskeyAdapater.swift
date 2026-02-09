import CoreBluetooth
import Foundation

class LegacyPasskeyAdapater: PairingAdapter {
    var logger = AccuChekLogger(category: "LegacyPasskeyAdapater")
    var peripheralManager: AccuChekPeripheralManager
    var cgmManager: AccuChekCgmManager

    init(cgmManager: AccuChekCgmManager, peripheralManager: AccuChekPeripheralManager) {
        self.peripheralManager = peripheralManager
        self.cgmManager = cgmManager
    }

    func pair() {
        guard let cgmStatus = peripheralManager.read(service: CBUUID.CGM_SERVICE, characteristic: CBUUID.CGM_STATUS) else {
            logger.error("Failed to read cgmStatus")
            return
        }

        logger.info("CGM status: \(cgmStatus.hexString())")
    }

    func initialize() -> Bool {
        peripheralManager.startNotify(service: CBUUID.CGM_SERVICE, characteristic: CBUUID.CGM_MEASUREMENT)
        peripheralManager.startNotify(service: CBUUID.CGM_SERVICE, characteristic: CBUUID.CGM_CONTROL_POINT)
        peripheralManager.startNotify(service: CBUUID.CGM_SERVICE, characteristic: CBUUID.CGM_RACP)
        peripheralManager.startNotify(service: CBUUID.RCS_SERVICE, characteristic: CBUUID.RCS_CONTROL_POINT)

        return true
    }
}

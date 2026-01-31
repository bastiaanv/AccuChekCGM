import CoreBluetooth

class AcsAdapter: PairingAdapter {
    private let logger = AccuChekLogger(category: "AcsAdapter")

    internal let cgmManager: AccuChekCgmManager
    internal let peripheralManager: AccuChekPeripheralManager
    
    private let descriptorPacket = GetAllActiveDescriptorsPacket()

    init(cgmManager: AccuChekCgmManager, peripheralManager: AccuChekPeripheralManager) {
        self.cgmManager = cgmManager
        self.peripheralManager = peripheralManager
    }

    func pair() {
        guard peripheralManager.read(service: CBUUID.ACS_SERVICE, characteristic: CBUUID.ACS_STATUS) != nil else {
            logger.error("Failed to read ACS status")
            return
        }

        peripheralManager.startNotify(service: CBUUID.ACS_SERVICE, characteristic: CBUUID.ACS_DATA_OUT_NOTIFY)
        peripheralManager.startNotify(service: CBUUID.ACS_SERVICE, characteristic: CBUUID.ACS_DATA_OUT_INDICATE)
    }

    func initialize() -> Bool {
        if cgmManager.state.publicKey != nil, cgmManager.state.privateKey != nil {
            logger.info("Used auth bypass")
            return true
        }
        
        peripheralManager.startNotify(service: CBUUID.ACS_SERVICE, characteristic: CBUUID.ACS_CONTROL_POINT)

        let mtuPacket = GetAttMtuPacket()
        if !peripheralManager.write(packet: mtuPacket, service: CBUUID.ACS_SERVICE, characteristic: CBUUID.ACS_CONTROL_POINT) {
            logger.error("Failed to write to GetAttMtu")
            return false
        }

        cgmManager.state.mtu = mtuPacket.mtu
        
        if !peripheralManager.write(packet: descriptorPacket, service: CBUUID.ACS_SERVICE, characteristic: CBUUID.ACS_CONTROL_POINT) {
            logger.error("Failed to write to GetAllActiveDescriptors")
            return false
        }

        // TODO: GetResourceHandleToUuidMap

        let certPacket = GetCertificateNonce()
        if !peripheralManager.write(packet: certPacket, service: CBUUID.ACS_SERVICE, characteristic: CBUUID.ACS_CONTROL_POINT) {
            logger.error("Failed to write to GetCertificateNonce")
            return false
        }
        
        doKeyExchange(keyConfigurations: descriptorPacket.keyConfigurations, nonce: certPacket.nonce)
    }

    func configureSensor() {}
    
    private func doKeyExchange(keyConfigurations: [IKeyDescriptor], nonce: UInt16) {
        
    }
}

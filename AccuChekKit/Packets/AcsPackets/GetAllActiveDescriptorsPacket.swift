import Foundation

class GetAllActiveDescriptorsPacket: AccuChekBasePacket {
    var securityConfigurations: [SecurityConfiguration] = []
    var keyConfigurations: [IKeyDescriptor] = []

    var describe: String {
        "[GetAllActiveDescriptorsPacket] #securityConf=\(securityConfigurations.count), hasAesCgm=\(getAesCgm() != nil), hasEcdh=\(getEcdh() != nil)"
    }

    func getRequest() -> Data {
        createAcsOpCodePacket(code: AcsOpcode.getAllActiveDescriptors)
    }

    func parseResponse(data: Data) {
        switch data[0] {
        case 3:
            parseRestrictionMap(data)
        case 12:
            parseSecurityConfig(data)
        case 14:
            parseKeyConfig(data)
        default:
            break
        }
    }

    func isComplete() -> Bool {
        !securityConfigurations.isEmpty && !keyConfigurations.isEmpty
    }

    func getAesCgm() -> AesCgmKeyDescriptor? {
        for key in keyConfigurations where key.keyType == .aes128Gcm {
            return key as? AesCgmKeyDescriptor
        }
        return nil
    }

    func getEcdh() -> EcdhKeyDescriptor? {
        for key in keyConfigurations {
            if let key = key as? EcdhKeyDescriptor {
                return key
            }
        }
        return nil
    }

    private func parseRestrictionMap(_: Data) {}

    private func parseSecurityConfig(_ data: Data) {
        var index = 1
        while index < data.count {
            let controlCount = Int(data[index + 3])
            var keyId: UInt16?

            var controls: [SecurityControl] = []
            for i in 0 ..< controlCount {
                if let control = SecurityControl(rawValue: data[index + 4 + i]) {
                    controls.append(control)
                }
            }

            var offset = 4 + controlCount
            if controls.contains(where: { $0 == SecurityControl.Unencrypted }) {
                keyId = data.getUInt16(offset: index + 5 + controlCount)
                offset += 2
            }

            securityConfigurations.append(SecurityConfiguration(
                configurationId: data.getUInt16(offset: index + 1),
                keyId: keyId,
                securityControl: controls
            ))

            index += offset
        }
    }

    private func parseKeyConfig(_ data: Data) {
        var index = 1
        while index < data.count {
            switch data[index + 1] {
            case KeyDescriptorType.ecdhKeyExchange.rawValue:
                if let descriptor = parseEcdhKeyDescriptor(data, index) {
                    keyConfigurations.append(descriptor)
                }
            case KeyDescriptorType.aes128Gcm.rawValue:
                if let descriptor = parseAesKeyDescriptor(data, index) {
                    keyConfigurations.append(descriptor)
                }
            default:
                let length = data[index + 2]
                index += 3 + Int(length)
            }
        }
    }

    private func parseEcdhKeyDescriptor(_ data: Data, _ index: Int) -> EcdhKeyDescriptor? {
        EcdhKeyDescriptor(
            keyId: data.getUInt16(offset: index + 2),
            keyType: KeyDescriptorType.ecdhKeyExchange,
            serverPublicKeyFormat: data[index + 3],
            clientPublicKeyFormat: data[index + 4],
            ellipticCurve: data[index + 5],
            keyDerivationFunction: data[index + 6]
        )
    }

    private func parseAesKeyDescriptor(_ data: Data, _ index: Int) -> AesCgmKeyDescriptor? {
        AesCgmKeyDescriptor(
            keyId: data.getUInt16(offset: index + 2),
            keyType: data[index + 3],
            messageType: data[index + 4],
            macSize: data[index + 5],
            nonceType: data[index + 6],
            nonceVariableSize: data[index + 7],
            nonceFixedSize: data[index + 8],
            nonceFixedValue: data.getSubData(offset: index + 8, size: Int(data[index + 8]))
        )
    }
}

struct SecurityConfiguration {
    let configurationId: UInt16
    let keyId: UInt16?
    let securityControl: [SecurityControl]
}

import Foundation

protocol AccuChekBasePacket {
    var numberOfResponses: Int { get }
    var describe: String { get }

    func getRequest() -> Data
    func parseResponse(data: Data)
    func isComplete() -> Bool
}

extension AccuChekBasePacket {
    func createAcsOpCodePacket(code: AcsOpcode) -> Data {
        Data([code.rawValue])
    }
}

enum AcsOpcode: UInt8 {
    case getAllActiveDescriptors = 1
    case getRestrictionMapDescriptor = 2
    case restrictionMapDescriptorResponse = 3
    case getRestrictionMapIdList = 4
    case getRestrictionMapIdListResponse = 5
    case getResourceHandleToUuidMap = 7
    case resourceHandleToUuidMapResponse = 8
    case getInformationSecurityConfigurationDescriptor = 11
    case informationSecurityConfigurationDescriptorResponse = 12
    case getKeyDescriptor = 13
    case keyDescriptorResponse = 14
    case startKeyExchange = 17
    case keyExchangeResponse = 18
    case invalidateAllEstablishedSecurity = 19
    case keyExchangeEcdh = 27
    case keyExchangeEcdhResponse = 28
    case keyExchangeEcdhConfirmationCode = 29
    case keyExchangeEcdhConfirmationCodeResponse = 30
    case keyExchangeEcdhConfirmationRandomNumber = 31
    case keyExchangeEcdhConfirmationRandomNumberResponse = 32
    case keyExchangeKdf = 33
    case keyExchangeKdfResponse = 34
    case setAcClientNonceFixed = 35
    case getAttMtu = 221
    case attMtuResponse = 222
    case getCertificateNonce = 224
    case getCertificateNonceResponse = 225
}

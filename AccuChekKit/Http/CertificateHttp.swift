import ASN1
import CryptoKit
import Foundation
import UIKit

enum CertificateHttp {
    private static let logger = AccuChekLogger(category: "CertificateHttp")

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        // 2027-02-05T19:05:24Z
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        return formatter
    }()

    static func getCertificate(request: CertificateRequest) async -> Certificate? {
        guard let csrPem = generateCertificationRequest(request: request) else {
            logger.error("Failed to generate certificate request")
            return nil
        }

        do {
            let device = await UIDevice.current
            let requestBody = AcsCertificateRequest(
                dcdCSR: csrPem,
                dcdCWVersions: ["SmartGuide|1.2.0"],
                dcdHWVersions: ["Apple|\(await device.model)"],
                dcdSWVersions: ["iOS|\(await device.systemVersion)", "SmartGuide|1.2.0"],
                hdCWVersions: [request.sensorRevisionInfo.firmwareRevision],
                hdHWVersions: [request.sensorRevisionInfo.hardwareRevision],
                hdSWVersions: [request.sensorRevisionInfo.softwareRevision]
            )
            let requestJson = try JSONEncoder().encode(requestBody)

            guard let url = URL(string: "https://api.prodeu.rdcplatform.com/cs/pki/v3/certificate") else {
                logger.error("Failed to parse URL")
                return nil
            }

            var httpRequest = URLRequest(url: url)
            httpRequest.httpMethod = "POST"
            httpRequest.httpBody = requestJson
            httpRequest.allHTTPHeaderFields = [
                "client_id": AuthHttp.CLIENT_ID,
                "client_secret": AuthHttp.CLIENT_SECRET,
                "apiKey": AuthHttp.API_KEY,
                "x-operation-id": UUID().uuidString,
                "Content-Type": "application/json",
                "Authorization": "Bearer \(request.authToken)",
                "Content-Digest": "SHA-256=\(hash(data: requestJson))"
            ]

            let (data, response) = try await URLSession.shared.data(for: httpRequest)
            guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
                let body = String(data: data, encoding: .utf8) ?? "No data"
                let code = (response as? HTTPURLResponse)?.statusCode ?? -1
                logger.error("Got invalid response certificate: \(code) \(body)")

                return nil
            }

            print(String(data: data, encoding: .utf8))
            let responseObj = try JSONDecoder().decode(AcsCertrificateResponse.self, from: data)

            let certificates = responseObj.certificates.compactMap {
                guard let der = Data(base64Encoded: $0.dcdCertificate),
                      let validTo = dateFormatter.date(from: $0.dcdCertificateValidTo)
                else {
                    logger
                        .error(
                            "Some object is empty or of wrong type - encoded value: \($0.dcdCertificate), validTo: \($0.dcdCertificateValidTo)"
                        )
                    return nil as Certificate?
                }

                return Certificate(der: der, validTo: validTo)
            }.sorted(by: { $0.validTo > $1.validTo })

            return certificates.first
        } catch {
            logger.error("Failed to generate certificate: \(error.localizedDescription)")
            return nil
        }
    }

    private static func hash(data: Data) -> String {
        var sha = SHA256()
        sha.update(data: data)

        return Data(sha.finalize()).base64EncodedString()
    }

    private static func generateCertificationRequest(request: CertificateRequest) -> String? {
        let csr = CertificateSigningRequest(
            commonName: "947",
            surName: "303",
            givenName: "*",
            organizationName: "Roche Diabetes Care GmbH",
            serialNumber: UUID().uuidString[0 ..< 36],
            pseudonym: "*",
            keyAlgorithm: KeyAlgorithm.ec(signatureType: KeyAlgorithm.Signature.sha256)
        )

        return csr.buildAndEncodeDataAsString(privateKey: request.privateKey)
    }

    struct CertificateRequest {
        let privateKey: P256.KeyAgreement.PrivateKey
        let sensorRevisionInfo: SensorInfo
        let authToken: String
    }

    struct AcsCertificateRequest: Encodable {
        let dcdCSR: String
        let dcdCWVersions: [String]
        let dcdHWVersions: [String]
        let dcdSWVersions: [String]
        let hdCWVersions: [String]
        let hdHWVersions: [String]
        let hdSWVersions: [String]
    }

    struct AcsCertrificateResponse: Decodable {
        let certificates: [Acscertificate]
    }

    struct Acscertificate: Decodable {
        let hdTypeId: String
        let dcdCertificate: String
        let dcdCertificateValidFrom: String
        let dcdCertificateValidTo: String
        let caSerialNumber: String
    }
}

struct Certificate: Decodable, Encodable, Equatable {
    let der: Data
    let validTo: Date
}

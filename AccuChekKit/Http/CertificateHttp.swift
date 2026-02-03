import CryptoKit
import ASN1
import Foundation
import UIKit

enum CertificateHttp {
    private static let logger = AccuChekLogger(category: "CertificateHttp")

    static func getCertificate(request: CertificateRequest) async -> Certificate? {
        guard let csrPem = generateCertificationRequest(request: request) else {
            logger.error("Failed to generate certificate request")
            return nil
        }

        logger.info("csrPem: \(csrPem)")

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

            print([
                "client_id": AuthHttp.CLIENT_ID,
                "client_secret": AuthHttp.CLIENT_SECRET,
                "apiKey": AuthHttp.API_KEY,
                "x-operation-id": UUID().uuidString,
                "Content-Type": "application/json",
                "Authorization": "Bearer \(request.authToken)",
                "Content-Digest": "SHA-256=\(hash(data: requestJson))"
            ])
            print(String(bytes: requestJson, encoding: .utf8))

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
                do {
                    guard
                        let der = Data(base64Encoded: $0.dcdCertificate),
                        let asn1Sequence = try ASN1.build(der) as? ASN1Sequence,
                        let tbsCertificate = asn1Sequence.get(0) as? ASN1Sequence,
                        let validity = tbsCertificate.get(4) as? ASN1Sequence,
                        let notValidAfter = validity.get(1) as? ASN1Time
                    else {
                        logger.error("Some object is empty or of wrong type - encoded value: \($0.dcdCertificate)")
                        return nil as Certificate?
                    }

                    return Certificate(der: der, notValidAfter: notValidAfter.toDate() ?? Date.distantPast)
                } catch {
                    logger.error("Failed to parse certificate: \(error.localizedDescription)")
                    return nil
                }
            }.sorted(by: { $0.notValidAfter > $1.notValidAfter })

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
            givenName: request.serialNumber,
            organizationName: "Roche Diabetes Care GmbH",
            serialNumber: request.dcdSerialNumber,
            pseudonym: "\(request.certificateNonce)",
            keyAlgorithm: KeyAlgorithm.ec(signatureType: KeyAlgorithm.Signature.sha256)
        )

        return csr.buildAndEncodeDataAsString(privateKey: request.privateKey)
    }

    struct CertificateRequest {
        let serialNumber: String
        let certificateNonce: UInt16
        let dcdSerialNumber: String
        let privateKey: P256.Signing.PrivateKey
        let sensorRevisionInfo: SensorRevisionInfo
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

struct Certificate {
    let der: Data
    let notValidAfter: Date
}

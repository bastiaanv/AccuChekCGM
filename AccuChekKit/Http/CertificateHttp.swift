import Foundation
internal import X509
import UIKit
internal import SwiftASN1
internal import Crypto

enum CertificateHttp {
    private static let logger = AccuChekLogger(category: "CertificateHttp")

    static func getCertificate(request: CertificateRequest) async -> Certificate? {
        guard let csrPem = generateCertificationRequest(request: request) else {
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
                        let cert = SecCertificateCreateWithData(nil, der as CFData)
                    else {
                        return nil as Certificate?
                    }

                    return try Certificate(cert)
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
        do {
            let subject = try DistinguishedName([
                .init(type: .NameAttributes.organizationName, utf8String: "Roche Diabetes Care GmbH"),
                .init(type: .NameAttributes.commonName, utf8String: "947"),
                .init(type: .NameAttributes.surname, utf8String: "303"),
                .init(type: .NameAttributes.pseudonym, utf8String: "\(request.certificateNonce)"),
                .init(type: .NameAttributes.serialNumber, utf8String: request.dcdSerialNumber.uuidString),
                .init(type: .NameAttributes.givenName, utf8String: request.serialNumber)
            ])

            let csr = try CertificateSigningRequest(
                version: .v1,
                subject: subject,
                privateKey: Certificate.PrivateKey(request.privateKey),
                attributes: CertificateSigningRequest.Attributes([]),
                signatureAlgorithm: .ecdsaWithSHA256
            )

            if !csr.publicKey.isValidSignature(csr.signature, for: csr) {
                logger.error("Signature is invalid...")
                return nil
            }

            var pemString = try csr.publicKey.serializeAsPEM(discriminator: CertificateSigningRequest.defaultPEMDiscriminator)
                .pemString
            return pemString
                .replace(target: "-----BEGIN CERTIFICATE REQUEST-----\n", withString: "")
                .replace(target: "-----END CERTIFICATE REQUEST-----\n", withString: "")
                .replace(target: "\n", withString: "")
                .replace(target: "\r", withString: "")
        } catch {
            logger.error("Failed to generate certificate request: \(error.localizedDescription)")
            return nil
        }
    }

    struct CertificateRequest {
        let serialNumber: String
        let certificateNonce: UInt16
        let dcdSerialNumber: UUID
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

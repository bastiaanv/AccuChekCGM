import Foundation

enum TokenType: String {
    case code = "CODE"
    case refresh = "REFRESH"
}

/*
 {\"access_token\":\"st2.s.AtLt0ptssQ.rMA4TfCFihlFPVD4PUSzEneiAZpqChDNa92yP8CFVeP2NaGndXUhC7euDtzjkpqwIV-FXgBE9uqTKW8yqjMl6tWW67sTjfnIgOY5en8ffJRAqQcG0YkIUXVSHpUkQsi5.dv3G6KwHYaI4O27EV8kHsHqEfOZeRDYYD7amNLY4MMNamuWDH1Fax5-DpUrGmwvJenZSGYDK3I3-iaKcshSiMg.sc3\",\"expires_in\":86400,\"refresh_token\":\"st2.s.AtLt9FhIIw.MKF8pQvMen_smJOxVktwJGP0e8YNssIA2kMqN3X8mZkc0ubwid-tFhMemP88o-vQIWzkXoErn-OpGaxJgJ4ifqz-M1VC5tZjwc0gBf5siEfpHpgUz_isnFIA1gkVfa89.KosX7FJWuCRGtzs3Fnz0mwkk2HqTDQTa2JDS8pK1HUnFJSBCPW3i2rE4T7H5nXq1vbs3VDzCXJpprkMAKeFYQQ.sc3\",\"id_token\":\"eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsImtpZCI6IlJFUTBNVVE1TjBOQ1JUSkVNemszTTBVMVJrTkRRMFUwUTBNMVJFRkJSamhETWpkRU5VRkJRZyJ9.eyJpc3MiOiJodHRwczovL2ZpZG0uZ2lneWEuY29tL2p3dC80X19KS2xjTV9jeEpTSDQzUDljTEwybUEvIiwiYXBpS2V5IjoiNF9fSktsY01fY3hKU0g0M1A5Y0xMMm1BIiwiaWF0IjoxNzY5OTQzNTc4LCJleHAiOjE3NzAwMjk5NzgsInN1YiI6IjA0NDRmZTJkNWQ4NzRmMDZhZDNiMTQ5ZGQ5MGRhZTA4IiwiZW1haWwiOiJiYXN0aWFua3BuNzgwMEBnbWFpbC5jb20ifQ.lryV11R1CJB4SAxdlyi20PYAUCZinqGn0xoH6xTT2I71SYfCrJnARzlmsa4NJPJVij7rcKAFhUu8N7gQCzr3MBdp1tkRMqrfX8Hri9JdAel8ttevc8szp89JGT7SAGBaY9_u13TKtHO9YXBk_3fIsKK1par-wkVMlY3u-vWanBjko-pVJTgvNQQYWsxBbIKvJatgWdNXb2jGKqiZF9nUo_KY-VOphqAKHgGRqO7MRqFOBgbzpg3qd0KmkblYj5IaAwBYhxU-ygEtUNkBOSB16extIi08TRI-2-_xtdGm6tNeSXtBxA3paCEwWyN-8BG1acP0neWx87wzwXAv6W4xyw\",\"token_type\":\"Bearer\"}
 */

enum AuthHttp {
    public static let CLIENT_ID = "036e247fda28423db6153bbc75458f4d"
    public static let CLIENT_SECRET = "C7401EFF2C914602A9f4AC8B10A5EB86"
    public static let API_KEY = "4__JKlcM_cxJSH43P9cLL2mA"

    private static let logger = AccuChekLogger(category: "AuthHttp")

    static func getToken(code: String, type: TokenType) async -> AuthResponse? {
        guard let url = URL(string: "https://api.prodeu.rdcplatform.com/v2/ciam/api/v3/identities/token") else {
            logger.error("Failed to parse URL")
            return nil
        }

        let requestBody =
            "{\"token\":\"\(code)\",\"tokenType\":\"\(type.rawValue)\",\"redirectUri\":\"smartguide://oidc/success\"}"

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = [
            "client_id": CLIENT_ID,
            "client_secret": CLIENT_SECRET,
            "apiKey": API_KEY,
            "x-operation-id": UUID().uuidString,
            "Content-Type": "application/json"
        ]
        request.httpBody = Data(requestBody.utf8)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
                logger
                    .error(
                        "Got invalid response auth token: \((response as? HTTPURLResponse)?.statusCode ?? -1) \(String(data: data, encoding: .utf8) ?? "No data")"
                    )
                return nil
            }

            print(String(data: data, encoding: .utf8))
            return try JSONDecoder().decode(AuthResponse.self, from: data)
        } catch {
            logger.error("Failed to get auth token: \(error.localizedDescription)")
            return nil
        }
    }
}

struct AuthResponse: Decodable {
    let access_token: String
    let expires_in: Int
    let refresh_token: String
    let id_token: String
    let token_type: String
}

import Foundation

enum TokenType : String {
    case code = "CODE"
    case refresh = "REFRESH"
}

enum AuthHttp {
    private static let CLIENT_ID = "036e247fda28423db6153bbc75458f4d"
    private static let CLIENT_SECRET = "C7401EFF2C914602A9f4AC8B10A5EB86"
    public static let API_KEY = "4__JKlcM_cxJSH43P9cLL2mA"
    
    private static let logger = AccuChekLogger(category: "AuthHttp")
    
    static func getToken(code: String, type: TokenType) async -> AuthResponse? {
        guard let url = URL(string: "https://api.prodeu.rdcplatform.com/v2/ciam/api/v3/identities/token") else {
            logger.error("Failed to parse URL")
            return nil
        }
        
        let requestBody = "{\"token\":\"\(code)\",\"tokenType\":\"\(type.rawValue)\",\"redirectUri\":\"smartguide://oidc/success\"}"
        
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

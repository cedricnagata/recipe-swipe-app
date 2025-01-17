import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

class NetworkService {
    static let shared = NetworkService()
    private let session: URLSession
    
    private lazy var decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZZZZZ"
        
        decoder.dateDecodingStrategy = .custom({ decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            if let date = formatter.date(from: dateString) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date string \(dateString)"
            )
        })
        
        return decoder
    }()
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        session = URLSession(configuration: config)
    }
    
    func fetch<T: Decodable>(
        _ endpoint: String,
        method: HTTPMethod = .get,
        body: [String: Any]? = nil
    ) async throws -> T {
        guard let url = URL(string: Constants.API.baseURL + endpoint) else {
            print("❌ Invalid URL: \(Constants.API.baseURL + endpoint)")
            throw APIError.invalidURL
        }
        
        print("📡 \(method.rawValue) request to: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let body = body {
            let jsonData = try JSONSerialization.data(withJSONObject: body)
            request.httpBody = jsonData
            print("📤 Request body: \(String(data: jsonData, encoding: .utf8) ?? "")")
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid response type")
                throw APIError.networkError(NSError(domain: "", code: -1))
            }
            
            print("📥 Response status code: \(httpResponse.statusCode)")
            
            guard (200...299).contains(httpResponse.statusCode) else {
                print("❌ Server error: \(httpResponse.statusCode)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Response body: \(responseString)")
                }
                throw APIError.serverError(httpResponse.statusCode)
            }
            
            do {
                let decodedData = try decoder.decode(T.self, from: data)
                print("✅ Successfully decoded response")
                return decodedData
            } catch {
                print("❌ Decoding error: \(error)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Failed to decode: \(responseString)")
                }
                throw APIError.decodingError(error)
            }
        } catch {
            print("❌ Network error: \(error)")
            throw APIError.networkError(error)
        }
    }
    
    func fetch(
        _ endpoint: String,
        method: HTTPMethod = .get,
        body: [String: Any]? = nil
    ) async throws {
        // Version without return type for endpoints that don't return data
        try await fetch(endpoint, method: method, body: body) as EmptyResponse
    }
}

// Empty struct for endpoints that don't return data
private struct EmptyResponse: Decodable {}
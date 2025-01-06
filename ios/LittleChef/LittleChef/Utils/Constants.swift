import Foundation

enum Constants {
    enum API {
        static let baseURL = "http://127.0.0.1:8000"  // Changed from localhost to explicit IP
        
        enum Endpoints {
            static let recipes = "/recipes"
            static let nextRecipe = "/recipes/swipe/next"
        }
    }
}

enum APIError: Error {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case noData
    case serverError(Int)
    
    var description: String {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        case .noData:
            return "No data received"
        case .serverError(let code):
            return "Server error: \(code)"
        }
    }
}
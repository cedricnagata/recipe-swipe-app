import Foundation

struct SessionStats: Codable {
    let tagWeights: [String: Double]
    let seenRecipes: Int
    let createdAt: Date
    let lastUpdated: Date
    
    // Remove CodingKeys since we're using .convertFromSnakeCase in NetworkService
}
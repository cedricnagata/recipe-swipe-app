import Foundation

struct SwipeSession: Codable {
    let id: UUID
    let tagWeights: [String: Double]
    let seenRecipes: [UUID]
    let createdAt: Date
    let lastUpdated: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case tagWeights = "tag_weights"
        case seenRecipes = "seen_recipes"
        case createdAt = "created_at"
        case lastUpdated = "last_updated"
    }
}
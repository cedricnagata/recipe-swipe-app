import Foundation

struct RecipeDTO: Codable {
    let id: UUID
    let title: String
    let ingredients: [String: String]
    let steps: [String]
    let sourceUrl: String
    let images: [String?]
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case ingredients
        case steps
        case sourceUrl = "source_url"
        case images
    }
}
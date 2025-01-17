import Foundation

struct RecipeDTO: Codable {
    let id: UUID
    let title: String
    let ingredients: [String: String]
    let steps: [String]
    let sourceUrl: String
    let images: [String?]
    let totalTime: Int?
    let tags: [String]
    let hash: String

    // We don't need CodingKeys anymore since we're using .convertFromSnakeCase
    // in NetworkService's JSONDecoder
}
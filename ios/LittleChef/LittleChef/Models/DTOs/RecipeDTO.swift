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
    let isSaved: Bool
    let servings: Int?
}

struct NextRecipeResponse: Codable {
    let hasMoreRecipes: Bool
    let recipe: RecipeDTO?
}
import Foundation

class SavedRecipeService {
    static let shared = SavedRecipeService()
    private let networkService = NetworkService.shared
    
    private init() {}
    
    func getSavedRecipes() async throws -> [Recipe] {
        print("📲 Requesting saved recipes from API...")
        let recipeDTOs: [RecipeDTO] = try await networkService.fetch("/saved-recipes")
        print("📥 Received \(recipeDTOs.count) recipes from API")
        let recipes = recipeDTOs.map { $0.toRecipe() }
        print("🔄 Converted \(recipes.count) DTOs to Recipe models")
        return recipes
    }
    
    func checkIfSaved(recipeId: UUID) async throws -> Bool {
        struct SavedResponse: Codable {
            let isSaved: Bool
        }
        let response: SavedResponse = try await networkService.fetch("/saved-recipes/check/\(recipeId)")
        return response.isSaved
    }
    
    func unsaveRecipe(recipeId: UUID) async throws {
        print("🗑️ Attempting to delete recipe with ID: \(recipeId)")
        try await networkService.fetch("/saved-recipes/\(recipeId)", method: .delete)
        print("✅ Successfully deleted recipe from saved recipes")
    }
}
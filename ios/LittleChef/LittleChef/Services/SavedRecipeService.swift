import Foundation

class SavedRecipeService {
    static let shared = SavedRecipeService()
    private let networkService = NetworkService.shared
    
    private init() {}
    
    func getSavedRecipes() async throws -> [Recipe] {
        let recipeDTOs: [RecipeDTO] = try await networkService.fetch("/saved-recipes")
        return recipeDTOs.map { $0.toRecipe() }
    }
    
    func checkIfSaved(recipeId: UUID) async throws -> Bool {
        struct SavedResponse: Codable {
            let isSaved: Bool
        }
        let response: SavedResponse = try await networkService.fetch("/saved-recipes/check/\(recipeId)")
        return response.isSaved
    }
    
    func unsaveRecipe(recipeId: UUID) async throws {
        try await networkService.fetch("/saved-recipes/\(recipeId)", method: .delete)
    }
}
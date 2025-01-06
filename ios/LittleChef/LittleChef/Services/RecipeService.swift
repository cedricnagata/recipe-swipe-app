import Foundation

class RecipeService {
    static let shared = RecipeService()
    private let networkService = NetworkService.shared
    
    private init() {}
    
    func fetchNextRecipe() async throws -> Recipe {
        let recipeDTO: RecipeDTO = try await networkService.fetch(Constants.API.Endpoints.nextRecipe)
        return recipeDTO.toRecipe()
    }
    
    func fetchRecipe(id: UUID) async throws -> Recipe {
        let recipeDTO: RecipeDTO = try await networkService.fetch("\(Constants.API.Endpoints.recipes)/\(id)")
        return recipeDTO.toRecipe()
    }
}
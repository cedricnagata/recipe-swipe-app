import Foundation

class SwipeSessionService {
    static let shared = SwipeSessionService()
    private let networkService = NetworkService.shared
    
    private init() {}
    
    func startSession() async throws -> UUID {
        struct SessionResponse: Codable {
            let sessionId: UUID
        }
        let response: SessionResponse = try await networkService.fetch("/swipe-sessions/start", method: .post)
        return response.sessionId
    }
    
    func registerSwipe(sessionId: UUID, recipeId: UUID, liked: Bool, save: Bool) async throws {
        let endpoint = "/swipe-sessions/\(sessionId)/swipe/\(recipeId)?liked=\(liked)&save=\(save)"
        try await networkService.fetch(endpoint, method: .post)
    }
    
    func getNextRecipe(sessionId: UUID) async throws -> (hasMoreRecipes: Bool, recipe: Recipe?) {
        let response: NextRecipeResponse = try await networkService.fetch("/swipe-sessions/\(sessionId)/next")
        return (
            hasMoreRecipes: response.hasMoreRecipes,
            recipe: response.recipe?.toRecipe()
        )
    }
    
    func endSession(sessionId: UUID) async throws {
        try await networkService.fetch("/swipe-sessions/\(sessionId)", method: .delete)
    }
}
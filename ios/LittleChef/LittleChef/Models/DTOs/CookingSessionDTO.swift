import Foundation

struct CreateSessionRequest: Codable {
    let recipeId: UUID
    let currentStep: Int
    
    enum CodingKeys: String, CodingKey {
        case recipeId = "recipe_id"
        case currentStep = "current_step"
    }
}
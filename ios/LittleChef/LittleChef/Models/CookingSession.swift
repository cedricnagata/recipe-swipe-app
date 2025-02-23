import Foundation

struct CookingSession: Codable, Identifiable {
    let id: UUID
    let recipeId: UUID
    var currentStep: Int
    var conversationHistory: [ChatMessage]
    
    // Custom coding keys to match server's snake_case
    enum CodingKeys: String, CodingKey {
        case id
        case recipeId = "recipe_id"
        case currentStep = "current_step"
        case conversationHistory = "conversation_history"
    }
    
    // Encoding
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(recipeId, forKey: .recipeId)
        try container.encode(currentStep, forKey: .currentStep)
        try container.encode(conversationHistory, forKey: .conversationHistory)
    }
    
    // Decoding
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        recipeId = try container.decode(UUID.self, forKey: .recipeId)
        currentStep = try container.decode(Int.self, forKey: .currentStep)
        conversationHistory = (try? container.decode([ChatMessage].self, forKey: .conversationHistory)) ?? []
    }
    
    // Regular init
    init(id: UUID, recipeId: UUID, currentStep: Int, conversationHistory: [ChatMessage] = []) {
        self.id = id
        self.recipeId = recipeId
        self.currentStep = currentStep
        self.conversationHistory = conversationHistory
    }
}
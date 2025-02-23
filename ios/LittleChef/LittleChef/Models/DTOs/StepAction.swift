import Foundation

enum ActionType: String, Codable {
    case timer = "TIMER"
    case temperature = "TEMPERATURE"
}

struct StepAction: Codable, Identifiable {
    var id: String { "\(type)_\(description)" }  // Computed id for SwiftUI ForEach
    let type: ActionType
    let duration: Int?          // for timers (in minutes)
    let appliance: String
    let label: String?         // for timers
    let value: Int?           // for temperatures (in fahrenheit)
    let description: String
}

struct StepActionRequest: Codable {
    let stepNumber: Int
    
    enum CodingKeys: String, CodingKey {
        case stepNumber = "step_number"
    }
}

struct StepActionResponse: Codable {
    let actions: [StepAction]
}

struct ChatRequest: Codable {
    let message: String
}

struct ChatResponse: Codable {
    let message: String
    let suggestedActions: [StepAction]?
    
    enum CodingKeys: String, CodingKey {
        case message
        case suggestedActions = "suggested_actions"
    }
}
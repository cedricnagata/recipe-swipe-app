import Foundation

enum MessageSender: String, Codable {
    case user
    case assistant
}

struct ChatMessage: Identifiable, Codable {
    let id = UUID()
    let content: String
    let sender: MessageSender
    let timestamp: Date
    
    init(content: String, sender: MessageSender, timestamp: Date = Date()) {
        self.content = content
        self.sender = sender
        self.timestamp = timestamp
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case content
        case sender = "role"
        case timestamp
    }
}
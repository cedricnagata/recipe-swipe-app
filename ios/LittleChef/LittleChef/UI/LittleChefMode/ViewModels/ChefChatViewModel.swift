import Foundation
import SwiftUI

class ChefChatViewModel: ObservableObject {
    let recipe: Recipe
    @Published var messages: [ChatMessage] = []
    @Published var inputMessage: String = ""
    @Published var isLoading: Bool = false
    
    init(recipe: Recipe) {
        self.recipe = recipe
        sendWelcomeMessage()
    }
    
    private func sendWelcomeMessage() {
        let welcomeMessage = """
        Hi! I'm your AI cooking assistant and I'm here to help you cook \(recipe.title)! 
        
        I can help you with:
        • Understanding recipe steps
        • Ingredient substitutions
        • Cooking techniques
        • Timing and temperature
        
        What would you like to know?
        """
        
        messages.append(ChatMessage(content: welcomeMessage, sender: .assistant))
    }
    
    func sendMessage() {
        guard !inputMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = ChatMessage(content: inputMessage, sender: .user)
        messages.append(userMessage)
        
        // Store the message and clear input
        let messageToProcess = inputMessage
        inputMessage = ""
        
        // TODO: Implement actual AI response
        isLoading = true
        
        // Simulate AI response for now
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.isLoading = false
            self?.simulateResponse(to: messageToProcess)
        }
    }
    
    // Temporary function until we integrate with the actual AI
    private func simulateResponse(to message: String) {
        let response = "I understand you're asking about '\(message)'. I'm currently being implemented and will be able to help you with your cooking questions soon!"
        messages.append(ChatMessage(content: response, sender: .assistant))
    }
}
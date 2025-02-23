import Foundation
import SwiftUI

@MainActor
class ChefChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputMessage = ""
    @Published var isLoading = false
    @Published var suggestedActions: [StepAction] = []
    
    private let recipe: Recipe
    private let cookingSessionService = CookingSessionService()
    private let sessionId: UUID?
    
    init(recipe: Recipe, sessionId: UUID?) {
        self.recipe = recipe
        self.sessionId = sessionId
    }
    
    func sendMessage() {
        guard !inputMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let sessionId = sessionId else { return }
        
        let messageText = inputMessage
        inputMessage = ""
        
        // Add user message immediately
        let userMessage = ChatMessage(
            content: messageText,
            sender: .user
        )
        messages.append(userMessage)
        
        // Show loading indicator
        isLoading = true
        
        // Send to API
        Task {
            do {
                let response = try await cookingSessionService.sendMessage(
                    sessionId: sessionId,
                    message: messageText
                )
                
                // Add AI response
                let aiMessage = ChatMessage(
                    content: response.message,
                    sender: .assistant
                )
                messages.append(aiMessage)
                
                // Update suggested actions if any
                if let actions = response.suggestedActions {
                    suggestedActions = actions
                }
            } catch {
                // Add error message
                let errorMessage = ChatMessage(
                    content: "Sorry, I'm having trouble responding right now. Please try again.",
                    sender: .assistant
                )
                messages.append(errorMessage)
                print("Error sending message: \(error)")
            }
            
            isLoading = false
        }
    }
}
import Foundation
import SwiftUI

@MainActor
class ChefChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    @Published var suggestedActions: [StepAction] = []
    
    private let recipe: Recipe
    private let cookingSessionService = CookingSessionService()
    private var sessionId: UUID?
    
    init(recipe: Recipe, sessionId: UUID?) {
        self.recipe = recipe
        self.sessionId = sessionId
        
        print("ChefChatViewModel initialized")
        print("Recipe: \(recipe.title)")
        print("SessionId: \(sessionId?.uuidString ?? "nil")")
    }
    
    func sendMessage(_ text: String) {
        print("Sending message: \(text)")
        
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("Empty message")
            return
        }
        
        // If sessionId is nil, create a new session first
        if sessionId == nil {
            createSession(then: { self.sendMessageAfterSessionCreation(text) })
            return
        }
        
        sendMessageToSession(text)
    }
    
    private func createSession(then completion: (() -> Void)? = nil) {
        Task {
            do {
                let session = try await cookingSessionService.createSession(recipeId: recipe.id)
                self.sessionId = session.id
                print("Created new session: \(session.id)")
                
                // Call completion on main thread
                await MainActor.run {
                    completion?()
                }
            } catch {
                print("Error creating cooking session: \(error)")
                
                // Add error message to chat
                await MainActor.run {
                    let errorMessage = ChatMessage(
                        content: "Sorry, I couldn't start a new chat session. Please try again.",
                        sender: .assistant
                    )
                    messages.append(errorMessage)
                }
            }
        }
    }
    
    private func sendMessageAfterSessionCreation(_ text: String) {
        sendMessageToSession(text)
    }
    
    private func sendMessageToSession(_ text: String) {
        guard let sessionId = sessionId else {
            print("No valid session ID")
            return
        }
        
        // Add user message immediately
        let userMessage = ChatMessage(
            content: text,
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
                    message: text
                )
                
                print("Received response: \(response.message)")
                
                // Add AI response
                let aiMessage = ChatMessage(
                    content: response.message,
                    sender: .assistant
                )
                messages.append(aiMessage)
                
                // Update suggested actions if any
                if let actions = response.suggestedActions {
                    print("Received suggested actions: \(actions)")
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
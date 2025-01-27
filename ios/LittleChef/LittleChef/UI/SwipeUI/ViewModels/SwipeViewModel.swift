import Foundation
import SwiftUI

@MainActor
class SwipeViewModel: ObservableObject {
    @Published var currentRecipe: Recipe?
    @Published var isLoading = false
    @Published var error: String?
    @Published var sessionStarted = false
    
    private var currentSessionId: UUID?
    private let swipeSessionService = SwipeSessionService.shared
    
    func startNewSession() async {
        isLoading = true
        error = nil
        sessionStarted = false
        
        do {
            currentSessionId = try await swipeSessionService.startSession()
            sessionStarted = true
            await fetchNextRecipe()
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func fetchNextRecipe() async {
        guard let sessionId = currentSessionId else { return }
        
        isLoading = true
        error = nil
        currentRecipe = nil  // Clear current recipe while loading
        
        do {
            let nextRecipe = try await swipeSessionService.getNextRecipe(sessionId: sessionId)
            withAnimation {
                currentRecipe = nextRecipe
            }
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func swipeRight(saveRecipe: Bool = true) async {
        guard let sessionId = currentSessionId, let recipe = currentRecipe else { return }
        
        do {
            try await swipeSessionService.registerSwipe(
                sessionId: sessionId,
                recipeId: recipe.id,
                liked: true,
                save: saveRecipe
            )
            await fetchNextRecipe()
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func swipeLeft() async {
        guard let sessionId = currentSessionId, let recipe = currentRecipe else { return }
        
        do {
            try await swipeSessionService.registerSwipe(
                sessionId: sessionId,
                recipeId: recipe.id,
                liked: false,
                save: false
            )
            await fetchNextRecipe()
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func endSession() async {
        guard let sessionId = currentSessionId else { return }
        
        do {
            try await swipeSessionService.endSession(sessionId: sessionId)
            currentSessionId = nil
            currentRecipe = nil
            sessionStarted = false
        } catch {
            self.error = error.localizedDescription
        }
    }
}
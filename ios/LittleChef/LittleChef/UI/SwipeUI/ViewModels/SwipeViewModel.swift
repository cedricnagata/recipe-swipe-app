import Foundation
import SwiftUI

@MainActor
class SwipeViewModel: ObservableObject {
    @Published var currentRecipe: Recipe?
    @Published var isLoading = false
    @Published var error: String?
    @Published var sessionStarted = false
    @Published var hasMoreRecipes = true
    
    private var currentSessionId: UUID?
    private let swipeSessionService = SwipeSessionService.shared
    
    func startNewSession() async {
        isLoading = true
        error = nil
        sessionStarted = false
        hasMoreRecipes = true
        
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
            let result = try await swipeSessionService.getNextRecipe(sessionId: sessionId)
            hasMoreRecipes = result.hasMoreRecipes
            
            if hasMoreRecipes {
                withAnimation {
                    currentRecipe = result.recipe
                }
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
            hasMoreRecipes = true
        } catch {
            self.error = error.localizedDescription
        }
    }
}
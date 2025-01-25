import Foundation
import SwiftUI

@MainActor
class SwipeViewModel: ObservableObject {
    @Published var currentRecipe: Recipe?
    @Published var isLoading = false
    @Published var error: String?
    @Published var sessionStats: SessionStats?
    @Published var sessionStarted = false
    
    private var currentSessionId: UUID?
    private let swipeSessionService = SwipeSessionService.shared
    private let savedRecipeService = SavedRecipeService.shared
    
    func startNewSession() async {
        isLoading = true
        error = nil
        sessionStarted = false
        
        do {
            currentSessionId = try await swipeSessionService.startSession()
            print("✅ Started new session: \(currentSessionId?.uuidString ?? "unknown")")
            sessionStarted = true
            await fetchNextRecipe()
        } catch {
            print("❌ Error starting session: \(error)")
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func fetchNextRecipe() async {
        guard let sessionId = currentSessionId else {
            print("❌ No active session")
            return
        }
        
        isLoading = true
        error = nil
        currentRecipe = nil  // Clear current recipe while loading
        
        do {
            print("🔄 Fetching next recipe...")
            let nextRecipe = try await swipeSessionService.getNextRecipe(sessionId: sessionId)
            print("✅ Fetched recipe: \(nextRecipe.title)")
            
            // Update session stats
            sessionStats = try await swipeSessionService.getSessionStats(sessionId: sessionId)
            
            withAnimation {
                currentRecipe = nextRecipe
            }
        } catch {
            print("❌ Error fetching recipe: \(error)")
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func swipeRight(saveRecipe: Bool = true) async {
        guard let sessionId = currentSessionId, let recipe = currentRecipe else { return }
        
        print("👍 Swiped right on: \(recipe.title)")
        
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
        
        print("👎 Swiped left on: \(recipe.title)")
        
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
            sessionStats = nil
            sessionStarted = false
        } catch {
            self.error = error.localizedDescription
        }
    }
}
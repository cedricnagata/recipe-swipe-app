import Foundation
import SwiftUI

@MainActor
class SwipeViewModel: ObservableObject {
    @Published var currentRecipe: Recipe?
    @Published var isLoading = false
    @Published var error: String?
    
    private let recipeService = RecipeService.shared
    
    func fetchNextRecipe() {
        Task {
            isLoading = true
            error = nil
            currentRecipe = nil  // Clear current recipe while loading
            
            do {
                print("🔄 Fetching next recipe...")
                let nextRecipe = try await recipeService.fetchNextRecipe()
                print("✅ Fetched recipe: \(nextRecipe.title)")
                withAnimation {
                    currentRecipe = nextRecipe
                }
            } catch {
                print("❌ Error fetching recipe: \(error)")
                self.error = error.localizedDescription
            }
            
            isLoading = false
        }
    }
    
    func swipeRight() {
        print("👍 Swiped right on: \(currentRecipe?.title ?? "unknown")")
        fetchNextRecipe()
    }
    
    func swipeLeft() {
        print("👎 Swiped left on: \(currentRecipe?.title ?? "unknown")")
        fetchNextRecipe()
    }
}
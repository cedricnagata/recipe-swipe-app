import Foundation

@MainActor
class SavedRecipesViewModel: ObservableObject {
    @Published var recipes: [Recipe] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let savedRecipeService = SavedRecipeService.shared
    
    func fetchSavedRecipes() async {
        isLoading = true
        error = nil
        
        do {
            let fetchedRecipes = try await savedRecipeService.getSavedRecipes()
            recipes = fetchedRecipes
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func unsaveRecipe(_ recipe: Recipe) async {
        guard !isLoading else { return }
        isLoading = true
        
        do {
            // First try to delete from backend
            try await savedRecipeService.unsaveRecipe(recipeId: recipe.id)
            
            // If successful, update the local state
            await fetchSavedRecipes()
        } catch {
            self.error = "Failed to delete recipe: \(error.localizedDescription)"
            // Refresh to ensure UI is in sync with backend
            await fetchSavedRecipes()
        }
        
        isLoading = false
    }
}
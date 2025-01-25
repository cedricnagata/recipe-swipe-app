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
            print("🔄 Fetching saved recipes...")
            let fetchedRecipes = try await savedRecipeService.getSavedRecipes()
            print("✅ Fetched \(fetchedRecipes.count) saved recipes")
            recipes = fetchedRecipes
        } catch {
            print("❌ Error fetching saved recipes: \(error)")
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func unsaveRecipe(_ recipe: Recipe) async {
        do {
            print("🗑️ Starting delete operation for recipe: \(recipe.title)")
            // First update the UI
            recipes.removeAll { $0.id == recipe.id }
            
            // Then delete from backend
            try await savedRecipeService.unsaveRecipe(recipeId: recipe.id)
            print("✅ Successfully deleted recipe from backend")
            
            // Refresh the list to ensure sync
            await fetchSavedRecipes()
        } catch {
            print("❌ Error deleting recipe: \(error)")
            self.error = "Failed to delete recipe: \(error.localizedDescription)"
            // Refresh the list to ensure UI is in sync with backend
            await fetchSavedRecipes()
        }
    }
}
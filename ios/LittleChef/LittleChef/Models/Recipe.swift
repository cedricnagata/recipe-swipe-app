import Foundation

struct Recipe: Identifiable {
    let id: UUID
    let title: String
    let ingredients: [String: String]
    let steps: [String]
    let sourceUrl: String
    let images: [String?]
    
    var mainImage: String? {
        images.first ?? nil
    }
    
    var ingredientCount: Int {
        ingredients.count
    }
    
    var stepCount: Int {
        steps.count
    }
}

extension RecipeDTO {
    func toRecipe() -> Recipe {
        Recipe(
            id: id,
            title: title,
            ingredients: ingredients,
            steps: steps,
            sourceUrl: sourceUrl,
            images: images
        )
    }
}
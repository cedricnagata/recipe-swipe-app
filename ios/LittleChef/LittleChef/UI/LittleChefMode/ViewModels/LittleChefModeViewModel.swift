import Foundation
import SwiftUI

class LittleChefModeViewModel: ObservableObject {
    let recipe: Recipe
    @Published var currentStepIndex: Int = 0
    @Published var selectedTab: Int = 0
    @Published var showingFinishAlert: Bool = false
    @Published var currentServings: Int
    
    init(recipe: Recipe) {
        self.recipe = recipe
        self.currentServings = recipe.servings
    }
    
    var currentStep: String {
        guard currentStepIndex < recipe.steps.count else { return "" }
        return recipe.steps[currentStepIndex]
    }
    
    var nextStep: String? {
        guard currentStepIndex + 1 < recipe.steps.count else { return nil }
        return recipe.steps[currentStepIndex + 1]
    }
    
    var progress: CGFloat {
        guard !recipe.steps.isEmpty else { return 0 }
        return CGFloat(currentStepIndex) / CGFloat(recipe.steps.count - 1)
    }
    
    var servingsScaleFactor: Float {
        guard recipe.servings > 0 else { return 1.0 }
        return Float(currentServings) / Float(recipe.servings)
    }
    
    func scaledAmount(for ingredient: String) -> String {
        guard let amount = recipe.ingredients[ingredient] else { return "" }
        return IngredientAmount.parseAndScale(amount, by: servingsScaleFactor)
    }
    
    func moveToNextStep() {
        guard currentStepIndex < recipe.steps.count - 1 else {
            showingFinishAlert = true
            return
        }
        currentStepIndex += 1
    }
    
    func moveToPreviousStep() {
        guard currentStepIndex > 0 else { return }
        currentStepIndex -= 1
    }
    
    func updateServings(_ newValue: Int) {
        guard newValue > 0 else { return }
        currentServings = newValue
    }
}
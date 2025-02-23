import Foundation
import SwiftUI

@MainActor
class LittleChefModeViewModel: ObservableObject {
    @Published var recipe: Recipe
    @Published var selectedTab = 0
    @Published var currentStepIndex = 0
    @Published var currentServings: Int
    @Published var showingFinishAlert = false
    @Published var sessionId: UUID?
    @Published var suggestedActions: [StepAction] = []
    
    private let cookingSessionService = CookingSessionService()
    
    var currentStep: String {
        recipe.steps[currentStepIndex]
    }
    
    var nextStep: String? {
        guard currentStepIndex < recipe.steps.count - 1 else { return nil }
        return recipe.steps[currentStepIndex + 1]
    }
    
    init(recipe: Recipe) {
        self.recipe = recipe
        self.currentServings = recipe.servings
        
        // Create cooking session when initialized
        Task {
            do {
                let session = try await cookingSessionService.createSession(recipeId: recipe.id)
                self.sessionId = session.id
                // Get initial actions for first step
                await self.fetchStepActions()
            } catch {
                print("Error creating cooking session: \(error)")
            }
        }
    }
    
    func updateServings(_ newServings: Int) {
        currentServings = newServings
        objectWillChange.send()  // Force UI update
    }
    
    func scaledAmount(for ingredient: String) -> String {
        guard let originalAmount = recipe.ingredients[ingredient] else {
            return ""
        }
        
        // Extract numeric value and unit from the original amount
        let components = originalAmount.split(separator: " ", maxSplits: 1)
        guard let amountStr = components.first,
              let amount = Double(amountStr) else {
            return originalAmount // Return original if we can't parse the number
        }
        
        // Calculate the scaled amount
        let originalServings = recipe.servings
        let scaledAmount = amount * (Double(currentServings) / Double(originalServings))
        
        // Format the scaled amount
        let formattedAmount: String
        if scaledAmount.truncatingRemainder(dividingBy: 1) == 0 {
            // Whole number
            formattedAmount = String(format: "%.0f", scaledAmount)
        } else {
            // Decimal number, rounded to 2 places
            formattedAmount = String(format: "%.2f", scaledAmount)
        }
        
        // If there was a unit, add it back
        if components.count > 1 {
            return "\(formattedAmount) \(components[1])"
        } else {
            return formattedAmount
        }
    }
    
    func moveToNextStep() {
        guard currentStepIndex < recipe.steps.count - 1 else {
            showingFinishAlert = true
            return
        }
        
        currentStepIndex += 1
        Task {
            await fetchStepActions()
        }
    }
    
    func moveToPreviousStep() {
        guard currentStepIndex > 0 else { return }
        currentStepIndex -= 1
        Task {
            await fetchStepActions()
        }
    }
    
    func removeSuggestedAction(_ action: StepAction) {
        suggestedActions.removeAll { $0.id == action.id }
    }
    
    private func fetchStepActions() async {
        guard let sessionId = sessionId else { return }
        
        do {
            let actions = try await cookingSessionService.getStepActions(
                sessionId: sessionId,
                stepNumber: currentStepIndex
            )
            self.suggestedActions = actions
        } catch {
            print("Error fetching step actions: \(error)")
        }
    }
    
    @MainActor
    func cleanup() {
        guard let sessionId = sessionId else { return }
        
        Task {
            do {
                try await cookingSessionService.deleteSession(sessionId: sessionId)
            } catch {
                print("Error deleting cooking session: \(error)")
            }
        }
    }
}

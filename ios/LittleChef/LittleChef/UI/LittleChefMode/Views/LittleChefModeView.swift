import SwiftUI

struct LittleChefModeView: View {
    @StateObject private var viewModel: LittleChefModeViewModel
    @StateObject private var actionCoordinator = ActionCoordinator.shared
    @Environment(\.dismiss) private var dismiss
    
    init(recipe: Recipe) {
        _viewModel = StateObject(wrappedValue: LittleChefModeViewModel(recipe: recipe))
    }
    
    var body: some View {
        TabView(selection: $viewModel.selectedTab) {
            RecipeStepsView(viewModel: viewModel)
                .tag(0)
            
            ChefChatView(recipe: viewModel.recipe, sessionId: viewModel.sessionId)
                .tag(1)
            
            TimersView()
                .tag(2)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(viewModel.recipe.title)
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    viewModel.cleanup()
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
            }
        }
        .alert("Recipe Complete!", isPresented: $viewModel.showingFinishAlert) {
            Button("Finish") {
                viewModel.cleanup()
                dismiss()
            }
        } message: {
            Text("Congratulations! You've completed all the steps.")
        }
        .alert("Temperature Setting",
               isPresented: $actionCoordinator.showingTemperatureAlert,
               presenting: actionCoordinator.currentTemperatureAction) { action in
            Button("OK") {
                // Dismiss alert
                viewModel.removeSuggestedAction(action)
            }
        } message: { action in
            if let value = action.value {
                Text("Set \(action.appliance.lowercased()) to \(value)°F\n\n\(action.description)")
            }
        }
        .onChange(of: viewModel.selectedTab) { newTab in
            // If switching to timers tab, automatically start any pending timer
            if newTab == 2 {
                viewModel.suggestedActions
                    .filter { $0.type == .timer }
                    .forEach { actionCoordinator.handleAction($0) }
                viewModel.suggestedActions.removeAll()
            }
        }
    }
}

private struct RecipeStepsView: View {
    @ObservedObject var viewModel: LittleChefModeViewModel
    @ObservedObject var actionCoordinator = ActionCoordinator.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Suggested Actions
                if !viewModel.suggestedActions.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Suggested Actions")
                            .font(.headline)
                        
                        ForEach(viewModel.suggestedActions) { action in
                            DismissibleActionCard(action: action) {
                                actionCoordinator.handleAction(action)
                                if action.type == .timer {
                                    viewModel.removeSuggestedAction(action)
                                }
                            } onDismiss: {
                                viewModel.removeSuggestedAction(action)
                            }
                        }
                    }
                }
                
                // Current Step
                VStack(alignment: .leading, spacing: 12) {
                    Text("Current Step")
                        .font(.headline)
                    
                    Text(viewModel.currentStep)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }
                
                // Next Step
                if let nextStep = viewModel.nextStep {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Next Up")
                            .font(.headline)
                        
                        Text(nextStep)
                            .foregroundStyle(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                }
                
                // Step Navigation
                HStack {
                    Button(action: viewModel.moveToPreviousStep) {
                        Image(systemName: "chevron.left")
                            .imageScale(.large)
                            .frame(width: 44, height: 44)
                            .background(Color(.systemGray6))
                            .clipShape(Circle())
                    }
                    .disabled(viewModel.currentStepIndex == 0)
                    
                    Spacer()
                    
                    Button(action: viewModel.moveToNextStep) {
                        Image(systemName: "chevron.right")
                            .imageScale(.large)
                            .frame(width: 44, height: 44)
                            .background(Color(.systemGray6))
                            .clipShape(Circle())
                    }
                    .disabled(viewModel.currentStepIndex == viewModel.recipe.steps.count - 1)
                }
                
                // Servings Adjustment
                VStack(alignment: .leading, spacing: 12) {
                    Text("Servings")
                        .font(.headline)
                    
                    HStack {
                        Button {
                            viewModel.updateServings(viewModel.currentServings - 1)
                        } label: {
                            Image(systemName: "minus")
                                .frame(width: 44, height: 44)
                                .background(Color(.systemGray6))
                                .clipShape(Circle())
                        }
                        .disabled(viewModel.currentServings <= 1)
                        
                        Text("\(viewModel.currentServings)")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .frame(minWidth: 44)
                        
                        Button {
                            viewModel.updateServings(viewModel.currentServings + 1)
                        } label: {
                            Image(systemName: "plus")
                                .frame(width: 44, height: 44)
                                .background(Color(.systemGray6))
                                .clipShape(Circle())
                        }
                    }
                }
                
                // Ingredients
                VStack(alignment: .leading, spacing: 12) {
                    Text("Ingredients")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(viewModel.recipe.ingredients.keys.sorted()), id: \.self) { ingredient in
                            HStack {
                                Text(ingredient)
                                Spacer()
                                Text(viewModel.scaledAmount(for: ingredient))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
            }
            .padding()
        }
    }
}

struct DismissibleActionCard: View {
    let action: StepAction
    let onAccept: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        HStack {
            ActionCard(action: action, onAccept: onAccept)
            
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
                    .font(.title2)
            }
            .padding(.leading, 8)
        }
    }
}
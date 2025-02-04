import SwiftUI

struct LittleChefModeView: View {
    @StateObject private var viewModel: LittleChefModeViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(recipe: Recipe) {
        _viewModel = StateObject(wrappedValue: LittleChefModeViewModel(recipe: recipe))
    }
    
    var body: some View {
        TabView(selection: $viewModel.selectedTab) {
            RecipeStepsView(viewModel: viewModel)
                .tag(0)
            
            ChefChatView(recipe: viewModel.recipe)
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
                dismiss()
            }
        } message: {
            Text("Congratulations! You've completed all the steps.")
        }
    }
}

private struct RecipeStepsView: View {
    @ObservedObject var viewModel: LittleChefModeViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
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

private struct ChefChatView: View {
    let recipe: Recipe
    
    var body: some View {
        Color.clear
    }
}

private struct TimersView: View {
    var body: some View {
        Color.clear
    }
}

#Preview {
    NavigationStack {
        LittleChefModeView(recipe: Recipe(
            id: UUID(),
            title: "Test Recipe",
            ingredients: [
                "Flour": "2 cups",
                "Sugar": "1.5 cups",
                "Eggs": "3 large",
                "Salt": "1/2 tsp"
            ],
            steps: ["Step 1", "Step 2", "Step 3"],
            sourceUrl: "",
            images: [],
            isSaved: true,
            servings: 4,
            totalTime: 45
        ))
    }
}
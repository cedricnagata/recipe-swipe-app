import SwiftUI

struct LittleChefView: View {
    let recipe: Recipe?
    
    var body: some View {
        VStack(spacing: 20) {
            if let recipe = recipe {
                Text("Ready to cook \(recipe.title)?")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                Text("I'll guide you through each step")
                    .foregroundStyle(.secondary)
                
                Button(action: {
                    // TODO: Start cooking session
                }) {
                    Text("Start Cooking")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                }
            } else {
                Text("Choose a Recipe")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Select a recipe from your saved collection\nto start cooking with Little Chef")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                
                NavigationLink(destination: SavedRecipesView()) {
                    Text("Browse Saved Recipes")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                }
            }
        }
        .padding()
        .navigationTitle("Little Chef Mode")
    }
}

#Preview {
    NavigationStack {
        LittleChefView(recipe: nil)
    }
}
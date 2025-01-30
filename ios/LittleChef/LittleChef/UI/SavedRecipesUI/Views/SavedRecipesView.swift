import SwiftUI

struct SavedRecipesView: View {
    @StateObject private var viewModel = SavedRecipesViewModel()
    @State private var selectedRecipe: Recipe?
    @State private var showingCookingView = false
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
            } else if viewModel.recipes.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "heart.slash")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    
                    Text("No Saved Recipes")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Recipes you like will appear here")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else {
                List {
                    ForEach(viewModel.recipes) { recipe in
                        SavedRecipeCard(recipe: recipe) {
                            selectedRecipe = recipe
                            showingCookingView = true
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                    .onDelete { indexSet in
                        deleteRecipes(at: indexSet)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Saved Recipes")
        .onAppear {
            Task {
                await viewModel.fetchSavedRecipes()
            }
        }
        .sheet(isPresented: $showingCookingView) {
            if let recipe = selectedRecipe {
                CookingView(recipe: recipe)
            }
        }
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") {
                viewModel.error = nil
            }
        } message: {
            if let error = viewModel.error {
                Text(error)
            }
        }
    }
    
    private func deleteRecipes(at indexSet: IndexSet) {
        Task {
            for index in indexSet {
                await viewModel.unsaveRecipe(viewModel.recipes[index])
            }
        }
    }
}

struct SavedRecipeCard: View {
    let recipe: Recipe
    let onCookTapped: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if recipe.images.isEmpty || recipe.images.allSatisfy({ $0 == nil }) {
                // No photos placeholder
                VStack {
                    Image(systemName: "photo.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.gray.opacity(0.5))
                    Text("No photos available")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else if let firstImageUrl = recipe.images.first ?? nil,
                      let url = URL(string: firstImageUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(recipe.title)
                    .font(.headline)
                    .lineLimit(2)
                
                HStack {
                    Label("\(recipe.ingredientCount) ingredients", systemImage: "carrot")
                    Spacer()
                    Label("\(recipe.stepCount) steps", systemImage: "list.bullet")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                
                Button(action: onCookTapped) {
                    Label("Cook with Little Chef", systemImage: "figure.2.and.child.holdinghands")
                        .font(.callout)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.green)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(.horizontal, 4)
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(radius: 2, y: 1)
        }
    }
}

// Placeholder for our new cooking view
struct CookingView: View {
    let recipe: Recipe
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Ready to cook \(recipe.title)?")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .padding(.top)
                
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
                
                Spacer()
            }
            .padding()
            .navigationTitle("Little Chef")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SavedRecipesView()
    }
}
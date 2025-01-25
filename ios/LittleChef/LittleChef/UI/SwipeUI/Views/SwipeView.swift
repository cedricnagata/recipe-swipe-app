import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct SwipeView: View {
    @StateObject private var viewModel = SwipeViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            #if os(iOS)
            Color(.systemBackground)
                .ignoresSafeArea()
            #else
            Color(.white)
                .ignoresSafeArea()
            #endif
            
            VStack {
                if viewModel.isLoading {
                    ProgressView()
                } else if !viewModel.sessionStarted {
                    // Session start prompt
                    VStack(spacing: 20) {
                        Image(systemName: "rectangle.stack")
                            .font(.system(size: 60))
                            .foregroundStyle(.blue)
                        
                        Text("Ready to discover recipes?")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Start swiping to find new recipes\ntailored to your taste")
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                        
                        Button(action: {
                            Task {
                                await viewModel.startNewSession()
                            }
                        }) {
                            Text("Start Discovery Session")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .padding(.horizontal)
                        }
                    }
                } else if let recipe = viewModel.currentRecipe {
                    VStack {
                        // Session stats
                        if let stats = viewModel.sessionStats {
                            HStack {
                                Label("\(stats.seenRecipes) recipes seen", systemImage: "eye.fill")
                                Spacer()
                                Button("End Session") {
                                    Task {
                                        await viewModel.endSession()
                                        dismiss()
                                    }
                                }
                                .foregroundStyle(.red)
                            }
                            .font(.caption)
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                        }
                        
                        // Recipe card
                        RecipeCardView(recipe: recipe) { swipedRight in
                            Task {
                                if swipedRight {
                                    await viewModel.swipeRight()
                                } else {
                                    await viewModel.swipeLeft()
                                }
                            }
                        }
                        .animation(.default, value: recipe.id)
                        .id(recipe.id)  // Force view refresh on recipe change
                    }
                } else {
                    VStack(spacing: 16) {
                        Text("No more recipes")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        
                        Button("End Session") {
                            Task {
                                await viewModel.endSession()
                                dismiss()
                            }
                        }
                        .foregroundStyle(.red)
                    }
                }
            }
        }
        .navigationTitle("Recipe Discovery")
        .navigationBarTitleDisplayMode(.inline)
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
}

#Preview {
    NavigationStack {
        SwipeView()
    }
}
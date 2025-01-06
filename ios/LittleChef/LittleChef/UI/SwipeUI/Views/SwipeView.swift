import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct SwipeView: View {
    @StateObject private var viewModel = SwipeViewModel()
    
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
                } else if let recipe = viewModel.currentRecipe {
                    RecipeCardView(recipe: recipe) { swipedRight in
                        if swipedRight {
                            viewModel.swipeRight()
                        } else {
                            viewModel.swipeLeft()
                        }
                    }
                    .animation(.default, value: recipe.id)
                    .id(recipe.id)  // Force view refresh on recipe change
                } else {
                    Text("No more recipes")
                        .foregroundColor(.gray)
                }
            }
        }
        .onAppear {
            viewModel.fetchNextRecipe()
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
}
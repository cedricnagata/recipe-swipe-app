import SwiftUI

struct RecipeDetailView: View {
    let recipe: Recipe
    @Environment(\.dismiss) private var dismiss
    @State private var currentImageIndex = 0
    
    var timeFormatted: String {
        guard let time = recipe.totalTime else { return "" }
        if time >= 60 {
            let hours = time / 60
            let minutes = time % 60
            if minutes == 0 {
                return "\(hours)h"
            }
            return "\(hours)h \(minutes)m"
        }
        return "\(time)m"
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Image Carousel
                TabView(selection: $currentImageIndex) {
                    ForEach(recipe.images.indices, id: \.self) { index in
                        if let imageUrl = recipe.images[index] {
                            AsyncImage(url: URL(string: imageUrl)) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                ProgressView()
                            }
                        }
                    }
                }
                .tabViewStyle(.page)
                .frame(height: 300)
                
                VStack(alignment: .leading, spacing: 24) {
                    // Title
                    Text(recipe.title)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    // Recipe Info
                    HStack(spacing: 16) {
                        HStack {
                            Image(systemName: "person.2.fill")
                            Text("\(recipe.servings) servings")
                        }
                        
                        if let _ = recipe.totalTime {
                            HStack {
                                Image(systemName: "clock.fill")
                                Text(timeFormatted)
                            }
                        }
                        
                        Spacer()
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    
                    // Ingredients Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Ingredients")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        ForEach(Array(recipe.ingredients.keys.sorted()), id: \.self) { ingredient in
                            HStack(alignment: .top) {
                                Text("•")
                                    .padding(.trailing, 4)
                                Text(ingredient)
                                    .fontWeight(.medium)
                                Spacer()
                                Text(recipe.ingredients[ingredient] ?? "")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    // Steps Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Instructions")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        ForEach(Array(recipe.steps.enumerated()), id: \.offset) { index, step in
                            HStack(alignment: .top) {
                                Text("\(index + 1).")
                                    .fontWeight(.bold)
                                    .foregroundColor(.secondary)
                                    .frame(width: 28, alignment: .leading)
                                Text(step)
                            }
                            .padding(.bottom, 8)
                        }
                    }
                    
                    // Source Attribution
                    if let url = URL(string: recipe.sourceUrl) {
                        Link(destination: url) {
                            Text("View Original Recipe")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                    }
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.gray)
                }
            }
        }
    }
}
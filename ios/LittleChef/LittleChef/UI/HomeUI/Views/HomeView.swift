import SwiftUI

struct HomeView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Little Chef")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("Your AI-powered cooking companion")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top)
                
                // Main Actions Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    // Recipe Discovery
                    NavigationLink(destination: SwipeView()) {
                        HomeActionCard(
                            title: "Recipe Discovery",
                            subtitle: "Swipe to find new recipes",
                            iconName: "rectangle.on.rectangle.angled",
                            color: .blue
                        )
                    }
                    
                    // Saved Recipes
                    NavigationLink(destination: SavedRecipesView()) {
                        HomeActionCard(
                            title: "Saved Recipes",
                            subtitle: "Your recipe collection",
                            iconName: "heart.fill",
                            color: .red
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct HomeActionCard: View {
    let title: String
    let subtitle: String
    let iconName: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: iconName)
                .font(.title)
                .foregroundColor(color)
                .frame(width: 40, height: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: 140)
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(radius: 2, y: 1)
        }
    }
}

#Preview {
    HomeView()
}
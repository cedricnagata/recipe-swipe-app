import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct RecipeCardView: View {
    let recipe: Recipe
    let onSwiped: (_ right: Bool) -> Void
    
    @State private var currentImageIndex = 0
    @State private var offset = CGSize.zero
    @State private var color = Color.black.opacity(0)
    @State private var showingDetail = false
    
    #if os(iOS)
    private let cardWidth: CGFloat = UIScreen.main.bounds.width - 40
    private let cardHeight: CGFloat = UIScreen.main.bounds.height * 0.55
    #else
    private let cardWidth: CGFloat = 300
    private let cardHeight: CGFloat = 400
    #endif
    
    private let swipeThreshold: CGFloat = 120
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white)
                .shadow(radius: 10)
            
            VStack(spacing: 0) {
                // Image carousel
                TabView(selection: $currentImageIndex) {
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
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.gray.opacity(0.1))
                    } else {
                        ForEach(recipe.images.indices, id: \.self) { index in
                            if let imageUrl = recipe.images[index],
                               let url = URL(string: imageUrl) {
                                GeometryReader { geometry in
                                    AsyncImage(url: url) { image in
                                        ZStack {
                                            Color(.systemGray6)
                                            image
                                                .resizable()
                                                .scaledToFit()
                                                .frame(maxWidth: geometry.size.width, maxHeight: geometry.size.height)
                                        }
                                    } placeholder: {
                                        ProgressView()
                                    }
                                }
                            }
                        }
                    }
                }
                #if os(iOS)
                .tabViewStyle(PageTabViewStyle())
                #endif
                .frame(height: cardHeight * 0.6)
                .clipShape(RoundedRectangle(cornerRadius: 15))
                
                // Recipe details
                VStack(alignment: .leading, spacing: 8) {
                    Text(recipe.title)
                        .font(.title3)
                        .fontWeight(.bold)
                        .lineLimit(2)
                    
                    HStack(spacing: 16) {
                        Text("\(recipe.ingredientCount) ingredients")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Text("\(recipe.stepCount) steps")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Like/Dislike symbols
            HStack {
                Text("✗")
                    .font(.system(size: 48))
                    .opacity(Double(max(-offset.width, 0)) / 100)
                    .foregroundColor(.red)
                
                Spacer()
                
                Text("♥︎")
                    .font(.system(size: 48))
                    .opacity(Double(max(offset.width, 0)) / 100)
                    .foregroundColor(.green)
            }
            .padding(30)
        }
        .frame(width: cardWidth, height: cardHeight)
        .offset(x: offset.width, y: offset.height)
        .rotationEffect(.degrees(Double(offset.width / 40)))
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    offset = gesture.translation
                    withAnimation {
                        color = offset.width > 0 ? .green : .red
                    }
                }
                .onEnded { _ in
                    withAnimation {
                        swipeCard(width: offset.width)
                        color = .black.opacity(0)
                    }
                }
        )
        .onTapGesture {
            showingDetail = true
        }
        .sheet(isPresented: $showingDetail) {
            NavigationView {
                RecipeDetailView(recipe: recipe)
            }
        }
    }
    
    private func swipeCard(width: CGFloat) {
        switch width {
        case let x where x > swipeThreshold:
            offset = CGSize(width: cardWidth * 2, height: 0)
            onSwiped(true)
        case let x where x < -swipeThreshold:
            offset = CGSize(width: -cardWidth * 2, height: 0)
            onSwiped(false)
        default:
            offset = .zero
        }
    }
}
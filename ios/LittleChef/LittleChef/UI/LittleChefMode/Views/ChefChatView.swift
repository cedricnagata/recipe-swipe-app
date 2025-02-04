import SwiftUI

struct ChefChatView: View {
    @StateObject private var viewModel: ChefChatViewModel
    @FocusState private var isFocused: Bool
    
    init(recipe: Recipe) {
        _viewModel = StateObject(wrappedValue: ChefChatViewModel(recipe: recipe))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                        
                        if viewModel.isLoading {
                            TypingIndicator()
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) { _ in
                    if let lastMessageId = viewModel.messages.last?.id {
                        withAnimation {
                            proxy.scrollTo(lastMessageId, anchor: .bottom)
                        }
                    }
                }
            }
            
            Divider()
            
            // Input Area
            HStack(spacing: 12) {
                TextField("Ask Little Chef...", text: $viewModel.inputMessage, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .focused($isFocused)
                    .lineLimit(1...5)
                
                Button(action: {
                    viewModel.sendMessage()
                    isFocused = false
                }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(
                            viewModel.inputMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? Color.secondary
                            : Color.blue
                        )
                }
                .disabled(viewModel.inputMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
        }
        .onTapGesture {
            isFocused = false
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.sender == .user {
                Spacer(minLength: 60)
            }
            
            VStack(alignment: message.sender == .user ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(12)
                    .background(message.sender == .user ? Color.blue : Color(.systemGray5))
                    .foregroundColor(message.sender == .user ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                
                // Optional: Add timestamp
                Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if message.sender == .assistant {
                Spacer(minLength: 60)
            }
        }
    }
}

struct TypingIndicator: View {
    @State private var animationStep = 0
    
    var body: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color(.systemGray3))
                        .frame(width: 6, height: 6)
                        .scaleEffect(animationStep == index ? 1.2 : 1)
                        .animation(.easeInOut(duration: 0.3), value: animationStep)
                }
            }
            .padding(12)
            .background(Color(.systemGray5))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            
            Spacer()
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { timer in
                animationStep = (animationStep + 1) % 3
            }
        }
    }
}

#Preview {
    NavigationStack {
        ChefChatView(recipe: Recipe(
            id: UUID(),
            title: "Test Recipe",
            ingredients: ["Ingredient": "1 cup"],
            steps: ["Step 1"],
            sourceUrl: "",
            images: [],
            isSaved: true,
            servings: 4,
            totalTime: 30
        ))
    }
}
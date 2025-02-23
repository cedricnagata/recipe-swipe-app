import SwiftUI

struct ChefChatView: View {
    @StateObject private var viewModel: ChefChatViewModel
    @StateObject private var actionCoordinator = ActionCoordinator.shared
    @FocusState private var isFocused: Bool
    
    init(recipe: Recipe, sessionId: UUID?) {
        _viewModel = StateObject(wrappedValue: ChefChatViewModel(recipe: recipe, sessionId: sessionId))
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
                        
                        if !viewModel.suggestedActions.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Suggested Actions")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                ForEach(viewModel.suggestedActions) { action in
                                    ActionCard(action: action) {
                                        actionCoordinator.handleAction(action)
                                        // Remove timer action after handling
                                        if action.type == .timer {
                                            viewModel.suggestedActions.removeAll { $0.id == action.id }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.vertical)
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
        .alert("Temperature Setting",
               isPresented: $actionCoordinator.showingTemperatureAlert,
               presenting: actionCoordinator.currentTemperatureAction) { action in
            Button("OK") {
                // Dismiss alert
            }
        } message: { action in
            if let value = action.value {
                Text("Set \(action.appliance.lowercased()) to \(value)°F\n\n\(action.description)")
            }
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
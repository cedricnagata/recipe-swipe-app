import SwiftUI

struct TimersView: View {
    @StateObject private var viewModel = TimerViewModel()
    @State private var showingAddTimer = false
    @State private var selectedAppliance: KitchenAppliance = .other
    @State private var timerLabel = ""
    @State private var timerDuration: Double = 5
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Active Timers
                ForEach(viewModel.timers) { timer in
                    TimerCard(timer: timer) { action in
                        switch action {
                        case .toggle:
                            viewModel.toggleTimer(timer.id)
                        case .reset:
                            viewModel.resetTimer(timer.id)
                        case .delete:
                            viewModel.deleteTimer(timer.id)
                        }
                    }
                }
                
                // Add Timer Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Add Timer")
                        .font(.headline)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(KitchenAppliance.allCases, id: \.self) { appliance in
                                Button {
                                    selectedAppliance = appliance
                                    showingAddTimer = true
                                } label: {
                                    VStack(spacing: 8) {
                                        Text(appliance.icon)
                                            .font(.system(size: 32))
                                        Text(appliance.displayName)
                                            .font(.caption)
                                    }
                                    .frame(width: 80, height: 80)
                                    .background(Color(.systemGray6))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
                .padding()
                .background(Color(.systemGray6).opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding()
        }
        .sheet(isPresented: $showingAddTimer) {
            NavigationStack {
                Form {
                    Section("Timer Details") {
                        TextField("Timer Label", text: $timerLabel)
                        
                        Stepper(value: $timerDuration, in: 0.5...180, step: 0.5) {
                            HStack {
                                Text("Duration")
                                Spacer()
                                Text(formatDuration(timerDuration))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .navigationTitle("New \(selectedAppliance.displayName) Timer")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showingAddTimer = false
                        }
                    }
                    
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") {
                            viewModel.addTimer(
                                appliance: selectedAppliance,
                                label: timerLabel.isEmpty ? "Timer" : timerLabel,
                                minutes: timerDuration
                            )
                            showingAddTimer = false
                            timerLabel = ""
                            timerDuration = 5
                        }
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }
    
    private func formatDuration(_ minutes: Double) -> String {
        let hours = Int(minutes) / 60
        let mins = Int(minutes) % 60
        
        if hours > 0 {
            return "\(hours)h \(mins)m"
        } else {
            return "\(Int(minutes))m"
        }
    }
}

struct TimerCard: View {
    let timer: KitchenTimer
    let onAction: (TimerAction) -> Void
    
    enum TimerAction {
        case toggle
        case reset
        case delete
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Text(timer.appliance.icon)
                Text(timer.appliance.displayName)
                    .font(.headline)
                Spacer()
                
                Menu {
                    Button(role: .destructive) {
                        onAction(.delete)
                    } label: {
                        Label("Delete Timer", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
            
            // Timer Display
            HStack {
                Text(timer.label)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(timer.timeRemaining.timerDisplay)
                    .monospacedDigit()
                    .foregroundColor(timer.isComplete ? .red : .primary)
            }
            
            // Controls
            HStack {
                Button {
                    onAction(.toggle)
                } label: {
                    Text(timer.isRunning ? "Pause" : "Start")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(timer.isRunning ? Color.orange : Color.green)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                Button {
                    onAction(.reset)
                } label: {
                    Text("Reset")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray5))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 2, y: 1)
    }
}
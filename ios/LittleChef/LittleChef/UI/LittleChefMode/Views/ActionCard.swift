import SwiftUI

struct ActionCard: View {
    let action: StepAction
    let onAccept: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: action.type == .timer ? "timer" : "thermometer")
                    .font(.title2)
                Text(action.type == .timer ? "Timer" : "Temperature")
                    .font(.headline)
                Spacer()
            }
            
            // Content
            Text(action.description)
                .foregroundStyle(.secondary)
            
            // Details
            if action.type == .timer {
                HStack {
                    Image(systemName: action.appliance == "OVEN" ? "oven" : 
                                    action.appliance == "STOVE" ? "cooktop" : "timer")
                    Text("\(action.duration ?? 0) minutes")
                }
                .foregroundStyle(.secondary)
            } else {
                HStack {
                    Image(systemName: action.appliance == "OVEN" ? "oven" : "cooktop")
                    Text("\(action.value ?? 0)°F")
                }
                .foregroundStyle(.secondary)
            }
            
            // Button
            Button(action: onAccept) {
                Text(action.type == .timer ? "Start Timer" : "Got it")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 2, y: 1)
    }
}
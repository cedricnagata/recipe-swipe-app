import Foundation
import SwiftUI

enum KitchenAppliance: String, CaseIterable {
    case oven = "oven"
    case stovetop = "stovetop"
    case microwave = "microwave"
    case airFryer = "airFryer"
    case presureCooker = "presureCooker"
    case riceCooker = "riceCooker"
    case other = "other"
    
    var icon: String {
        switch self {
        case .oven: return "🎛️"
        case .stovetop: return "🔥"
        case .microwave: return "⚡️"
        case .airFryer: return "💨"
        case .presureCooker: return "♨️"
        case .riceCooker: return "🍚"
        case .other: return "⏲️"
        }
    }
    
    var displayName: String {
        switch self {
        case .airFryer: return "Air Fryer"
        case .presureCooker: return "Pressure Cooker"
        case .riceCooker: return "Rice Cooker"
        default: return rawValue.capitalized
        }
    }
}

struct KitchenTimer: Identifiable {
    let id = UUID()
    let appliance: KitchenAppliance
    var label: String
    var duration: TimeInterval
    var timeRemaining: TimeInterval
    var isRunning: Bool
    var isComplete: Bool
    
    mutating func tick() {
        guard isRunning, !isComplete else { return }
        
        if timeRemaining > 0 {
            timeRemaining -= 1
        }
        
        if timeRemaining == 0 {
            isComplete = true
            isRunning = false
        }
    }
}

class TimerViewModel: ObservableObject {
    @Published var timers: [KitchenTimer] = []
    private var timer: Timer?
    
    init() {
        startTick()
    }
    
    private func startTick() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateTimers()
        }
    }
    
    private func updateTimers() {
        for index in timers.indices {
            timers[index].tick()
        }
    }
    
    func addTimer(appliance: KitchenAppliance, label: String, minutes: Double) {
        let duration = minutes * 60
        let newTimer = KitchenTimer(
            appliance: appliance,
            label: label,
            duration: duration,
            timeRemaining: duration,
            isRunning: false,
            isComplete: false
        )
        timers.append(newTimer)
    }
    
    func toggleTimer(_ id: UUID) {
        guard let index = timers.firstIndex(where: { $0.id == id }) else { return }
        timers[index].isRunning.toggle()
        
        // Reset complete status if restarting
        if timers[index].isRunning && timers[index].isComplete {
            timers[index].isComplete = false
            timers[index].timeRemaining = timers[index].duration
        }
    }
    
    func resetTimer(_ id: UUID) {
        guard let index = timers.firstIndex(where: { $0.id == id }) else { return }
        timers[index].timeRemaining = timers[index].duration
        timers[index].isComplete = false
        timers[index].isRunning = false
    }
    
    func deleteTimer(_ id: UUID) {
        timers.removeAll(where: { $0.id == id })
    }
    
    deinit {
        timer?.invalidate()
    }
}

extension TimeInterval {
    var timerDisplay: String {
        let hours = Int(self) / 3600
        let minutes = Int(self) / 60 % 60
        let seconds = Int(self) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}
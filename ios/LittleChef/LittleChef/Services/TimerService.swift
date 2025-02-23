import Foundation

class TimerService: ObservableObject {
    static let shared = TimerService()
    @Published var timers: [KitchenTimer] = []
    private var timer: Timer?
    
    private init() {
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
    
    func addTimer(from action: StepAction, autoStart: Bool = true) -> KitchenTimer? {
        guard action.type == .timer,
              let duration = action.duration else {
            return nil
        }
        
        // Convert minutes to seconds
        let durationInSeconds = TimeInterval(duration * 60)
        
        // Determine appliance type from action
        let applianceStr = action.appliance.lowercased()
        let appliance: KitchenAppliance
        switch applianceStr {
        case "oven":
            appliance = .oven
        case "stove", "stovetop":
            appliance = .stovetop
        default:
            appliance = .other
        }
        
        let newTimer = KitchenTimer(
            appliance: appliance,
            label: action.label ?? action.description,
            duration: durationInSeconds,
            timeRemaining: durationInSeconds,
            isRunning: autoStart,  // Start automatically if requested
            isComplete: false
        )
        
        timers.append(newTimer)
        return newTimer
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
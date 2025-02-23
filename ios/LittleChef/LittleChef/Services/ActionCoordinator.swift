import SwiftUI

class ActionCoordinator: ObservableObject {
    static let shared = ActionCoordinator()
    
    @Published var showingTemperatureAlert = false
    @Published var currentTemperatureAction: StepAction?
    
    private let timerService = TimerService.shared
    
    private init() {}
    
    func handleAction(_ action: StepAction) {
        switch action.type {
        case .timer:
            if let timer = timerService.addTimer(from: action) {
                print("Created timer: \(timer.label)")
            }
        case .temperature:
            currentTemperatureAction = action
            showingTemperatureAlert = true
        }
    }
}
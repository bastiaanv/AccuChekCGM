import Combine
import HealthKit
import LoopKit
import SwiftUI

class SettingsViewModel: ObservableObject {
    @Published var connected: Bool = false
    @Published var deviceName: String = ""
    @Published var lastMeasurement = HKQuantity(unit: .milligramsPerDeciliter, doubleValue: 0)
    @Published var lastMeasurementDatetime: String = ""
    @Published var sensorAgeProcess: Double = 0
    @Published var sensorAgeDays: Double = 0
    @Published var sensorAgeHours: Double = 0
    @Published var sensorAgeMinutes: Double = 0
    @Published var notifications: [NotificationContent] = []

    @Published var isSharePresented = false
    @Published var showingDeleteConfirmation = false

    private let timeFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter
    }()

    private let logger = AccuChekLogger(category: "SettingsViewModel")
    private let cgmManager: AccuChekCgmManager?
    let deleteCGM: () -> Void
    init(_ cgmManager: AccuChekCgmManager?, deleteCGM: @escaping () -> Void) {
        self.cgmManager = cgmManager
        self.deleteCGM = deleteCGM

        guard let cgmManager = cgmManager else {
            return
        }

        stateDidUpdate(cgmManager.state)
        cgmManager.addStateObserver(state: self, queue: DispatchQueue.main)
    }

    func getLogs() -> [URL] {
        if let cgmManager = self.cgmManager {
            logger.info(cgmManager.state.debugDescription)
        }
        return logger.getDebugLogs()
    }
}

extension SettingsViewModel: StateObserver {
    func stateDidUpdate(_ state: AccuChekState) {
        connected = state.isConnected
        deviceName = state.deviceName ?? ""
        notifications = state.cgmStatus.compactMap(\.notification)

        if let glucose = state.lastGlucoseValue {
            lastMeasurement = HKQuantity(unit: .milligramsPerDeciliter, doubleValue: Double(glucose))
        }

        if let date = state.lastGlucoseDate {
            lastMeasurementDatetime = timeFormatter.string(from: date)
        }

        if let cgmStartTime = state.cgmStartTime, let cgmEndTime = state.cgmEndTime {
            let sensorAge = cgmEndTime.timeIntervalSinceNow

            sensorAgeProcess = min(cgmStartTime.timeIntervalSinceNow * -1 / .days(14), 1)

            sensorAgeDays = max(floor(sensorAge / .days(1)), 0)
            sensorAgeHours = max(sensorAge.truncatingRemainder(dividingBy: .days(1)) / .hours(1), 0)
            sensorAgeMinutes = max(sensorAge.truncatingRemainder(dividingBy: .hours(1)) / .minutes(1), 0)
        }
    }
}

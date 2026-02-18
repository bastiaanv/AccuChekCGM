import Combine
import HealthKit
import LoopKit
import SwiftUI

enum CGMState {
    case warmingup
    case active
    case expired
}

class SettingsViewModel: ObservableObject {
    @Published var cgmState = CGMState.warmingup
    @Published var connected: Bool = false
    @Published var deviceName: String = ""
    @Published var lastMeasurement = HKQuantity(unit: .milligramsPerDeciliter, doubleValue: 0)
    @Published var lastMeasurementDatetime: String = ""
    @Published var sensorStartedAt: String = ""
    @Published var sensorEndsAt: String = ""
    @Published var sensorAgeProcess: Double = 0
    @Published var sensorAgeDays: Double = 0
    @Published var sensorAgeHours: Double = 0
    @Published var sensorAgeMinutes: Double = 0
    @Published var sensorWarmupProgress: Double = 0
    @Published var sensorWarmupMinutes: Double = 0
    @Published var notifications: [NotificationContent] = []

    @Published var isSharePresented = false
    @Published var showingDeleteConfirmation = false
    @Published var showingRepairConfirmation = false

    private let dateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .medium
        return formatter
    }()

    private let timeFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter
    }()

    private let logger = AccuChekLogger(category: "SettingsViewModel")
    private let cgmManager: AccuChekCgmManager?
    let doCalibration: () -> Void
    private let doPairing: () -> Void
    let deleteCGM: () -> Void
    init(_ cgmManager: AccuChekCgmManager?, doCalibration: @escaping () -> Void, doPairing: @escaping () -> Void, deleteCGM: @escaping () -> Void) {
        self.cgmManager = cgmManager
        self.doCalibration = doCalibration
        self.doPairing = doPairing
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

    func pairNewCGM() {
        guard let cgmManager else {
            logger.error("No CGMManager")
            return
        }

        cgmManager.cleanup()
        doPairing()
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

        guard let cgmStartTime = state.cgmStartTime, let cgmEndTime = state.cgmEndTime else {
            return
        }

        let warmupEnd = cgmStartTime.addingTimeInterval(.hours(1))
        sensorStartedAt = dateFormatter.string(from: cgmStartTime)
        sensorEndsAt = dateFormatter.string(from: cgmEndTime)

        if cgmEndTime < Date.now {
            cgmState = .expired

        } else if warmupEnd > Date.now {
            let warmupAge = warmupEnd.timeIntervalSinceNow

            cgmState = .warmingup
            sensorWarmupProgress = min(cgmStartTime.timeIntervalSinceNow * -1 / .hours(1), 1)
            sensorWarmupMinutes = max(warmupAge / .minutes(1), 0)

        } else {
            cgmState = .active

            sensorAgeProcess = min(cgmStartTime.timeIntervalSinceNow * -1 / .days(14), 1)

            let sensorAge = cgmEndTime.timeIntervalSinceNow
            sensorAgeDays = max(floor(sensorAge / .days(1)), 0)
            sensorAgeHours = max(sensorAge.truncatingRemainder(dividingBy: .days(1)) / .hours(1), 0)
            sensorAgeMinutes = max(sensorAge.truncatingRemainder(dividingBy: .hours(1)) / .minutes(1), 0)
        }
    }
}

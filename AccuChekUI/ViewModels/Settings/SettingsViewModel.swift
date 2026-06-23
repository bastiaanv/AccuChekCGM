import Combine
import HealthKit
import LoopKit
import SwiftUI

class SettingsViewModel: ObservableObject {
    @Published var cgmState = CGMState.warmingUp
    @Published var connected: Bool = false
    @Published var deviceSerialNumber: String = ""
    @Published var lastMeasurement = HKQuantity(unit: .milligramsPerDeciliter, doubleValue: 0)
    @Published var lastMeasurementDatetime: String = ""
    @Published var nextCalibrationDate: String? = nil
    @Published var sensorStartedAt: String = ""
    @Published var sensorEndsAt: String = ""
    @Published var sensorModel: String = ""
    @Published var firmwareRevision: String = ""
    @Published var hardwareRevision: String = ""
    @Published var softwareRevision: String = ""
    @Published var sensorAgeProcess: Double = 0
    @Published var sensorAgeDays: Double = 0
    @Published var sensorAgeHours: Double = 0
    @Published var sensorAgeMinutes: Double = 0
    @Published var sensorWarmupProgress: Double = 0
    @Published var sensorWarmupMinutes: Double = 0
    @Published var notifications: [NotificationContent] = []
    @Published var readingsUnavailable: Bool = false
    @Published var calibrationAvailable: Bool = false
    @Published var calibrationPhase: CalibrationPhase = .done
    @Published var calibrationConfirmed: Bool = false
    @Published var isSharePresented = false
    @Published var showingDeleteConfirmation = false
    @Published var showingRepairConfirmation = false

    // Simulator-only
    @Published var demoStatus: SensorStatusDisplay? = nil

    private let timeFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    private let dateTimeFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    private let logger = AccuChekLogger(category: "SettingsViewModel")
    private let cgmManager: AccuChekCgmManager
    let doCalibration: () -> Void
    private let doPairing: () -> Void
    let deleteCGM: () -> Void
    init(
        _ cgmManager: AccuChekCgmManager,
        doCalibration: @escaping () -> Void,
        doPairing: @escaping () -> Void,
        deleteCGM: @escaping () -> Void
    ) {
        self.cgmManager = cgmManager
        self.doCalibration = doCalibration
        self.doPairing = doPairing
        self.deleteCGM = deleteCGM

        stateDidUpdate(cgmManager.state)
        cgmManager.addStateObserver(state: self, queue: DispatchQueue.main)
    }

    deinit {
        cgmManager.removeStateObserver(state: self)
    }

    var sensorStatus: SensorStatusDisplay {
        if let demoStatus {
            return demoStatus
        }

        func hasNotification(_ type: SensorStatusEnum) -> Bool {
            notifications.contains { $0.type == type }
        }

        if !connected {
            return .connecting
        }
        if cgmState == .expired || hasNotification(.sessionStopped) {
            return .expired
        }
        if hasNotification(.generalDeviceFaultOccuredInSensor) {
            return .malfunction
        }
        if readingsUnavailable && cgmState != .warmingUp {
            return .readingsUnavailable
        }
        if hasNotification(.deviceBatteryLow) {
            return .batteryLow
        }
        if hasNotification(.sensorTemperatureTooHigh) || hasNotification(.sensorTemperatureTooLow) {
            return .temperature
        }

        let calibrationDue = calibrationAvailable && calibrationConfirmed

        switch calibrationPhase {
        case .warmingup:
            return .trendMode(calibrationDue: calibrationDue)
        case .calibratedOnce:
            return .therapyMode(calibrationDue: calibrationDue)
        case .done:
            return cgmState == .warmingUp ? .trendMode(calibrationDue: false) : .ok
        }
    }

    func getLogs() -> [URL] {
        logger.info(cgmManager.state.debugDescription)
        return logger.getDebugLogs()
    }

    func pairNewCGM() {
        cgmManager.cleanup()
        doPairing()
    }
}

extension SettingsViewModel: StateObserver {
    func stateDidUpdate(_ state: AccuChekState) {
        connected = state.isConnected
        readingsUnavailable = state.readingsUnavailable
        notifications = state.cgmStatus.compactMap(\.notification)
        calibrationPhase = state.calibrationPhase
        calibrationConfirmed = state.cgmStatus.contains(.calibrationRecommended)
            || state.cgmStatus.contains(.calibrationRequired)

        if let sensorInfo = state.sensorInfo {
            sensorModel = sensorInfo.model
            deviceSerialNumber = "(21) " + sensorInfo.serialNumber
            firmwareRevision = sensorInfo.firmwareRevision
            hardwareRevision = sensorInfo.hardwareRevision
            softwareRevision = sensorInfo.softwareRevision
        }

        if let glucose = state.lastGlucoseValue {
            lastMeasurement = HKQuantity(unit: .milligramsPerDeciliter, doubleValue: Double(glucose))
        }

        if let date = state.lastGlucoseDate {
            lastMeasurementDatetime = timeFormatter.string(from: date)
        }

        if let nextCalibrationAt = state.nextCalibrationAt {
            nextCalibrationDate = dateTimeFormatter.string(from: nextCalibrationAt)
            calibrationAvailable = Date.now >= nextCalibrationAt
        } else {
            nextCalibrationDate = nil
            calibrationAvailable = false
        }

        guard let cgmStartTime = state.cgmStartTime, let cgmEndTime = state.cgmEndTime else {
            return
        }

        let warmupEnd = cgmStartTime.addingTimeInterval(.hours(1))
        sensorStartedAt = dateTimeFormatter.string(from: cgmStartTime)
        sensorEndsAt = dateTimeFormatter.string(from: cgmEndTime)

        if cgmEndTime < Date.now {
            cgmState = .expired

        } else if warmupEnd > Date.now {
            let warmupAge = warmupEnd.timeIntervalSinceNow

            cgmState = .warmingUp
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

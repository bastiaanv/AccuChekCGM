import Combine
import HealthKit
import SwiftUI

class CalibrationViewModel: ObservableObject {
    @Published var glucose: UInt16
    @Published var time = Date.now
    @Published var isLoading = false
    @Published var error = ""

    let allowedGlucoseValuesMgDl = Array(UInt16(60) ... UInt16(400))
    let allowedGlucoseValuesMmolL = Array(UInt16(33) ... UInt16(220))

    private let logger = AccuChekLogger(category: "CalibrationViewModel")
    private let cgmManager: AccuChekCgmManager?
    private let done: () -> Void
    private let unit: HKUnit
    init(cgmManager: AccuChekCgmManager?, _ unit: HKUnit, _ done: @escaping () -> Void) {
        self.cgmManager = cgmManager
        self.unit = unit
        self.done = done
        glucose = unit == .milligramsPerDeciliter ? 100 : 56
    }

    func calibrate() {
        guard let cgmManager = cgmManager else {
            logger.warning("No CGMManager...")
            return
        }

        error = ""
        isLoading = true

        var glucose = glucose
        if unit == .millimolesPerLiter {
            let mgdl = HKQuantity(unit: unit, doubleValue: Double(glucose) / 10).doubleValue(for: .milligramsPerDeciliter)
            glucose = UInt16(mgdl)
        }

        Task {
            do {
                await MainActor.run {
                    self.isLoading = false
                    self.done()
                }
            } catch {
                logger.error("Error during calibration: \(error)")

                await MainActor.run {
                    self.error = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
}

import Combine
import HealthKit
import SwiftUI

class CalibrationViewModel: ObservableObject {
    @Published var glucose: UInt16
    @Published var isLoading = false
    @Published var isError = false

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

        isError = false
        isLoading = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            var glucose = glucose
            if unit == .millimolesPerLiter {
                let mgdl = HKQuantity(unit: unit, doubleValue: Double(glucose) / 10).doubleValue(for: .milligramsPerDeciliter)
                glucose = UInt16(mgdl)
            }
            
            let success = cgmManager.calibrateSensor(glucose: glucose)
            DispatchQueue.main.async {
                self.isLoading = false
                if success {
                    self.done()
                } else {
                    self.isError = true
                }
            }
        }
    }
}

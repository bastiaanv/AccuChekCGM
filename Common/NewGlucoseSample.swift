import LoopKit
import LoopAlgorithm

extension NewGlucoseSample {
    init(cgmManager: AccuChekCgmManager, value: UInt16, condition: GlucoseCondition?, trend: GlucoseTrend?, dateTime: Date) {
        self.init(
            date: dateTime,
            quantity: LoopQuantity(unit: .milligramsPerDeciliter, doubleValue: Double(value)),
            condition: condition,
            trend: trend,
            trendRate: nil,
            isDisplayOnly: false,
            wasUserEntered: false,
            syncIdentifier: "\(dateTime.timeIntervalSince1970)\(value)",
            device: cgmManager.device
        )
    }
}

import HealthKit
import LoopKitUI
import SwiftUI

struct CalibrationView: View {
    @EnvironmentObject private var displayGlucosePreference: DisplayGlucosePreference
    @ObservedObject var viewModel: CalibrationViewModel

    @State var isEdittingGlucose = false

    var isMgDl: Bool {
        displayGlucosePreference.unit == .milligramsPerDeciliter
    }

    var body: some View {
        VStack {
            List {
                Section {
                    Button(action: { withAnimation { isEdittingGlucose.toggle() } }) {
                        HStack(alignment: .bottom) {
                            Text(LocalizedString("Glucose level", comment: "label glucose"))
                                .foregroundColor(isEdittingGlucose ? .blue : .primary)
                            Spacer()
                            Text(formatGlucose(viewModel.glucose))
                                .foregroundColor(isEdittingGlucose ? .blue : .secondary)
                        }
                    }
                    .buttonStyle(.plain)

                    if isEdittingGlucose {
                        ResizeablePicker(
                            selection: $viewModel.glucose,
                            data: isMgDl ? viewModel.allowedGlucoseValuesMgDl : viewModel.allowedGlucoseValuesMmolL,
                            formatter: { formatGlucose($0) }
                        )
                        .padding(.horizontal)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())

            Spacer()
            if viewModel.isError {
                Text(LocalizedString("Calibration failed. Consult logs to find why", comment: "calibration error"))
                    .foregroundStyle(.red)
            }
            Button(action: viewModel.calibrate) {
                if viewModel.isLoading {
                    ActivityIndicator(isAnimating: .constant(true), style: .medium)
                } else {
                    Text(LocalizedString("Calibrate Sensor", comment: "calibration"))
                }
            }
            .buttonStyle(ActionButtonStyle())
            .padding([.bottom, .horizontal])
            .disabled(viewModel.isLoading)
        }
        .navigationTitle(LocalizedString("Calibration", comment: "Calibation header"))
    }

    private func formatGlucose(_ value: UInt16) -> String {
        let quantity = HKQuantity(
            unit: isMgDl ? .milligramsPerDeciliter : .millimolesPerLiter,
            doubleValue: isMgDl ? Double(value) : Double(value) / 10
        )
        return displayGlucosePreference.format(quantity)
    }
}

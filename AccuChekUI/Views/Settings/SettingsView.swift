import LoopKitUI
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismissAction) private var dismiss
    @Environment(\.guidanceColors) private var guidanceColors
    @EnvironmentObject private var displayGlucosePreference: DisplayGlucosePreference

    @ObservedObject var viewModel: SettingsViewModel

    var removeCgmManagerActionSheet: ActionSheet {
        ActionSheet(
            title: Text("Remove CGM", comment: "Label for CgmManager deletion button"),
            message: Text(
                "Are you sure you want to stop using Accu-Chek CGM?",
                comment: "Message for CgmManager deletion action sheet"
            ),
            buttons: [
                .destructive(
                    Text("Confirm", comment: "Confirmation label")
                ) {
                    viewModel.deleteCGM()
                },
                .cancel()
            ]
        )
    }

    var pairNewCGMActionSheet: ActionSheet {
        ActionSheet(
            title: Text("Pair new Sensor", comment: "title repair sensor action sheet"),
            message: Text(
                "Are you sure you want to pair a new Sensor? You cannot reverse this action.",
                comment: "message repair sensor action sheet"
            ),
            buttons: [
                .destructive(
                    Text("Confirm", comment: "Confirmation label")
                ) {
                    viewModel.pairNewCGM()
                },
                .cancel()
            ]
        )
    }

    var body: some View {
        List {
            Section {
                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        Image(imageName: "sensor")
                            .resizable()
                            .scaledToFit()
                            .padding(.horizontal)
                            .frame(height: 150)
                        Spacer()
                    }

                    sensorStateInformation
                        .padding(.bottom, 8)
                }

                sensorStatusRow
            }

            #if targetEnvironment(simulator)
                Section {
                    sensorDemoControls
                } header: {
                    Text(verbatim: "Demo")
                }
            #endif

            Section {
                SectionItem(
                    title: Text("Glucose", comment: "current glucose"),
                    value: displayGlucosePreference.format(viewModel.lastMeasurement)
                )
                SectionItem(
                    title: Text("Time", comment: "current glucose date"),
                    value: viewModel.lastMeasurementDatetime
                )
            } header: {
                Text("Last measurement", comment: "current reading")
            }

            Section {
                SectionItem(
                    title: Text("Serial Number", comment: "CGM name"),
                    value: viewModel.serialNumberDisplay
                )
                SectionItem(
                    title: Text("Started at", comment: "cgm started"),
                    value: viewModel.sensorStartedAt
                )
                SectionItem(
                    title: Text("Ends at", comment: "cgm ends"),
                    value: viewModel.sensorEndsAt
                )
            } header: {
                Text("Sensor information", comment: "current sensor")
            }

            Section {
                Button(action: { viewModel.isSharePresented = true }) {
                    Text("Share Accu-Chek Logs", comment: "share logs")
                }
                .sheet(isPresented: $viewModel.isSharePresented, onDismiss: {}, content: {
                    ActivityViewController(activityItems: viewModel.getLogs())
                })

                Button(action: { viewModel.showingRepairConfirmation = true }) {
                    Text("Pair New Sensor", comment: "pair new sensor")
                }
                .actionSheet(isPresented: $viewModel.showingRepairConfirmation) {
                    pairNewCGMActionSheet
                }
            } header: {
                Text("Manage", comment: "manage sensor section")
            }

            Section {
                Button(action: {
                    viewModel.showingDeleteConfirmation = true
                }) {
                    Text("Delete CGM", comment: "Label for CgmManager deletion button")
                        .foregroundColor(guidanceColors.critical)
                }
                .actionSheet(isPresented: $viewModel.showingDeleteConfirmation) {
                    removeCgmManagerActionSheet
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationBarItems(trailing: Button(action: dismiss) {
            Text("Done", comment: "done button title")
        })
        .navigationTitle("Accu-Chek CGM")
        .onAppear {
            viewModel.refreshCalibrationConfirmation()
        }
    }

    @ViewBuilder private var sensorStatusRow: some View {
        let status = viewModel.sensorStatus
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: status.iconName)
                .foregroundStyle(status.iconColor(guidanceColors))
            VStack(alignment: .leading, spacing: 2) {
                status.title
                    .fontWeight(.heavy)
                    .foregroundStyle(.primary)
                status.message(calibrationTime: viewModel.nextCalibrationDate)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if status.showsCalibrationButton {
                Button(action: viewModel.doCalibration) {
                    Text("Start", comment: "calibration start button")
                }
                .disabled(!viewModel.connected)
            }
        }
    }

    @ViewBuilder private func SectionItem(title: Text, value: String) -> some View {
        HStack(alignment: .bottom) {
            title
                .foregroundColor(.primary)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }

    @ViewBuilder private var sensorExpirationTimer: some View {
        HStack(alignment: .bottom) {
            if viewModel.sensorAgeDays > 0 {
                Group {
                    Text(String(format: "%.0f", viewModel.sensorAgeDays))
                        .font(.system(size: 28))
                        .fontWeight(.heavy)
                        .foregroundColor(.primary)

                    viewModel.sensorAgeDays == 1 ?
                        Text("day", comment: "age in day").foregroundColor(.secondary) :
                        Text("days", comment: "age in days").foregroundColor(.secondary)
                }
            }
            if viewModel.sensorAgeHours > 0 {
                Group {
                    Text(String(format: "%.0f", viewModel.sensorAgeHours))
                        .font(.system(size: 28))
                        .fontWeight(.heavy)
                        .foregroundColor(.primary)

                    viewModel.sensorAgeHours == 1 ?
                        Text("hour", comment: "age in hour").foregroundColor(.secondary) :
                        Text("hours", comment: "age in hours").foregroundColor(.secondary)
                }
            }
            if viewModel.sensorAgeDays == 0 {
                Group {
                    Text(String(format: "%.0f", viewModel.sensorAgeMinutes))
                        .font(.system(size: 28))
                        .fontWeight(.heavy)
                        .foregroundColor(.primary)

                    viewModel.sensorAgeMinutes == 1 ?
                        Text("minute", comment: "age in hour").foregroundColor(.secondary) :
                        Text("minutes", comment: "age in hours").foregroundColor(.secondary)
                }
            }
        }
    }

    #if targetEnvironment(simulator)
        @ViewBuilder private var sensorDemoControls: some View {
            Picker(selection: $viewModel.demoStatus) {
                Text("Live").tag(SensorStatusDisplay?.none)
                ForEach(SensorStatusDisplay.allCases, id: \.self) { status in
                    Text(verbatim: status.demoLabel).tag(SensorStatusDisplay?.some(status))
                }
            } label: {
                Text(verbatim: "Status row")
            }
        }
    #endif

    @ViewBuilder private var sensorStateInformation: some View {
        switch viewModel.cgmState {
        case .warmingup:
            HStack(alignment: .lastTextBaseline) {
                Text("Warming up:", comment: "sensor warming up label")
                    .foregroundColor(.secondary)
                Spacer()
                Group {
                    Text(String(format: "%.0f", viewModel.sensorWarmupMinutes))
                        .font(.system(size: 28))
                        .fontWeight(.heavy)
                        .foregroundColor(.primary)

                    viewModel.sensorWarmupMinutes == 1 ?
                        Text("minute remaining", comment: "remaining in minute").foregroundColor(.secondary) :
                        Text("minutes remaining", comment: "remaining in minutes").foregroundColor(.secondary)
                }
            }
            SwiftUI.ProgressView(value: viewModel.sensorWarmupProgress)
                .scaleEffect(x: 1, y: 4, anchor: .center)
                .padding(.top, 7)
        case .active:
            HStack(alignment: .lastTextBaseline) {
                Text("Sensor expires in:", comment: "expiration timer")
                    .foregroundColor(.secondary)
                Spacer()
                sensorExpirationTimer
            }
            SwiftUI.ProgressView(value: viewModel.sensorAgeProcess)
                .scaleEffect(x: 1, y: 4, anchor: .center)
                .padding(.top, 7)
        case .expired:
            HStack(alignment: .lastTextBaseline) {
                Text("Sensor expired!", comment: "expired")
                    .foregroundColor(guidanceColors.critical)
                Spacer()
            }
            SwiftUI.ProgressView(value: 1)
                .scaleEffect(x: 1, y: 4, anchor: .center)
                .padding(.top, 7)
                .tint(guidanceColors.critical)
        }
    }
}

private extension SensorStatusDisplay {
    var iconName: String {
        switch self {
        case .connecting: return "arrow.triangle.2.circlepath"
        case .ok: return "checkmark.circle.fill"
        case .trendMode(calibrationDue: false): return "hourglass"
        case .therapyMode(calibrationDue: false): return "drop.circle"
        case .therapyMode(calibrationDue: true),
             .trendMode(calibrationDue: true): return "drop.circle.fill"
        case .temperature: return "thermometer.medium"
        case .batteryLow: return "battery.25"
        case .expired,
             .malfunction,
             .readingsUnavailable: return "exclamationmark.triangle.fill"
        }
    }

    func iconColor(_ guidanceColors: GuidanceColors) -> Color {
        switch severity {
        case .neutral: return .secondary
        case .good: return .green
        case .warning: return guidanceColors.warning
        case .critical: return guidanceColors.critical
        }
    }

    var title: Text {
        switch self {
        case .connecting:
            return Text("Connecting", comment: "sensor status connecting title")
        case .ok:
            return Text("Sensor OK", comment: "sensor status ok title")
        case .trendMode:
            return Text("Trend Mode", comment: "sensor status trend mode title")
        case .therapyMode:
            return Text("Therapy Mode", comment: "sensor status therapy mode title")
        case .temperature:
            return Text("Sensor Temperature", comment: "sensor status temperature title")
        case .batteryLow:
            return Text("Sensor Battery Low", comment: "sensor status battery low title")
        case .expired:
            return Text("Sensor Expired", comment: "sensor status expired title")
        case .malfunction:
            return Text("Sensor Malfunction", comment: "sensor status malfunction title")
        case .readingsUnavailable:
            return Text("Sensor Readings Unavailable", comment: "sensor status unavailable title")
        }
    }

    // `calibrationTime` is the sensor-reported next-calibration time (already
    // formatted), injected into the warmup/trend-mode copy. nil when unknown, in
    // which case the time clause is omitted.
    func message(calibrationTime: String?) -> Text {
        switch self {
        case .connecting:
            return Text("Establishing a connection to your sensor.", comment: "sensor status connecting message")
        case .ok:
            return Text("Your sensor is functioning normally.", comment: "sensor status ok message")
        case .trendMode(calibrationDue: true):
            return Text("Calibrate now to start using your sensor.", comment: "sensor status trend mode due message")
        case .trendMode(calibrationDue: false):
            guard let calibrationTime else {
                return Text("Your sensor is warming up.", comment: "sensor status trend mode message")
            }
            return Text(
                "Your sensor is warming up. First calibration at \(calibrationTime).",
                comment: "sensor status trend mode message with time"
            )
        case .therapyMode(calibrationDue: true):
            return Text(
                "Calibrate now to keep your sensor in therapy mode.",
                comment: "sensor status therapy mode due message"
            )
        case .therapyMode(calibrationDue: false):
            guard let calibrationTime else {
                return Text(
                    "Calibrate again to keep your sensor in therapy mode.",
                    comment: "sensor status therapy mode message"
                )
            }
            return Text(
                "Calibrate again at \(calibrationTime) to keep your sensor in therapy mode.",
                comment: "sensor status therapy mode message with time"
            )
        case .temperature:
            return Text(
                "Your sensor is outside its operating temperature range. Move somewhere it can return to normal.",
                comment: "sensor status temperature message"
            )
        case .batteryLow:
            return Text(
                "Your sensor battery is running low. Start a new one as soon as possible.",
                comment: "sensor status battery low message"
            )
        case .expired:
            return Text(
                "Your sensor has expired. Start a new one as soon as possible.",
                comment: "sensor status expired message"
            )
        case .malfunction:
            return Text(
                "Your sensor is malfunctioning. Start a new one as soon as possible.",
                comment: "sensor status malfunction message"
            )
        case .readingsUnavailable:
            return Text(
                "This could be due to compression or connection loss. Wait for it to resolve, or replace the sensor if it persists.",
                comment: "sensor status unavailable message"
            )
        }
    }

    #if targetEnvironment(simulator)
        var demoLabel: String {
            switch self {
            case .connecting: return "Connecting"
            case .expired: return "Expired"
            case .malfunction: return "Malfunction"
            case .readingsUnavailable: return "Readings Unavailable"
            case .batteryLow: return "Battery Low"
            case .temperature: return "Temperature"
            case .trendMode(calibrationDue: false): return "Trend Mode"
            case .trendMode(calibrationDue: true): return "Trend Mode (calibrate now)"
            case .therapyMode(calibrationDue: false): return "Therapy Mode"
            case .therapyMode(calibrationDue: true): return "Therapy Mode (calibrate now)"
            case .ok: return "OK"
            }
        }
    #endif
}

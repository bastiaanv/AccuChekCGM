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
                        Image(uiImage: UIImage(named: "sensor", in: Bundle(for: AccuChekUIController.self), compatibleWith: nil)!)
                            .resizable()
                            .scaledToFit()
                            .padding(.horizontal)
                            .frame(height: 150)
                        Spacer()
                    }

                    sensorStateInformation
                }

                HStack(alignment: .top) {
                    cgmConnectionStatus
                    Spacer()
                    cgmSerialNumber
                }
                .padding(.bottom, 5)

                if !viewModel.notifications.isEmpty {
                    ForEach(viewModel.notifications) { notification in
                        HStack(alignment: .center) {
                            VStack(alignment: .leading) {
                                HStack(spacing: 10) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundStyle(.red)
                                    Text(notification.title)
                                        .foregroundStyle(.primary)
                                }
                                Text(notification.content)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if notification.type == .calibrationRequired || notification.type == .calibrationRecommended {
                                Button(action: viewModel.doCalibration) {
                                    Text("Start", comment: "calibration start button")
                                }
                                .disabled(!viewModel.connected)
                            }
                        }
                    }
                }
            }

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
                    value: viewModel.deviceName
                )
                SectionItem(
                    title: Text("Started at", comment: "cgm started"),
                    value: viewModel.sensorStartedAt
                )
                SectionItem(
                    title: Text("Ends at", comment: "cgm ends"),
                    value: viewModel.sensorEndsAt
                )
                if let nextCalibration = viewModel.nextCalibration {
                    SectionItem(
                        title: Text("Next calibration at", comment: "cgm calibration"),
                        value: nextCalibration
                    )
                }
            } header: {
                Text("Sensor information", comment: "current sensor")
            }

            Section {
                Button(action: { viewModel.isSharePresented = true }) {
                    Text("Share Accu-chek logs", comment: "share logs")
                }
                .sheet(isPresented: $viewModel.isSharePresented, onDismiss: {}, content: {
                    ActivityViewController(activityItems: viewModel.getLogs())
                })

                Button(action: { viewModel.showingRepairConfirmation = true }) {
                    Text("Pair new Sensor", comment: "pair new sensor")
                }
                .actionSheet(isPresented: $viewModel.showingRepairConfirmation) {
                    pairNewCGMActionSheet
                }

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
    }

    @ViewBuilder private var cgmConnectionStatus: some View {
        VStack(alignment: .leading) {
            Text("Sensor State", comment: "CGM name")
                .fontWeight(.heavy)
                .fixedSize()

            viewModel.connected ?
                Text("Operational", comment: "cgm connection Operational").foregroundColor(.secondary) :
                Text("Connecting", comment: "cgm connection Connecting").foregroundColor(.secondary)
        }
    }

    @ViewBuilder private var cgmSerialNumber: some View {
        VStack(alignment: .trailing) {
            Text("Serial Number", comment: "CGM name")
                .fontWeight(.heavy)
                .fixedSize()
            Text(viewModel.deviceName)
                .foregroundColor(.secondary)
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
                    Text("\(viewModel.sensorAgeDays, specifier: "%.0f")")
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
                    Text("\(viewModel.sensorAgeHours, specifier: "%.0f")")
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
                    Text("\(viewModel.sensorAgeMinutes, specifier: "%.0f")")
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

    @ViewBuilder private var sensorStateInformation: some View {
        switch viewModel.cgmState {
        case .warmingup:
            HStack(alignment: .lastTextBaseline) {
                Text("Warming up:", comment: "sensor warming up label")
                    .foregroundColor(.secondary)
                Spacer()
                Group {
                    Text("\(viewModel.sensorWarmupMinutes, specifier: "%.0f")")
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

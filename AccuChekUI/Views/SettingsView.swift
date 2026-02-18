import LoopKitUI
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismissAction) private var dismiss
    @Environment(\.guidanceColors) private var guidanceColors
    @EnvironmentObject private var displayGlucosePreference: DisplayGlucosePreference

    @ObservedObject var viewModel: SettingsViewModel

    var removeCgmManagerActionSheet: ActionSheet {
        ActionSheet(
            title: Text(LocalizedString("Remove CGM", comment: "Label for CgmManager deletion button")),
            message: Text(LocalizedString(
                "Are you sure you want to stop using Eversense CGM?",
                comment: "Message for CgmManager deletion action sheet"
            )),
            buttons: [
                .destructive(
                    Text(LocalizedString("Confirm", comment: "Confirmation label"))
                ) {
                    viewModel.deleteCGM()
                },
                .cancel()
            ]
        )
    }

    var pairNewCGMActionSheet: ActionSheet {
        ActionSheet(
            title: Text(LocalizedString("Pair new Sensor", comment: "title repair sensor action sheet")),
            message: Text(LocalizedString(
                "Are you sure you want to pair a new Sensor? You cannot reverse this action.",
                comment: "message repair sensor action sheet"
            )),
            buttons: [
                .destructive(
                    Text(LocalizedString("Confirm", comment: "Confirmation label"))
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
                                    Text(LocalizedString("Start", comment: "calibration start button"))
                                }
                                .disabled(!viewModel.connected)
                            }
                        }
                    }
                }
            }

            Section {
                SectionItem(
                    title: LocalizedString("Glucose", comment: "current glucose"),
                    value: displayGlucosePreference.format(viewModel.lastMeasurement)
                )
                SectionItem(
                    title: LocalizedString("Time", comment: "current glucose date"),
                    value: viewModel.lastMeasurementDatetime
                )
            } header: {
                Text(LocalizedString("Last measurement", comment: "current reading"))
            }

            Section {
                SectionItem(
                    title: LocalizedString("Serial Number", comment: "CGM name"),
                    value: viewModel.deviceName
                )
                SectionItem(
                    title: LocalizedString("Started at", comment: "cgm started"),
                    value: viewModel.sensorStartedAt
                )
                SectionItem(
                    title: LocalizedString("Ends at", comment: "cgm ends"),
                    value: viewModel.sensorEndsAt
                )
            } header: {
                Text(LocalizedString("Sensor information", comment: "current sensor"))
            }

            Section {
                Button(LocalizedString("Share Accu-chek logs", comment: "share logs")) {
                    viewModel.isSharePresented = true
                }
                .sheet(isPresented: $viewModel.isSharePresented, onDismiss: {}, content: {
                    ActivityViewController(activityItems: viewModel.getLogs())
                })

                Button(LocalizedString("Pair new Sensor", comment: "pair new sensor")) {
                    viewModel.showingRepairConfirmation = true
                }
                .actionSheet(isPresented: $viewModel.showingRepairConfirmation) {
                    pairNewCGMActionSheet
                }

                Button(action: {
                    viewModel.showingDeleteConfirmation = true
                }) {
                    Text(LocalizedString("Delete CGM", comment: "Label for CgmManager deletion button"))
                        .foregroundColor(guidanceColors.critical)
                }
                .actionSheet(isPresented: $viewModel.showingDeleteConfirmation) {
                    removeCgmManagerActionSheet
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationBarItems(trailing: Button(LocalizedString("Done", comment: "done button title"), action: dismiss))
        .navigationTitle("Accu-Chek CGM")
    }

    @ViewBuilder private var cgmConnectionStatus: some View {
        VStack(alignment: .leading) {
            Text(LocalizedString("Sensor State", comment: "CGM name"))
                .fontWeight(.heavy)
                .fixedSize()
            Text(
                viewModel
                    .connected ? LocalizedString("Operational", comment: "cgm connection Operational") :
                    LocalizedString("Connecting", comment: "CGM name")
            )
            .foregroundColor(.secondary)
        }
    }

    @ViewBuilder private var cgmSerialNumber: some View {
        VStack(alignment: .trailing) {
            Text(LocalizedString("Sensor Serial", comment: "CGM name"))
                .fontWeight(.heavy)
                .fixedSize()
            Text(viewModel.deviceName)
                .foregroundColor(.secondary)
        }
    }

    @ViewBuilder private func SectionItem(title: String, value: String) -> some View {
        HStack(alignment: .bottom) {
            Text(title)
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

                    Text(
                        viewModel.sensorAgeDays == 1 ?
                            LocalizedString("day", comment: "age in day") :
                            LocalizedString("days", comment: "age in days")
                    )
                    .foregroundColor(.secondary)
                }
            }
            if viewModel.sensorAgeHours > 0 {
                Group {
                    Text("\(viewModel.sensorAgeHours, specifier: "%.0f")")
                        .font(.system(size: 28))
                        .fontWeight(.heavy)
                        .foregroundColor(.primary)

                    Text(
                        viewModel.sensorAgeHours == 1 ?
                            LocalizedString("hour", comment: "age in hour") :
                            LocalizedString("hours", comment: "age in hours")
                    )
                    .foregroundColor(.secondary)
                }
            }
            if viewModel.sensorAgeDays == 0 {
                Group {
                    Text("\(viewModel.sensorAgeMinutes, specifier: "%.0f")")
                        .font(.system(size: 28))
                        .fontWeight(.heavy)
                        .foregroundColor(.primary)

                    Text(LocalizedString("min", comment: "age in minute"))
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    @ViewBuilder private var sensorStateInformation: some View {
        switch viewModel.cgmState {
        case .warmingup:
            HStack(alignment: .lastTextBaseline) {
                Text(LocalizedString("Warming up:", comment: "sensor warming up label"))
                    .foregroundColor(.secondary)
                Spacer()
                Group {
                    Text("\(viewModel.sensorWarmupMinutes, specifier: "%.0f")")
                        .font(.system(size: 28))
                        .fontWeight(.heavy)
                        .foregroundColor(.primary)

                    Text(
                        viewModel.sensorWarmupMinutes == 1 ?
                            LocalizedString("minute remaining", comment: "remaining in minute") :
                            LocalizedString("minutes remaining", comment: "remaining in minutes")
                    )
                    .foregroundColor(.secondary)
                }
            }
            SwiftUI.ProgressView(value: viewModel.sensorWarmupProgress)
                .scaleEffect(x: 1, y: 4, anchor: .center)
                .padding(.top, 7)
        case .active:
            HStack(alignment: .lastTextBaseline) {
                Text(LocalizedString("Sensor expires in:", comment: "expiration timer"))
                    .foregroundColor(.secondary)
                Spacer()
                sensorExpirationTimer
            }
            SwiftUI.ProgressView(value: viewModel.sensorAgeProcess)
                .scaleEffect(x: 1, y: 4, anchor: .center)
                .padding(.top, 7)
        case .expired:
            HStack(alignment: .lastTextBaseline) {
                Text(LocalizedString("Sensor expired!", comment: "expired"))
                    .foregroundColor(guidanceColors.critical)
            }
            SwiftUI.ProgressView(value: 1)
                .scaleEffect(x: 1, y: 4, anchor: .center)
                .padding(.top, 7)
                .foregroundStyle(guidanceColors.critical)
        }
    }
}

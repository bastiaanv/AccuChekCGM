import LoopKitUI
import SwiftUI

struct SettingsView: View {
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

    var body: some View {
        List {
            Section {
                VStack {
                    HStack {
                        Spacer()
                        Image(uiImage: UIImage(named: "sensor", in: Bundle(for: AccuChekUIController.self), compatibleWith: nil)!)
                            .resizable()
                            .scaledToFit()
                            .padding(.horizontal)
                            .frame(height: 150)
                        Spacer()
                    }

                    HStack(alignment: .bottom) {
                        Text(LocalizedString("Sensor expires in:", comment: "expiration timer"))
                            .foregroundColor(.secondary)
                        Spacer()
                        sensorExpirationTimer
                    }
                    ProgressView(progress: viewModel.sensorAgeProcess)
                }

                HStack(alignment: .top) {
                    cgmConnectionStatus
                    Spacer()
                    cgmSerialNumber
                }
                .padding(.bottom, 5)
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
                Button(LocalizedString("Share Accu-chek logs", comment: "share logs")) {
                    viewModel.isSharePresented = true
                }
                .sheet(isPresented: $viewModel.isSharePresented, onDismiss: {}, content: {
                    ActivityViewController(activityItems: viewModel.getLogs())
                })

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
        .navigationTitle("Accu-Chek SmartGuide CGM")
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
                    Text(LocalizedString("d", comment: "day"))
                        .foregroundColor(.secondary)
                }
            }
            if viewModel.sensorAgeHours > 0 {
                Group {
                    Text("\(viewModel.sensorAgeHours, specifier: "%.0f")")
                        .font(.system(size: 28))
                        .fontWeight(.heavy)
                        .foregroundColor(.primary)
                    Text(LocalizedString("h", comment: "hour"))
                        .foregroundColor(.secondary)
                }
            }
            if viewModel.sensorAgeDays == 0 {
                Group {
                    Text("\(viewModel.sensorAgeMinutes, specifier: "%.0f")")
                        .font(.system(size: 28))
                        .fontWeight(.heavy)
                        .foregroundColor(.primary)
                    Text(LocalizedString("min", comment: "minute"))
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

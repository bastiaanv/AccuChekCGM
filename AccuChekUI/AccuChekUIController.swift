import LoopKit
import LoopKitUI
import SwiftUI
import UIKit

enum AccuChekScreen {
    case onboarding
    case placementGuide
    case scanning
    case pairing
    case settings
    case calibration
}

class AccuChekUIController: UINavigationController, CGMManagerOnboarding, CompletionNotifying, UINavigationControllerDelegate {
    private let logger = AccuChekLogger(category: "AccuChekUIController")

    var cgmManagerOnboardingDelegate: LoopKitUI.CGMManagerOnboardingDelegate?
    var completionDelegate: LoopKitUI.CompletionDelegate?

    private var cgmManager: AccuChekCgmManager
    private var displayGlucosePreference: DisplayGlucosePreference
    private var colorPalette: LoopUIColorPalette
    private var screenStack = [AccuChekScreen]()

    private var scanResult: ScanResult?

    init(
        cgmManager: AccuChekCgmManager? = nil,
        colorPalette: LoopUIColorPalette,
        displayGlucosePreference: DisplayGlucosePreference,
        allowDebugFeatures _: Bool
    )
    {
        if let cgmManager = cgmManager {
            self.cgmManager = cgmManager
        } else {
            self.cgmManager = AccuChekCgmManager(rawState: [:])
        }
        self.colorPalette = colorPalette
        self.displayGlucosePreference = displayGlucosePreference
        super.init(navigationBarClass: UINavigationBar.self, toolbarClass: UIToolbar.self)
    }

    @available(*, unavailable) required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self

        navigationBar.prefersLargeTitles = true
        if screenStack.isEmpty {
            let screen = getInitialScreen()
            let viewController = viewControllerForScreen(screen)

            screenStack = [screen]
            viewController.isModalInPresentation = false
            setViewControllers([viewController], animated: false)
        }
    }

    private func getInitialScreen() -> AccuChekScreen {
        cgmManager.isOnboarded ? .settings : .onboarding
    }

    private func hostingController<Content: View>(rootView: Content) -> DismissibleHostingController<some View> {
        let rootView = rootView
            .environmentObject(displayGlucosePreference)
        return DismissibleHostingController(content: rootView, colorPalette: colorPalette)
    }

    private func viewControllerForScreen(_ screen: AccuChekScreen) -> UIViewController {
        switch screen {
        case .onboarding:
            let view = OnboardingView(
                manualScan: onboardingDone,
                sensorPlacement: { self.navigateTo(.placementGuide) }
            )
            return hostingController(rootView: view)

        case .placementGuide:
            return hostingController(rootView: SensorPlacementView())

        case .scanning:
            let viewModel = ScanViewModel(
                cgmManager: cgmManager,
                nextStep: { result in
                    DispatchQueue.main.async {
                        self.cgmManagerOnboardingDelegate?.cgmManagerOnboarding(didOnboardCGMManager: self.cgmManager)
                    }

                    self.scanResult = result
                    self.resetNavigationTo([.pairing])
                }
            )
            return hostingController(rootView: ScanView(viewModel: viewModel))

        case .pairing:
            let nextStep = {
                DispatchQueue.main.async {
                    self.cgmManagerOnboardingDelegate?.cgmManagerOnboarding(didCreateCGMManager: self.cgmManager)
                    self.completionDelegate?.completionNotifyingDidComplete(self)
                }
            }

            let viewModel = PairingViewModel(
                cgmManager,
                scanResult: scanResult,
                nextStep: nextStep
            )
            return hostingController(rootView: PairingView(viewModel: viewModel))

        case .settings:
            let deleteCGM = {
                self.cgmManager.notifyDelegateOfDeletion {
                    DispatchQueue.main.async {
                        self.completionDelegate?.completionNotifyingDidComplete(self)
                    }
                }
            }

            let viewModel = SettingsViewModel(
                cgmManager,
                doCalibration: { self.navigateTo(.calibration) },
                doPairing: { self.navigateTo(.scanning) },
                deleteCGM: deleteCGM
            )
            return hostingController(rootView: SettingsView(viewModel: viewModel))

        case .calibration:
            let viewModel = CalibrationViewModel(cgmManager: cgmManager, displayGlucosePreference.unit, goBack)
            return hostingController(rootView: CalibrationView(viewModel: viewModel))
        }
    }

    private func doOnboarding() {
        cgmManager.state.onboarded = true
        cgmManager.notifyStateDidChange()

        if let cgmManagerOnboardingDelegate = self.cgmManagerOnboardingDelegate {
            DispatchQueue.main.async {
                cgmManagerOnboardingDelegate.cgmManagerOnboarding(didOnboardCGMManager: self.cgmManager)
                cgmManagerOnboardingDelegate.cgmManagerOnboarding(didCreateCGMManager: self.cgmManager)
                self.completionDelegate?.completionNotifyingDidComplete(self)
            }
        } else {
            logger.warning("Not onboarded -> no onboardDelegate...")
        }
    }

    private func navigateTo(_ screen: AccuChekScreen) {
        screenStack.append(screen)
        let viewController = viewControllerForScreen(screen)
        viewController.isModalInPresentation = false
        pushViewController(viewController, animated: true)
        viewController.view.layoutSubviews()
    }

    private func goBack() {
        guard screenStack.count > 1 else {
            return
        }

        _ = screenStack.popLast()
        popViewController(animated: true)
    }

    func resetNavigationTo(_ screens: [AccuChekScreen]) {
        screenStack = screens
        let viewControllers = screenStack.map {
            let viewController = viewControllerForScreen($0)
            viewController.isModalInPresentation = false
            viewController.view.layoutSubviews()
            return viewController
        }

        setViewControllers(viewControllers, animated: true)
    }

    private func onboardingDone() {
        #if targetEnvironment(simulator)
            cgmManager.state.deviceName = "Simulator"
            cgmManager.state.onboarded = true
            cgmManager.state.nextCalibrationAt = Date.now.addingTimeInterval(.minutes(25))
            cgmManager.state.calibrationPhase = .calibratedOnce
            cgmManager.state.cgmStartTime = Date.now
            cgmManager.state.cgmStatus = []
            cgmManager.notifyStateDidChange()

            if let cgmManagerOnboardingDelegate = self.cgmManagerOnboardingDelegate {
                DispatchQueue.main.async {
                    cgmManagerOnboardingDelegate.cgmManagerOnboarding(didOnboardCGMManager: self.cgmManager)
                    cgmManagerOnboardingDelegate.cgmManagerOnboarding(didCreateCGMManager: self.cgmManager)
                    self.completionDelegate?.completionNotifyingDidComplete(self)
                }
            }
        #else
            navigateTo(.scanning)
        #endif
    }
}

import LoopKit
import LoopKitUI
import SwiftUI
import UIKit

enum AccuChekScreen {
    case onboarding
    case auth
    case pairing
    case settings
    case calibration
}

class AccuChekUIController: UINavigationController, CGMManagerOnboarding, CompletionNotifying, UINavigationControllerDelegate {
    let logger = AccuChekLogger(category: "AccuChekUIController")

    var cgmManagerOnboardingDelegate: LoopKitUI.CGMManagerOnboardingDelegate?
    var completionDelegate: LoopKitUI.CompletionDelegate?
    var cgmManager: AccuChekCgmManager?
    var displayGlucosePreference: DisplayGlucosePreference

    var colorPalette: LoopUIColorPalette
    var screenStack = [AccuChekScreen]()

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
        if cgmManager?.isOnboarded ?? false {
            return .settings
        }

        return .onboarding
    }

    private func hostingController<Content: View>(rootView: Content) -> DismissibleHostingController<some View> {
        let rootView = rootView
            .environmentObject(displayGlucosePreference)
        return DismissibleHostingController(content: rootView, colorPalette: colorPalette)
    }

    private func viewControllerForScreen(_ screen: AccuChekScreen) -> UIViewController {
        switch screen {
        case .onboarding:
            let view = OnboardingView(nextStep: { self.navigateTo(.pairing) })
            return hostingController(rootView: view)

        case .auth:
            let viewModel = WebViewModel(nextStep: { response in
                if let cgmManager = self.cgmManager, let response = response {
                    cgmManager.state.accessToken = response.access_token
                    cgmManager.state.expiresAt = Date.now.addingTimeInterval(.seconds(Double(response.expires_in)))
                    cgmManager.state.refreshToken = response.refresh_token
                    cgmManager.notifyStateDidChange()
                }

                self.resetNavigationTo([.pairing])
            })
            return hostingController(rootView: AuthView(viewModel: viewModel))

        case .pairing:
            let nextStep = {
                if let cgmManager = self.cgmManager {
                    DispatchQueue.main.async {
                        self.cgmManagerOnboardingDelegate?.cgmManagerOnboarding(didOnboardCGMManager: cgmManager)
                        self.cgmManagerOnboardingDelegate?.cgmManagerOnboarding(didCreateCGMManager: cgmManager)
                        self.completionDelegate?.completionNotifyingDidComplete(self)
                    }
                }
            }

            let viewModel = PairingViewModel(cgmManager, nextStep: nextStep)
            return hostingController(rootView: PairingView(viewModel: viewModel))

        case .settings:
            let doCalibration = {
                self.navigateTo(.calibration)
            }
            let doPairing = {
                self.navigateTo(.pairing)
            }
            let deleteCGM = {
                guard let cgmManager = self.cgmManager else {
                    self.completionDelegate?.completionNotifyingDidComplete(self)
                    return
                }

                cgmManager.notifyDelegateOfDeletion {
                    DispatchQueue.main.async {
                        self.completionDelegate?.completionNotifyingDidComplete(self)
                    }
                }
            }

            let viewModel = SettingsViewModel(cgmManager, doCalibration: doCalibration, doPairing: doPairing, deleteCGM: deleteCGM)
            return hostingController(rootView: SettingsView(viewModel: viewModel))

        case .calibration:
            let viewModel = CalibrationViewModel(cgmManager: cgmManager, displayGlucosePreference.unit, goBack)
            return hostingController(rootView: CalibrationView(viewModel: viewModel))
        }
    }

    private func doOnboarding() {
        if let cgmManager = self.cgmManager {
            cgmManager.state.onboarded = true
            cgmManager.notifyStateDidChange()

            if let cgmManagerOnboardingDelegate = self.cgmManagerOnboardingDelegate {
                DispatchQueue.main.async {
                    cgmManagerOnboardingDelegate.cgmManagerOnboarding(didOnboardCGMManager: cgmManager)
                    cgmManagerOnboardingDelegate.cgmManagerOnboarding(didCreateCGMManager: cgmManager)
                    self.completionDelegate?.completionNotifyingDidComplete(self)
                }
            } else {
                logger.warning("Not onboarded -> no onboardDelegate...")
            }
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
}

import LoopKit
import LoopKitUI

extension AccuChekCgmManager: CGMManagerUI {
    public static func setupViewController(
        bluetoothProvider _: any LoopKit.BluetoothProvider,
        displayGlucosePreference: LoopKitUI.DisplayGlucosePreference,
        colorPalette: LoopKitUI.LoopUIColorPalette,
        allowDebugFeatures: Bool,
        prefersToSkipUserInteraction _: Bool
    ) -> LoopKitUI.SetupUIResult<any LoopKitUI.CGMManagerViewController, any LoopKitUI.CGMManagerUI> {
        let vc = AccuChekUIController(
            colorPalette: colorPalette,
            displayGlucosePreference: displayGlucosePreference,
            allowDebugFeatures: allowDebugFeatures
        )
        return .userInteractionRequired(vc)
    }

    public func settingsViewController(
        bluetoothProvider _: any LoopKit.BluetoothProvider,
        displayGlucosePreference: LoopKitUI.DisplayGlucosePreference,
        colorPalette: LoopKitUI.LoopUIColorPalette,
        allowDebugFeatures: Bool
    ) -> any LoopKitUI.CGMManagerViewController {
        AccuChekUIController(
            cgmManager: self,
            colorPalette: colorPalette,
            displayGlucosePreference: displayGlucosePreference,
            allowDebugFeatures: allowDebugFeatures
        )
    }

    public static var onboardingImage: UIImage? {
        nil
    }

    public var smallImage: UIImage? {
        nil
    }

    public var cgmStatusHighlight: (any LoopKit.DeviceStatusHighlight)? {
        nil
    }

    public var cgmLifecycleProgress: (any LoopKit.DeviceLifecycleProgress)? {
        nil
    }

    public var cgmStatusBadge: (any LoopKitUI.DeviceStatusBadge)? {
        nil
    }
}

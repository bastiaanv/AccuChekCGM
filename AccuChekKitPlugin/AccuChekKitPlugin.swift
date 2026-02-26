import AccuChekKit
import LoopKitUI

class AccuChekKitPlugin: NSObject, CGMManagerUIPlugin {
    public var pumpManagerType: PumpManagerUI.Type? {
        nil
    }

    public var cgmManagerType: CGMManagerUI.Type? {
        AccuChekCgmManager.self
    }
}

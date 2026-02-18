import AccuChekKit
import LoopKitUI

class EversenseKitPlugin: NSObject, CGMManagerUIPlugin {
    public var pumpManagerType: PumpManagerUI.Type? {
        nil
    }

    public var cgmManagerType: CGMManagerUI.Type? {
        AccuChekCgmManager.self
    }
}

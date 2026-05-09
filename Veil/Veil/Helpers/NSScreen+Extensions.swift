import AppKit
import CoreGraphics

extension NSScreen {
    var displayID: CGDirectDisplayID? {
        deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID
    }

    func isSameScreen(as other: NSScreen) -> Bool {
        displayID == other.displayID
    }
}

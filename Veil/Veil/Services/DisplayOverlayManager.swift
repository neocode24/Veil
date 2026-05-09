import AppKit
import SwiftUI

@MainActor
final class DisplayOverlayManager {
    private var overlays: [CGDirectDisplayID: OverlayWindow] = [:]

    func ensureOverlay(on screen: NSScreen, showClock: Bool, use24Hour: Bool, showSeconds: Bool) {
        guard let displayID = screen.displayID else { return }

        if let existing = overlays[displayID] {
            existing.setFrame(screen.frame, display: false)
            updateContent(window: existing, showClock: showClock, use24Hour: use24Hour, showSeconds: showSeconds)
            existing.alphaValue = 1.0
            existing.orderFront(nil)
            return
        }

        let window = OverlayWindow(contentRect: screen.frame, targetScreen: screen)
        updateContent(window: window, showClock: showClock, use24Hour: use24Hour, showSeconds: showSeconds)
        window.alphaValue = 1.0
        window.orderFront(nil)
        overlays[displayID] = window
    }

    func removeExcept(_ displayIDs: Set<CGDirectDisplayID>) {
        for (id, window) in overlays where !displayIDs.contains(id) {
            window.alphaValue = 0
            window.orderOut(nil)
        }
    }

    func removeAll() {
        for window in overlays.values {
            window.alphaValue = 0
            window.orderOut(nil)
        }
    }

    private func updateContent(window: OverlayWindow, showClock: Bool, use24Hour: Bool, showSeconds: Bool) {
        if showClock {
            let view = NSHostingView(rootView: FlipClockViewWrapper(use24Hour: use24Hour, showSeconds: showSeconds))
            view.frame = window.contentView?.bounds ?? .zero
            view.autoresizingMask = [.width, .height]
            window.contentView = view
        } else {
            window.contentView = nil
        }
    }
}

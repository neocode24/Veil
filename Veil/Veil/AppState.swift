import AppKit

@MainActor
@Observable
final class AppState {
    var isEnabled = true
    var showClockOnBlanked = true
    var use24HourClock = true
    var showSecondsClock = false
    var isOverlayActive = false
    var fullscreenAppName: String?
    var blankedDisplayNames: [String] = []

    // Per-monitor settings
    var excludedMonitorNames: Set<String> = []

    let mediaAppDetector = MediaAppDetector()

    private let defaults = UserDefaults.standard
    private let excludedMonitorsKey = "veil.excludedMonitors"

    var screenCount: Int {
        NSScreen.screens.count
    }

    func updateScreenInfo() {
        _ = NSScreen.screens
    }

    func isMonitorExcluded(_ name: String) -> Bool {
        excludedMonitorNames.contains(name)
    }

    func toggleMonitorExclusion(_ name: String) {
        if excludedMonitorNames.contains(name) {
            excludedMonitorNames.remove(name)
        } else {
            excludedMonitorNames.insert(name)
        }
        defaults.set(Array(excludedMonitorNames), forKey: excludedMonitorsKey)
    }

    init() {
        let excluded = UserDefaults.standard.stringArray(forKey: "veil.excludedMonitors") ?? []
        excludedMonitorNames = Set(excluded)
        FullscreenDetector.requestAccessibilityIfNeeded()
    }
}

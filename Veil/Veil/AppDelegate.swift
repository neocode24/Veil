import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let appState = AppState()
    let statusBarController = StatusBarController()
    let fullscreenMonitor = FullscreenMonitor()
    let overlayManager = DisplayOverlayManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
        ProcessInfo.processInfo.disableAutomaticTermination("Veil is monitoring displays")

        requestAccessibilityIfNeeded()

        statusBarController.setup(appState: appState, delegate: self)
        fullscreenMonitor.delegate = self
        fullscreenMonitor.appDetector = appState.mediaAppDetector

        if appState.isEnabled {
            fullscreenMonitor.start()
        }

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(screenParametersChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )

        NSLog("[Veil] launched — screens=\(NSScreen.screens.count) accessibility=\(AXIsProcessTrusted())")
    }

    func refreshOverlays() {
        guard appState.isEnabled else {
            overlayManager.removeAll()
            appState.isOverlayActive = false
            appState.blankedDisplayNames = []
            return
        }

        if let activeScreen = fullscreenMonitor.currentFullscreenScreen {
            showOverlays(excluding: activeScreen)
        } else if appState.isOverlayActive {
            overlayManager.removeAll()
            appState.isOverlayActive = false
            appState.blankedDisplayNames = []
        }
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        overlayManager.removeAll()
        return .terminateNow
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        true
    }

    // MARK: - Private

    private func requestAccessibilityIfNeeded() {
        guard !AXIsProcessTrusted() else { return }
        // kAXTrustedCheckOptionPrompt = "AXTrustedCheckOptionPrompt"
        let opts = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        AXIsProcessTrustedWithOptions(opts)
    }

    @objc private func screenParametersChanged(_ notification: Notification) {
        appState.updateScreenInfo()
        if appState.isOverlayActive {
            overlayManager.removeAll()
            appState.isOverlayActive = false
        }
        fullscreenMonitor.check()
    }
}

// MARK: - FullscreenMonitorDelegate

extension AppDelegate: FullscreenMonitorDelegate {
    func fullscreenDidChange(activeScreen: NSScreen?, appName: String?) {
        appState.fullscreenAppName = appName

        guard appState.isEnabled else { return }

        if let activeScreen {
            showOverlays(excluding: activeScreen)
        } else {
            overlayManager.removeAll()
            appState.isOverlayActive = false
            appState.blankedDisplayNames = []
        }
    }

    private func showOverlays(excluding activeScreen: NSScreen) {
        var neededIDs: Set<CGDirectDisplayID> = []
        var blankedNames: [String] = []

        for screen in NSScreen.screens {
            guard !screen.isSameScreen(as: activeScreen) else { continue }
            let displayName = screen.localizedName
            guard !appState.excludedMonitorNames.contains(displayName) else { continue }
            guard let displayID = screen.displayID else { continue }

            neededIDs.insert(displayID)
            overlayManager.ensureOverlay(on: screen, showClock: appState.showClockOnBlanked, use24Hour: appState.use24HourClock, showSeconds: appState.showSecondsClock)
            blankedNames.append(displayName)
        }

        overlayManager.removeExcept(neededIDs)
        appState.blankedDisplayNames = blankedNames
        appState.isOverlayActive = !blankedNames.isEmpty
        NSLog("[Veil] overlays active=\(appState.fullscreenAppName ?? "none") blanked=\(blankedNames)")
    }
}

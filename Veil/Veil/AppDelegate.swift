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

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(systemDidWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )

        NSLog("[Veil] launched — screens=\(NSScreen.screens.count) accessibility=\(AXIsProcessTrusted())")
    }

    func refreshOverlays() {
        defer { statusBarController.refreshPanelSize() }

        guard appState.isEnabled else {
            overlayManager.removeAll()
            appState.isOverlayActive = false
            appState.blankedDisplayNames = []
            return
        }

        fullscreenMonitor.check()

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
            appState.blankedDisplayNames = []
        }
        fullscreenMonitor.check()
    }

    @objc private func systemDidWake(_ notification: Notification) {
        // 슬립 해제 직후 디스플레이 구성이 확정되기까지 짧은 지연 필요
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(1500))
            appState.updateScreenInfo()
            overlayManager.removeAll()
            appState.isOverlayActive = false
            appState.blankedDisplayNames = []
            fullscreenMonitor.check()
            NSLog("[Veil] wake from sleep — screens=\(NSScreen.screens.count)")
        }
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

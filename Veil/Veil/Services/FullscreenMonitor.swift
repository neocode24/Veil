import AppKit

@MainActor
protocol FullscreenMonitorDelegate: AnyObject {
    func fullscreenDidChange(activeScreen: NSScreen?, appName: String?)
}

@MainActor
final class FullscreenMonitor {
    weak var delegate: (any FullscreenMonitorDelegate)?
    var appDetector: MediaAppDetector?

    private var observers: [NSObjectProtocol] = []
    private var spaceChangeTask: Task<Void, Never>?
    private var currentFullscreenApp: String?
    private(set) var currentFullscreenScreen: NSScreen?

    func start() {
        guard observers.isEmpty else { return }
        registerWorkspaceObservers()
        check()
    }

    func stop() {
        let nc = NSWorkspace.shared.notificationCenter
        observers.forEach { nc.removeObserver($0) }
        observers.removeAll()
        spaceChangeTask?.cancel()
        spaceChangeTask = nil
    }

    func check() {
        guard let detector = appDetector else { return }
        let result = FullscreenDetector.detectFullscreenApp(using: detector)
        let newApp = result?.appName
        let newScreen = result?.screen
        guard newApp != currentFullscreenApp || !isSameScreen(newScreen, currentFullscreenScreen) else { return }
        currentFullscreenApp = newApp
        currentFullscreenScreen = newScreen
        delegate?.fullscreenDidChange(activeScreen: newScreen, appName: newApp)
    }

    // MARK: - Private

    private func registerWorkspaceObservers() {
        let nc = NSWorkspace.shared.notificationCenter

        // Space 전환: AX가 새 Space 상태를 반영할 때까지 800ms 대기
        let spaceTrigger: (Notification) -> Void = { [weak self] _ in
            Task { @MainActor in self?.scheduleSpaceCheck() }
        }

        // 앱 활성화/비활성화: 전체화면 진입·종료를 즉시 반영
        let immediateTrigger: (Notification) -> Void = { [weak self] _ in
            Task { @MainActor in self?.check() }
        }

        observers = [
            nc.addObserver(forName: NSWorkspace.activeSpaceDidChangeNotification, object: nil, queue: .main, using: spaceTrigger),
            nc.addObserver(forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main, using: immediateTrigger),
            nc.addObserver(forName: NSWorkspace.didDeactivateApplicationNotification, object: nil, queue: .main, using: immediateTrigger),
        ]
    }

    private func scheduleSpaceCheck() {
        spaceChangeTask?.cancel()
        spaceChangeTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(800))
            guard !Task.isCancelled else { return }
            self?.check()
        }
    }

    private func isSameScreen(_ a: NSScreen?, _ b: NSScreen?) -> Bool {
        guard let a, let b else { return a == nil && b == nil }
        return a.displayID == b.displayID
    }
}

import AppKit
import SwiftUI

@MainActor
final class StatusBarController {
    private var statusItem: NSStatusItem!
    private var panel: MenuPanel!
    private var hostingView: NSHostingView<MenuBarView>!
    nonisolated(unsafe) private var eventMonitor: Any?

    func setup(appState: AppState, delegate: AppDelegate) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            if let icon = NSImage(named: "VeilMenuBarIcon") {
                icon.isTemplate = true
                button.image = icon
            }
            button.action = #selector(togglePanel)
            button.target = self
        }

        let panel = MenuPanel(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 500),
            styleMask: [.nonactivatingPanel, .borderless],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.isMovableByWindowBackground = true
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true

        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = .popover
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.state = .active
        visualEffectView.wantsLayer = true
        visualEffectView.layer?.cornerRadius = 12
        visualEffectView.layer?.masksToBounds = true

        let menuBarView = MenuBarView(
            appState: appState,
            onRestore: { [weak delegate] in
                delegate?.overlayManager.removeAll()
                appState.isOverlayActive = false
                appState.blankedDisplayNames.removeAll()
            },
            onSettingsChanged: { [weak delegate] in
                delegate?.refreshOverlays()
            },
            onQuit: {
                NSApplication.shared.terminate(nil)
            }
        )

        let hostingView = NSHostingView(rootView: menuBarView)
        hostingView.autoresizingMask = [.width, .height]
        visualEffectView.addSubview(hostingView)

        panel.contentView = visualEffectView
        self.panel = panel
        self.hostingView = hostingView

        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown) { [weak self] _ in
            guard let self, let panel = self.panel, panel.isVisible else { return }
            if !panel.frame.contains(NSEvent.mouseLocation) {
                panel.orderOut(nil)
            }
        }
    }

    deinit {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    @objc private func togglePanel() {
        if panel.isVisible {
            panel.orderOut(nil)
        } else {
            guard let button = statusItem.button else { return }

            let buttonFrame = button.window?.convertToScreen(
                button.convert(button.bounds, to: nil)
            ) ?? .zero

            let panelWidth: CGFloat = 280 + 32
            let panelHeight: CGFloat = hostingView.fittingSize.height

            let x = buttonFrame.midX - panelWidth / 2
            let y = buttonFrame.origin.y - panelHeight - 8

            panel.setFrame(
                NSRect(x: x, y: max(0, y), width: panelWidth, height: panelHeight),
                display: true
            )
            panel.makeKeyAndOrderFront(nil)
        }
    }
}

private final class MenuPanel: NSPanel {
    override var canBecomeKey: Bool { true }
}

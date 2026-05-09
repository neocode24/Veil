import AppKit
import SwiftUI

@MainActor
final class StatusBarController {
    private var statusItem: NSStatusItem!
    private var panel: MenuPanel!

    func setup(appState: AppState, delegate: AppDelegate) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "eye.slash", accessibilityDescription: "Veil")
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
        panel.backgroundColor = NSColor(white: 0.12, alpha: 0.95)
        panel.hasShadow = true
        panel.contentView?.wantsLayer = true
        panel.contentView?.layer?.cornerRadius = 12
        panel.contentView?.layer?.masksToBounds = true

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
        panel.contentView = NSHostingView(rootView: menuBarView)
        self.panel = panel
    }

    @objc private func togglePanel() {
        if panel.isVisible {
            panel.orderOut(nil)
        } else {
            guard let button = statusItem.button,
                  let screen = button.window?.screen else { return }

            let buttonFrame = button.window?.convertToScreen(
                button.convert(button.bounds, to: nil)
            ) ?? .zero

            let panelWidth: CGFloat = 280 + 32
            let panelHeight: CGFloat = panel.contentView?.fittingSize.height ?? 400

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

// NSPanel subclass that allows becoming key window for text input
private final class MenuPanel: NSPanel {
    override var canBecomeKey: Bool { true }
}

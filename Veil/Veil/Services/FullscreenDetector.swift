import CoreGraphics
import AppKit

@MainActor
struct FullscreenDetector {

    static var isAXTrusted: Bool {
        AXIsProcessTrusted()
    }

    /// 접근성 권한이 없으면 시스템 다이얼로그 표시
    static func requestAccessibilityIfNeeded() {
        guard !AXIsProcessTrusted() else { return }
        let promptKey = "AXTrustedCheckOptionPrompt" as CFString
        let options = [promptKey: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    static func detectFullscreenApp(using appDetector: MediaAppDetector) -> (screen: NSScreen, appName: String)? {
        let axTrusted = AXIsProcessTrusted()
        NSLog("[Veil] check: AXTrusted=\(axTrusted)")
        if axTrusted {
            return detectViaAccessibility(using: appDetector)
        }
        return detectViaWindowList(using: appDetector)
    }

    // MARK: - Accessibility API (AXFullScreen 속성으로 정확한 감지)

    private static func detectViaAccessibility(using appDetector: MediaAppDetector) -> (screen: NSScreen, appName: String)? {
        let screens = NSScreen.screens
        for app in NSWorkspace.shared.runningApplications {
            guard let name = app.localizedName,
                  app.activationPolicy == .regular,
                  appDetector.shouldDetect(name) else { continue }

            NSLog("[Veil] AX checking: \(name) pid=\(app.processIdentifier)")
            let axApp = AXUIElementCreateApplication(app.processIdentifier)
            guard let screen = fullscreenScreen(for: axApp, appName: name, screens: screens) else { continue }
            NSLog("[Veil] AX detected: app=\(name) screen=\(screen.localizedName)")
            return (screen, name)
        }
        return nil
    }

    private static func fullscreenScreen(for axApp: AXUIElement, appName: String, screens: [NSScreen]) -> NSScreen? {
        var windowsRef: CFTypeRef?
        let err = AXUIElementCopyAttributeValue(axApp, kAXWindowsAttribute as CFString, &windowsRef)
        guard err == .success, let windows = windowsRef as? [AXUIElement] else {
            NSLog("[Veil] AX windows failed: app=\(appName) err=\(err.rawValue)")
            return nil
        }

        NSLog("[Veil] AX windows: app=\(appName) count=\(windows.count)")
        for window in windows {
            var fsRef: CFTypeRef?
            let fsErr = AXUIElementCopyAttributeValue(window, "AXFullScreen" as CFString, &fsRef)
            let isFS = fsRef as? Bool ?? false
            NSLog("[Veil] AX window: fsErr=\(fsErr.rawValue) AXFullScreen=\(isFS)")

            if fsErr == .success {
                if isFS {
                    return screenForAXWindow(window, screens: screens, sizeCheck: false)
                }
                continue
            }

            // fsErr != .success: 속성 없음 (-25201) vs 접근 불가 (-25212) 구분
            // -25212 = 창 접근 자체가 안 됨 → size-match도 신뢰 불가 → skip
            if fsErr.rawValue == -25212 { continue }

            // -25201 등 속성 없음: non-native fullscreen 앱(VLC 등) size-match fallback
            if let screen = screenForAXWindow(window, screens: screens, sizeCheck: true) {
                NSLog("[Veil] AX size-match: app=\(appName) screen=\(screen.localizedName)")
                return screen
            }
        }
        return nil
    }

    private static func screenForAXWindow(_ window: AXUIElement, screens: [NSScreen], sizeCheck: Bool) -> NSScreen? {
        var posRef: CFTypeRef?
        var szRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &posRef) == .success,
              AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &szRef) == .success,
              let posVal = posRef, CFGetTypeID(posVal) == AXValueGetTypeID(),
              let szVal = szRef, CFGetTypeID(szVal) == AXValueGetTypeID() else { return nil }

        var pos = CGPoint.zero
        var sz = CGSize.zero
        AXValueGetValue(posVal as! AXValue, .cgPoint, &pos)
        AXValueGetValue(szVal as! AXValue, .cgSize, &sz)

        var displayID: CGDirectDisplayID = kCGNullDirectDisplay
        var matchCount: UInt32 = 0
        CGGetDisplaysWithRect(CGRect(origin: pos, size: sz), 1, &displayID, &matchCount)
        guard matchCount > 0, let screen = screens.first(where: { $0.displayID == displayID }) else { return nil }

        if sizeCheck {
            let sf = screen.frame
            guard sz.height >= sf.height - 10 && sz.width >= sf.width - 10 else { return nil }
        }

        return screen
    }

    // MARK: - CGWindowList fallback (onscreen=true만 — 유령 창 제거)

    private static func detectViaWindowList(using appDetector: MediaAppDetector) -> (screen: NSScreen, appName: String)? {
        let options = CGWindowListOption(rawValue: 0)
        guard let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else { return nil }

        let ourPID = ProcessInfo.processInfo.processIdentifier
        let screens = NSScreen.screens

        let regularAppNames = Set(NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }
            .compactMap { $0.localizedName })

        for info in windowList {
            guard let ownerPID = info[kCGWindowOwnerPID as String] as? Int32,
                  Int32(ourPID) != ownerPID,
                  let ownerName = info[kCGWindowOwnerName as String] as? String,
                  regularAppNames.contains(ownerName),
                  appDetector.shouldDetect(ownerName) else { continue }

            let layer = info[kCGWindowLayer as String] as? Int ?? -999
            let onscreen = info[kCGWindowIsOnscreen as String] as? Bool ?? false
            guard let boundsDict = info[kCGWindowBounds as String] as? [String: Any],
                  let bounds = CGRect(dictionaryRepresentation: boundsDict as CFDictionary) else { continue }

            NSLog("[Veil] CGList candidate: app=\(ownerName) layer=\(layer) onscreen=\(onscreen) origin=(\(Int(bounds.origin.x)),\(Int(bounds.origin.y))) size=\(Int(bounds.width))×\(Int(bounds.height))")

            guard layer >= 0, layer <= 1 else { continue }

            // onscreen=true만 허용: 현재 보이는 Space에 있는 창만 신뢰
            // onscreen=false는 다른 Space/유령 창으로 오탐 가능성 높음
            guard onscreen else {
                NSLog("[Veil] CGList skip (offscreen)")
                continue
            }

            var displayID: CGDirectDisplayID = kCGNullDirectDisplay
            var matchCount: UInt32 = 0
            CGGetDisplaysWithRect(bounds, 1, &displayID, &matchCount)

            guard matchCount > 0, let screen = screens.first(where: { $0.displayID == displayID }) else { continue }

            let displayBounds = CGDisplayBounds(displayID)
            // fullscreen 창은 화면 origin에서 시작 + 화면 크기와 일치
            let originTolerance: CGFloat = 10
            guard abs(bounds.origin.x - displayBounds.origin.x) <= originTolerance &&
                  abs(bounds.origin.y - displayBounds.origin.y) <= originTolerance else {
                NSLog("[Veil] CGList skip (origin mismatch): (\(Int(bounds.origin.x)),\(Int(bounds.origin.y))) vs display (\(Int(displayBounds.origin.x)),\(Int(displayBounds.origin.y)))")
                continue
            }

            guard bounds.height >= displayBounds.height - 50 && bounds.width >= displayBounds.width - 10 else {
                NSLog("[Veil] CGList skip (too small): \(Int(bounds.width))×\(Int(bounds.height)) vs display \(Int(displayBounds.width))×\(Int(displayBounds.height))")
                continue
            }

            NSLog("[Veil] CGWindowList detected: app=\(ownerName) screen=\(screen.localizedName)")
            return (screen, ownerName)
        }
        return nil
    }
}

import Foundation

@MainActor
@Observable
final class MediaAppDetector {

    static let builtInApps: Set<String> = [
        "Safari",
        "Google Chrome",
        "Brave Browser",
        "Firefox",
        "Arc",
        "Microsoft Edge",
        "VLC",
        "QuickTime Player",
        "IINA",
        "mpv",
        "Apple TV",
        "Netflix",
        "Disney+",
        "Prime Video",
        "Infuse",
        "Plex",
        "Movist",
        "Kodi",
        "YouTube",
        "Zoom",
        "FaceTime",
        "Google Meet",
        "Discord",
        "OBS",
    ]

    private(set) var customApps: Set<String> {
        didSet { saveCustomApps() }
    }

    private(set) var disabledApps: Set<String> {
        didSet { saveDisabledApps() }
    }

    var allApps: Set<String> {
        Self.builtInApps.union(customApps)
    }

    var activeApps: Set<String> {
        allApps.subtracting(disabledApps)
    }

    private let defaults = UserDefaults.standard
    private let customAppsKey = "veil.customApps"
    private let disabledAppsKey = "veil.disabledApps"

    init() {
        let saved = UserDefaults.standard.stringArray(forKey: "veil.customApps") ?? []
        self.customApps = Set(saved)
        let disabled = UserDefaults.standard.stringArray(forKey: "veil.disabledApps") ?? []
        self.disabledApps = Set(disabled)
    }

    func isVideoPlayer(_ appName: String) -> Bool {
        activeApps.contains(appName)
    }

    func isActive(_ appName: String) -> Bool {
        !disabledApps.contains(appName)
    }

    func toggleApp(_ name: String) {
        if disabledApps.contains(name) {
            disabledApps.remove(name)
        } else {
            disabledApps.insert(name)
        }
    }

    func addCustomApp(_ name: String) {
        guard !name.isEmpty, !allApps.contains(name) else { return }
        customApps.insert(name)
    }

    func removeCustomApp(_ name: String) {
        customApps.remove(name)
        disabledApps.remove(name)
    }

    func isBuiltIn(_ name: String) -> Bool {
        Self.builtInApps.contains(name)
    }

    func isInstalled(_ appName: String) -> Bool {
        FileManager.default.fileExists(atPath: "/Applications/\(appName).app")
    }

    private func saveCustomApps() {
        defaults.set(Array(customApps), forKey: customAppsKey)
    }

    private func saveDisabledApps() {
        defaults.set(Array(disabledApps), forKey: disabledAppsKey)
    }
}

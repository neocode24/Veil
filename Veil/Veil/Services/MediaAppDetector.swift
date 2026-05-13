import AppKit
import Foundation

@MainActor
@Observable
final class MediaAppDetector {

    private(set) var excludedApps: Set<String> {
        didSet { saveExcludedApps() }
    }

    private let defaults = UserDefaults.standard
    private let excludedAppsKey = "veil.excludedApps"

    private(set) var runningApps: [String] = []

    func refreshRunningApps() {
        runningApps = NSWorkspace.shared.runningApplications
            .filter { app in
                app.activationPolicy == .regular
                && app.localizedName != nil
                && app.processIdentifier != ProcessInfo.processInfo.processIdentifier
            }
            .compactMap { $0.localizedName }
            .sorted()
    }

    init() {
        let saved = UserDefaults.standard.stringArray(forKey: excludedAppsKey) ?? []
        self.excludedApps = Set(saved)
    }

    func shouldDetect(_ appName: String) -> Bool {
        !excludedApps.contains(appName)
    }

    func isExcluded(_ appName: String) -> Bool {
        excludedApps.contains(appName)
    }

    func toggleExclusion(_ name: String) {
        if excludedApps.contains(name) {
            excludedApps.remove(name)
        } else {
            excludedApps.insert(name)
        }
    }

    func removeExclusion(_ name: String) {
        excludedApps.remove(name)
    }

    private func saveExcludedApps() {
        defaults.set(Array(excludedApps), forKey: excludedAppsKey)
    }
}

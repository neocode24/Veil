import AppKit
import Foundation

enum FilterMode: String {
    case exclude
    case include
}

@MainActor
@Observable
final class MediaAppDetector {

    private(set) var excludedApps: Set<String> {
        didSet { saveExcludedApps() }
    }

    private(set) var includedApps: Set<String> {
        didSet { saveIncludedApps() }
    }

    private(set) var filterMode: FilterMode {
        didSet { saveFilterMode() }
    }

    private let defaults = UserDefaults.standard
    private let excludedAppsKey = "veil.excludedApps"
    private let includedAppsKey = "veil.includedApps"
    private let filterModeKey = "veil.filterMode"

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
        let savedExcluded = UserDefaults.standard.stringArray(forKey: "veil.excludedApps") ?? []
        self.excludedApps = Set(savedExcluded)

        let savedIncluded = UserDefaults.standard.stringArray(forKey: "veil.includedApps") ?? []
        self.includedApps = Set(savedIncluded)

        let savedMode = UserDefaults.standard.string(forKey: "veil.filterMode") ?? FilterMode.exclude.rawValue
        self.filterMode = FilterMode(rawValue: savedMode) ?? .exclude
    }

    func shouldDetect(_ appName: String) -> Bool {
        switch filterMode {
        case .exclude:
            return !excludedApps.contains(appName)
        case .include:
            return includedApps.contains(appName)
        }
    }

    func isExcluded(_ appName: String) -> Bool {
        excludedApps.contains(appName)
    }

    func isIncluded(_ appName: String) -> Bool {
        includedApps.contains(appName)
    }

    // MARK: - Exclude

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

    // MARK: - Include

    func toggleInclusion(_ name: String) {
        if includedApps.contains(name) {
            includedApps.remove(name)
        } else {
            includedApps.insert(name)
        }
    }

    func removeInclusion(_ name: String) {
        includedApps.remove(name)
    }

    // MARK: - Mode

    func setFilterMode(_ mode: FilterMode) {
        filterMode = mode
    }

    // MARK: - Persistence

    private func saveExcludedApps() {
        defaults.set(Array(excludedApps), forKey: excludedAppsKey)
    }

    private func saveIncludedApps() {
        defaults.set(Array(includedApps), forKey: includedAppsKey)
    }

    private func saveFilterMode() {
        defaults.set(filterMode.rawValue, forKey: filterModeKey)
    }
}

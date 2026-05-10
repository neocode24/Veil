import SwiftUI

struct MenuBarView: View {
    @Bindable var appState: AppState
    let onRestore: () -> Void
    let onSettingsChanged: () -> Void
    let onQuit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            headerSection
            Divider()
            statusSection
            Divider()
            monitorSection
            Divider()
            settingsSection
            Divider()
            appListSection
            Divider()
            controlSection
        }
        .padding(DS.Spacing.lg)
        .frame(width: 300)
        .tint(.green)
        .onChange(of: appState.showClockOnBlanked) { _, _ in onSettingsChanged() }
        .onChange(of: appState.use24HourClock) { _, _ in onSettingsChanged() }
        .onChange(of: appState.showSecondsClock) { _, _ in onSettingsChanged() }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            Image("VeilMenuBarIcon")
                .resizable()
                .renderingMode(.template)
                .frame(width: 18, height: 18)
                .foregroundStyle(.secondary)
            Text("Veil")
                .font(.system(size: DS.Font.title, weight: .semibold))
            Spacer()
            Toggle("", isOn: $appState.isEnabled)
                .toggleStyle(.switch)
                .labelsHidden()
                .controlSize(.small)
        }
    }

    // MARK: - Status

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
            Label {
                Text("\(appState.screenCount) Displays Connected")
                    .font(.system(size: DS.Font.caption))
            } icon: {
                Image(systemName: "display")
                    .font(.system(size: 10))
            }
            .foregroundStyle(.secondary)

            if let appName = appState.fullscreenAppName {
                Label {
                    Text("Fullscreen: \(appName)")
                        .font(.system(size: DS.Font.caption))
                } icon: {
                    Image(systemName: "play.rectangle.fill")
                        .font(.system(size: 10))
                }
                .foregroundStyle(.orange)
            }
        }
    }

    // MARK: - Monitors

    private var monitorSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            Text("Monitors")
                .font(.system(size: DS.Font.tiny))
                .foregroundStyle(.tertiary)

            ForEach(NSScreen.screens, id: \.displayID) { screen in
                let name = screen.localizedName
                let isBlanked = appState.blankedDisplayNames.contains(name)
                let isExcluded = appState.isMonitorExcluded(name)

                HStack {
                    Circle()
                        .fill(isBlanked ? Color.orange : (isExcluded ? Color.gray : Color.green))
                        .frame(width: 8, height: 8)
                    Text(name)
                        .font(.system(size: DS.Font.caption))
                        .foregroundStyle(isExcluded ? .secondary : .primary)
                    Spacer()
                    if isBlanked {
                        Text("Veiled")
                            .font(.system(size: DS.Font.tiny, weight: .medium))
                            .foregroundStyle(.orange)
                    }
                    Toggle("", isOn: Binding(
                        get: { !isExcluded },
                        set: { _ in
                            appState.toggleMonitorExclusion(name)
                            onSettingsChanged()
                        }
                    ))
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .controlSize(.mini)
                }
            }
        }
    }

    // MARK: - Settings

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            HStack {
                Label("Show Clock", systemImage: "clock")
                    .font(.system(size: DS.Font.caption))
                Spacer()
                Toggle("", isOn: $appState.showClockOnBlanked)
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .controlSize(.small)
            }

            if appState.showClockOnBlanked {
                HStack {
                    Label("24-Hour", systemImage: "clock.badge")
                        .font(.system(size: DS.Font.caption))
                    Spacer()
                    Toggle("", isOn: $appState.use24HourClock)
                        .toggleStyle(.switch)
                        .labelsHidden()
                        .controlSize(.small)
                }
                .padding(.leading, DS.Spacing.lg)

                HStack {
                    Label("Seconds", systemImage: "timer")
                        .font(.system(size: DS.Font.caption))
                    Spacer()
                    Toggle("", isOn: $appState.showSecondsClock)
                        .toggleStyle(.switch)
                        .labelsHidden()
                        .controlSize(.small)
                }
                .padding(.leading, DS.Spacing.lg)
            }

        }
    }

    // MARK: - App List (collapsible)

    private var appListSection: some View {
        DisclosureGroup("Exclude Apps (\(appState.mediaAppDetector.excludedApps.count))") {
            ExcludedAppsView(appState: appState, onAppsChanged: onSettingsChanged)
        }
        .font(.system(size: DS.Font.caption))
    }

    // MARK: - Controls

    private var controlSection: some View {
        HStack {
            Button("Restore All") { onRestore() }
                .buttonStyle(.bordered)
                .controlSize(.small)
            Spacer()
            Button("Quit") { onQuit() }
                .buttonStyle(.bordered)
                .controlSize(.small)
        }
    }
}

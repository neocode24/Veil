import SwiftUI

struct MenuBarView: View {
    @Bindable var appState: AppState
    let onRestore: () -> Void
    let onSettingsChanged: () -> Void
    let onQuit: () -> Void
    @State private var showExcludeApps = false

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            dragHandle
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
        .padding(.top, DS.Spacing.xs)
        .frame(width: 300)
        .tint(.green)
        .onChange(of: appState.isEnabled) { _, _ in onSettingsChanged() }
        .onChange(of: appState.showClockOnBlanked) { _, _ in onSettingsChanged() }
        .onChange(of: appState.use24HourClock) { _, _ in onSettingsChanged() }
        .onChange(of: appState.showSecondsClock) { _, _ in onSettingsChanged() }
        .onChange(of: appState.launchAtLogin) { _, _ in onSettingsChanged() }
        .onChange(of: showExcludeApps) { _, _ in onSettingsChanged() }
        .onChange(of: appState.manualVeilActive) { _, _ in onSettingsChanged() }
    }

    // MARK: - Drag Handle

    private var dragHandle: some View {
        HStack {
            Spacer()
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.primary.opacity(0.2))
                .frame(width: 36, height: 5)
            Spacer()
        }
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

            if appState.manualVeilActive {
                Label {
                    Text("Veiled Manually")
                        .font(.system(size: DS.Font.caption))
                } icon: {
                    Image(systemName: "rectangle.on.rectangle.fill")
                        .font(.system(size: 10))
                }
                .foregroundStyle(.blue)
            }
        }
    }

    // MARK: - Monitors

    private var monitorSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            Text("Monitors")
                .font(.system(size: DS.Font.tiny))
                .foregroundStyle(.tertiary)

            ForEach(appState.screens, id: \.displayID) { screen in
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
                Label("Veil Now", systemImage: "rectangle.on.rectangle")
                    .font(.system(size: DS.Font.caption))
                Spacer()
                Text("⌃⌥⌘ V")
                    .font(.system(size: DS.Font.tiny, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Color.primary.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                Toggle("", isOn: $appState.manualVeilActive)
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .controlSize(.small)
            }

            HStack {
                Label("Launch at Login", systemImage: "power")
                    .font(.system(size: DS.Font.caption))
                Spacer()
                Toggle("", isOn: Binding(
                    get: { appState.launchAtLogin },
                    set: { appState.launchAtLogin = $0 }
                ))
                .toggleStyle(.switch)
                .labelsHidden()
                .controlSize(.small)
            }

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
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            Button(action: { withAnimation(.easeInOut(duration: 0.2)) { showExcludeApps.toggle() } }) {
                HStack(spacing: DS.Spacing.sm) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(showExcludeApps ? 90 : 0))
                    Text("Exclude Apps (\(appState.mediaAppDetector.excludedApps.count))")
                        .font(.system(size: DS.Font.caption))
                        .foregroundStyle(.primary)
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if showExcludeApps {
                ExcludedAppsView(appState: appState, onAppsChanged: onSettingsChanged, onLayout: onSettingsChanged)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - Controls

    private var controlSection: some View {
        HStack {
            Button("Restore All") { onRestore() }
                .buttonStyle(.bordered)
                .controlSize(.small)
            Spacer()
            Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")
                .font(.system(size: DS.Font.tiny))
                .foregroundStyle(.tertiary)
            Spacer()
            Button("Quit") { onQuit() }
                .buttonStyle(.bordered)
                .controlSize(.small)
        }
    }
}

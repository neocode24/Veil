import SwiftUI

struct AppListSettingsView: View {
    @Bindable var appState: AppState
    @State private var newAppName = ""

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            Text("App List")
                .font(.system(size: DS.Font.body, weight: .semibold))

            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                    ForEach(sortedApps, id: \.self) { appName in
                        appRow(appName)
                    }
                }
            }
            .frame(maxHeight: 200)

            Divider()

            HStack {
                TextField("App name", text: $newAppName)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: DS.Font.caption))
                    .onSubmit { addApp() }

                Button(action: addApp) {
                    Image(systemName: "plus.circle.fill")
                }
                .buttonStyle(.borderless)
                .disabled(newAppName.isEmpty)
            }

            Text("Enter the exact name of the running app")
                .font(.system(size: DS.Font.tiny))
                .foregroundStyle(.tertiary)
        }
        .padding(DS.Spacing.md)
    }

    private var sortedApps: [String] {
        appState.mediaAppDetector.allApps.sorted()
    }

    private func appRow(_ appName: String) -> some View {
        let isBuiltIn = appState.mediaAppDetector.isBuiltIn(appName)
        let isActive = appState.mediaAppDetector.isActive(appName)
        let isInstalled = appState.mediaAppDetector.isInstalled(appName)

        return HStack(spacing: DS.Spacing.xs) {
            Toggle("", isOn: Binding(
                get: { isActive },
                set: { _ in appState.mediaAppDetector.toggleApp(appName) }
            ))
            .toggleStyle(.switch)
            .labelsHidden()
            .controlSize(.mini)
            .tint(.green)

            Image(systemName: isBuiltIn ? "app.fill" : "app.dashed")
                .font(.system(size: 10))
                .foregroundStyle(isInstalled ? AnyShapeStyle(.secondary) : AnyShapeStyle(.quaternary))

            VStack(alignment: .leading, spacing: 1) {
                Text(appName)
                    .font(.system(size: DS.Font.caption))
                    .foregroundStyle(isActive ? .primary : .secondary)
                if !isInstalled {
                    Text("Not installed")
                        .font(.system(size: 8))
                        .foregroundStyle(.quaternary)
                }
            }

            Spacer()

            if isBuiltIn {
                Text("Default")
                    .font(.system(size: DS.Font.tiny))
                    .foregroundStyle(.quaternary)
            } else {
                Button(action: { appState.mediaAppDetector.removeCustomApp(appName) }) {
                    Image(systemName: "minus.circle.fill")
                        .foregroundStyle(.red)
                }
                .buttonStyle(.borderless)
                .font(.system(size: 10))
            }
        }
        .padding(.vertical, 2)
        .opacity(isActive ? 1.0 : 0.6)
    }

    private func addApp() {
        let trimmed = newAppName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        appState.mediaAppDetector.addCustomApp(trimmed)
        newAppName = ""
    }
}

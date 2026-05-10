import SwiftUI

struct ExcludedAppsView: View {
    @Bindable var appState: AppState
    var onAppsChanged: (() -> Void)?
    @State private var showPicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            HStack {
                Text("Exclude Apps")
                    .font(.system(size: DS.Font.body, weight: .semibold))
                Spacer()
                Button(action: { showPicker.toggle() }) {
                    Image(systemName: showPicker ? "xmark.circle.fill" : "plus.circle.fill")
                        .foregroundStyle(showPicker ? Color.secondary : Color.blue)
                }
                .buttonStyle(.borderless)
            }

            if showPicker {
                runningAppsPicker
            }

            if appState.mediaAppDetector.excludedApps.isEmpty {
                Text("No excluded apps. All fullscreen apps will trigger blanking.")
                    .font(.system(size: DS.Font.tiny))
                    .foregroundStyle(.tertiary)
            } else {
                excludedList
            }
        }
        .padding(DS.Spacing.md)
    }

    private var runningAppsPicker: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                let apps = appState.mediaAppDetector.runningApps.filter {
                    !appState.mediaAppDetector.isExcluded($0)
                }
                if apps.isEmpty {
                    Text("No running apps to add")
                        .font(.system(size: DS.Font.tiny))
                        .foregroundStyle(.tertiary)
                }
                ForEach(apps, id: \.self) { appName in
                    Button(action: {
                        appState.mediaAppDetector.toggleExclusion(appName)
                        onAppsChanged?()
                    }) {
                        HStack {
                            Image(systemName: "plus.circle")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                            Text(appName)
                                .font(.system(size: DS.Font.caption))
                                .foregroundStyle(.primary)
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 2)
                }
            }
        }
        .frame(maxHeight: 150)
    }

    private var excludedList: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
            ForEach(appState.mediaAppDetector.excludedApps.sorted(), id: \.self) { appName in
                HStack(spacing: DS.Spacing.xs) {
                    Image(systemName: "app.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)

                    Text(appName)
                        .font(.system(size: DS.Font.caption))

                    Spacer()

                    Button(action: {
                        appState.mediaAppDetector.removeExclusion(appName)
                        onAppsChanged?()
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.borderless)
                    .font(.system(size: 10))
                }
                .padding(.vertical, 2)
            }
        }
    }
}

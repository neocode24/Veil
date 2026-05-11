import AppKit
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
                Button(action: { withAnimation { showPicker.toggle() } }) {
                    Image(systemName: showPicker ? "xmark.circle.fill" : "plus.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(showPicker ? Color.secondary : Color.blue)
                }
                .buttonStyle(.borderless)
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
            }

            if showPicker {
                runningAppsPicker
                    .transition(.opacity.combined(with: .move(edge: .top)))
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
            VStack(alignment: .leading, spacing: 2) {
                let apps = appState.mediaAppDetector.runningApps.filter {
                    !appState.mediaAppDetector.isExcluded($0)
                }
                if apps.isEmpty {
                    Text("No running apps to add")
                        .font(.system(size: DS.Font.tiny))
                        .foregroundStyle(.tertiary)
                        .padding(.vertical, DS.Spacing.sm)
                }
                ForEach(apps, id: \.self) { appName in
                    AddAppRow(appName: appName) {
                        appState.mediaAppDetector.toggleExclusion(appName)
                        onAppsChanged?()
                    }
                }
            }
        }
        .frame(maxHeight: 150)
    }

    private var excludedList: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(appState.mediaAppDetector.excludedApps.sorted(), id: \.self) { appName in
                RemoveAppRow(appName: appName) {
                    appState.mediaAppDetector.removeExclusion(appName)
                    onAppsChanged?()
                }
            }
        }
    }
}

private struct AddAppRow: View {
    let appName: String
    let onAdd: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: onAdd) {
            HStack(spacing: DS.Spacing.sm) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 12))
                    .foregroundStyle(.blue)
                Text(appName)
                    .font(.system(size: DS.Font.caption))
                    .foregroundStyle(.primary)
                Spacer()
            }
            .contentShape(Rectangle())
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.btn)
                    .fill(isHovered ? Color.primary.opacity(0.08) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

private struct RemoveAppRow: View {
    let appName: String
    let onRemove: () -> Void
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: DS.Spacing.sm) {
            Image(systemName: "app.fill")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
            Text(appName)
                .font(.system(size: DS.Font.caption))
            Spacer()
            Button(action: onRemove) {
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(isHovered ? .red : .red.opacity(0.6))
            }
            .buttonStyle(.borderless)
            .frame(width: 28, height: 24)
            .contentShape(Rectangle())
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.btn)
                .fill(isHovered ? Color.primary.opacity(0.05) : Color.clear)
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

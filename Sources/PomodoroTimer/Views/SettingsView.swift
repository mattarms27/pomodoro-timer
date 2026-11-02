import SwiftUI
import UserNotifications

struct SettingsView: View {
    var body: some View {
        TabView {
            Tab("Timer", systemImage: "timer") {
                TimerSettings()
            }
            Tab("Appearance", systemImage: "circle.lefthalf.filled") {
                AppearanceSettings()
            }
            Tab("Alerts", systemImage: "bell.badge") {
                AlertSettings()
            }
        }
        .frame(width: 500)
    }
}

// MARK: - Timer

private struct TimerSettings: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings

        Form {
            Section("Durations") {
                MinutesRow(phase: .focus, minutes: $settings.focusMinutes, range: 5...90)
                MinutesRow(phase: .shortBreak, minutes: $settings.shortBreakMinutes, range: 1...30)
                MinutesRow(phase: .longBreak, minutes: $settings.longBreakMinutes, range: 5...60)
            }

            Section("Cycle") {
                LabeledContent("Long break after") {
                    HStack(spacing: 8) {
                        Text("^[\(settings.sessionsBeforeLongBreak) session](inflect: true)")
                            .monospacedDigit()
                            .contentTransition(.numericText())
                        Stepper("Long break after", value: $settings.sessionsBeforeLongBreak, in: 2...8)
                            .labelsHidden()
                    }
                    .animation(.snappy, value: settings.sessionsBeforeLongBreak)
                }
                Toggle("Start breaks automatically", isOn: $settings.autoStartBreaks)
                Toggle("Start focus sessions automatically", isOn: $settings.autoStartFocus)
            }

            Section {
                HStack {
                    Spacer()
                    Button("Restore Defaults") {
                        withAnimation { settings.resetTimerDefaults() }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .scrollDisabled(true)
        .fixedSize(horizontal: false, vertical: true)
    }
}

private struct MinutesRow: View {
    let phase: TimerPhase
    @Binding var minutes: Int
    let range: ClosedRange<Int>

    var body: some View {
        LabeledContent {
            HStack(spacing: 8) {
                Text("\(minutes) min")
                    .monospacedDigit()
                    .contentTransition(.numericText())
                Stepper(phase.title, value: $minutes, in: range)
                    .labelsHidden()
            }
            .animation(.snappy, value: minutes)
        } label: {
            Label {
                Text(phase.title)
            } icon: {
                Image(systemName: phase.symbol)
                    .foregroundStyle(phase.tint)
                    .frame(width: 22)
            }
        }
    }
}

// MARK: - Appearance

private struct AppearanceSettings: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings

        Form {
            Section {
                HStack(spacing: 20) {
                    Spacer(minLength: 0)
                    ForEach(AppearanceMode.allCases) { mode in
                        AppearanceOption(mode: mode, isSelected: settings.appearance == mode) {
                            withAnimation(.smooth) { settings.appearance = mode }
                        }
                    }
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 6)
            } header: {
                Text("Appearance")
            } footer: {
                Text("Automatic matches your Mac's appearance in System Settings.")
                    .foregroundStyle(.secondary)
            }

            Section("Menu Bar") {
                Toggle("Show timer in menu bar", isOn: $settings.showInMenuBar)
            }
        }
        .formStyle(.grouped)
        .scrollDisabled(true)
        .fixedSize(horizontal: false, vertical: true)
    }
}

/// A thumbnail of a tiny window, in the style of System Settings' appearance picker.
private struct AppearanceOption: View {
    let mode: AppearanceMode
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                thumbnail
                    .frame(width: 88, height: 60)
                    .clipShape(.rect(cornerRadius: 8, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(.separator, lineWidth: 1)
                    }
                    .padding(3)
                    .overlay {
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .strokeBorder(Color.accentColor, lineWidth: 3)
                            .opacity(isSelected ? 1 : 0)
                            .scaleEffect(isSelected ? 1 : 1.08)
                    }

                Text(mode.title)
                    .font(.callout)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(isSelected ? .primary : .secondary)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    @ViewBuilder
    private var thumbnail: some View {
        switch mode {
        case .light:
            MiniWindow(isDark: false)
        case .dark:
            MiniWindow(isDark: true)
        case .system:
            ZStack {
                MiniWindow(isDark: false)
                MiniWindow(isDark: true)
                    .mask {
                        GeometryReader { proxy in
                            Path { path in
                                path.move(to: CGPoint(x: proxy.size.width * 0.62, y: 0))
                                path.addLine(to: CGPoint(x: proxy.size.width, y: 0))
                                path.addLine(to: CGPoint(x: proxy.size.width, y: proxy.size.height))
                                path.addLine(to: CGPoint(x: proxy.size.width * 0.38, y: proxy.size.height))
                                path.closeSubpath()
                            }
                        }
                    }
            }
        }
    }
}

private struct MiniWindow: View {
    let isDark: Bool

    var body: some View {
        let background = isDark ? Color(white: 0.16) : Color(white: 0.97)
        let chrome = isDark ? Color(white: 0.24) : Color(white: 0.88)
        let tint = TimerPhase.focus.tint

        ZStack(alignment: .topLeading) {
            LinearGradient(
                colors: [tint.opacity(isDark ? 0.35 : 0.25), background],
                startPoint: .center,
                endPoint: .topLeading
            )
            .background(background)

            HStack(spacing: 2.5) {
                ForEach([Color.red, .yellow, .green], id: \.self) { color in
                    Circle().fill(color.opacity(0.9)).frame(width: 4, height: 4)
                }
            }
            .padding(5)

            // Centered as a group, with the gap wide enough that the Automatic thumbnail's
            // diagonal split passes between the circle and the lines without touching either.
            HStack(spacing: 18) {
                Circle()
                    .strokeBorder(tint, lineWidth: 3)
                    .frame(width: 26, height: 26)

                VStack(spacing: 3) {
                    ForEach(0..<3, id: \.self) { _ in
                        Capsule().fill(chrome).frame(width: 18, height: 3)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .offset(y: 3)
        }
    }
}

// MARK: - Alerts

private struct AlertSettings: View {
    @Environment(AppSettings.self) private var settings
    @Environment(Notifier.self) private var notifier
    @ViewState private var notificationsDenied = false

    var body: some View {
        @Bindable var settings = settings

        Form {
            Section("Sound") {
                Toggle("Play a sound when a phase ends", isOn: $settings.playSound)
                Picker("Sound", selection: $settings.alertSound) {
                    ForEach(AppSettings.alertSounds, id: \.self) { name in
                        Text(name).tag(name)
                    }
                }
                .disabled(!settings.playSound)
                .onChange(of: settings.alertSound) { _, name in
                    notifier.preview(sound: name)
                }
            }

            Section {
                Toggle("Show a notification when a phase ends", isOn: $settings.showNotifications)
            } header: {
                Text("Notifications")
            } footer: {
                if notificationsDenied && settings.showNotifications {
                    HStack {
                        Label("Notifications are turned off for Pomodoro Timer.", systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Open System Settings…") {
                            if let url = URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                    }
                    .font(.callout)
                }
            }
        }
        .formStyle(.grouped)
        .scrollDisabled(true)
        .fixedSize(horizontal: false, vertical: true)
        .task { await refreshAuthorization() }
    }

    private func refreshAuthorization() async {
        guard Bundle.main.bundleIdentifier != nil else { return }
        let status = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
        notificationsDenied = status == .denied
    }
}

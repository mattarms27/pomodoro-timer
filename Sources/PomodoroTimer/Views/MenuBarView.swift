import SwiftUI

/// The status item: an icon while idle, plus the countdown once a session starts.
struct MenuBarLabel: View {
    let engine: TimerEngine

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: engine.isIdle ? "timer" : engine.phase.symbol)
            if !engine.isIdle {
                Text(engine.formattedRemaining)
                    .monospacedDigit()
            }
        }
    }
}

/// The compact popover shown from the menu bar.
struct MenuBarView: View {
    @Environment(TimerEngine.self) private var engine
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 14) {
                ProgressRing(fraction: 1 - engine.progress, tint: engine.phase.tint, lineWidth: 6)
                    .frame(width: 54, height: 54)
                    .animation(.linear(duration: 0.2), value: engine.progress)

                VStack(alignment: .leading, spacing: 2) {
                    Text(engine.phase.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(engine.phase.tint)
                    Text(engine.formattedRemaining)
                        .font(.system(size: 30, weight: .light, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText(countsDown: true))
                        .animation(.snappy, value: engine.remainingSeconds)
                }
                Spacer(minLength: 0)
            }

            TimerControls(compact: true)

            Divider()

            HStack {
                Button("Open Pomodoro Timer") {
                    openWindow(id: WindowID.main)
                    NSApp.activate()
                }
                Spacer()
                SettingsLink {
                    Image(systemName: "gearshape")
                }
                .help("Settings")
                Button("Quit") { NSApp.terminate(nil) }
            }
            .buttonStyle(.borderless)
            .font(.callout)
        }
        .padding(16)
        .frame(width: 280)
    }
}

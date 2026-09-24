import SwiftUI

/// The Timer menu and the View ▸ Appearance submenu.
struct TimerCommands: Commands {
    let engine: TimerEngine
    @Bindable var settings: AppSettings

    var body: some Commands {
        CommandMenu("Timer") {
            Button(engine.isRunning ? "Pause" : "Start") {
                withAnimation(.bouncy) { engine.toggle() }
            }
            .keyboardShortcut(.return, modifiers: .command)

            Button("Reset") {
                withAnimation(.bouncy) { engine.reset() }
            }
            .keyboardShortcut("r", modifiers: .command)
            .disabled(engine.isIdle)

            Button("Skip to Next Phase") {
                withAnimation(.bouncy) { engine.skip() }
            }
            .keyboardShortcut(.rightArrow, modifiers: [.command, .option])

            Divider()

            ForEach(Array(TimerPhase.allCases.enumerated()), id: \.element) { index, phase in
                Button(phase.title) {
                    withAnimation(.smooth) { engine.select(phase) }
                }
                .keyboardShortcut(KeyEquivalent(Character("\(index + 1)")), modifiers: .command)
            }
        }

        CommandGroup(after: .toolbar) {
            Picker("Appearance", selection: $settings.appearance) {
                ForEach(AppearanceMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            Divider()
        }
    }
}

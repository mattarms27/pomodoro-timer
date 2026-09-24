import SwiftUI

struct ContentView: View {
    @Environment(TimerEngine.self) private var engine

    var body: some View {
        TimerView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .frame(minWidth: 460, minHeight: 560)
            .background {
                PhaseBackground(phase: engine.phase, isRunning: engine.isRunning)
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    PhasePicker()
                }
            }
            .toolbar(removing: .title)
            .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
    }
}

/// The Focus / Short Break / Long Break switcher that lives in the toolbar.
struct PhasePicker: View {
    @Environment(TimerEngine.self) private var engine

    var body: some View {
        Picker("Phase", selection: selection) {
            ForEach(TimerPhase.allCases) { phase in
                Text(phase.title).tag(phase)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .fixedSize()
    }

    private var selection: Binding<TimerPhase> {
        Binding {
            engine.phase
        } set: { phase in
            withAnimation(.smooth(duration: 0.5)) { engine.select(phase) }
        }
    }
}

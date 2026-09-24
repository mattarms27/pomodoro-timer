import SwiftUI

struct ContentView: View {
    @Environment(TimerEngine.self) private var engine
    @Environment(TaskStore.self) private var tasks
    @AppStorage("showTasks") private var showTasks = true

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
            .inspector(isPresented: $showTasks) {
                TaskListView()
                    .inspectorColumnWidth(min: 260, ideal: 300, max: 420)
                    .toolbar {
                        ToolbarItem(placement: .primaryAction) {
                            Spacer()
                        }
                        ToolbarItem(placement: .primaryAction) {
                            tasksToggle
                        }
                    }
            }
            .onChange(of: tasks.wantsNewTaskFocus) { _, wantsFocus in
                if wantsFocus { showTasks = true }
            }
            .toolbar(removing: .title)
            .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
    }

    private var tasksToggle: some View {
        Button {
            withAnimation(.smooth) { showTasks.toggle() }
        } label: {
            Label("Tasks", systemImage: "checklist")
        }
        .help(showTasks ? "Hide Tasks" : "Show Tasks")
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

import SwiftUI

struct ContentView: View {
    @Environment(TimerEngine.self) private var engine
    @Environment(TaskStore.self) private var tasks
    @AppStorage("showTasks") private var showTasks = true

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                // Lives in the content rather than the toolbar: a centered toolbar item
                // gets cross-faded between positions when the inspector opens or closes,
                // which reads as ghosting. In the content it simply slides with the layout.
                // It's drawn up into the title bar strip, centered on the window controls.
                PhasePicker()
                    .frame(maxWidth: .infinity)
                    .frame(height: proxy.safeAreaInsets.top)
                    .background { TitleBarDragArea() }
                TimerView()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea(edges: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(minWidth: 460, minHeight: 560)
        .background {
            PhaseBackground(phase: engine.phase, isRunning: engine.isRunning)
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

/// Since the phase picker's strip covers the title bar, this restores the title
/// bar's behavior in the empty space around it: drag to move the window, and
/// double-click to zoom or minimize, per System Settings.
private struct TitleBarDragArea: View {
    var body: some View {
        Color.clear
            .contentShape(.rect)
            .gesture(WindowDragGesture())
            .onTapGesture(count: 2) {
                let window = NSApp.keyWindow
                switch UserDefaults.standard.string(forKey: "AppleActionOnDoubleClick") {
                case "Minimize": window?.miniaturize(nil)
                case "None": break
                default: window?.zoom(nil)
                }
            }
    }
}

/// The Focus / Short Break / Long Break switcher in the title bar strip: a glass
/// capsule whose tinted selection slides between phases.
struct PhasePicker: View {
    @Environment(TimerEngine.self) private var engine
    @Namespace private var selection

    var body: some View {
        HStack(spacing: 2) {
            ForEach(TimerPhase.allCases) { phase in
                let isSelected = phase == engine.phase

                Button {
                    withAnimation(.smooth(duration: 0.5)) { engine.select(phase) }
                } label: {
                    Text(phase.title)
                        .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                        .foregroundStyle(isSelected ? AnyShapeStyle(.primary) : AnyShapeStyle(.secondary))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 7)
                        .background {
                            if isSelected {
                                Capsule()
                                    .fill(phase.tint.opacity(0.3))
                                    .matchedGeometryEffect(id: "selection", in: selection)
                            }
                        }
                        .contentShape(.capsule)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(4)
        .glassEffect(.regular, in: .capsule)
        .animation(.smooth(duration: 0.4), value: engine.phase)
    }
}

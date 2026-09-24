import SwiftUI

/// Explicit text colors for the task pane. The sidebar list's vibrant `.secondary`
/// and `.tertiary` styles wash out over the phase gradient.
private enum PaneText {
    static let secondary = Color.primary.opacity(0.75)
    static let tertiary = Color.primary.opacity(0.55)
}

struct TaskListView: View {
    @Environment(TaskStore.self) private var store
    @Environment(TimerEngine.self) private var engine

    @AppStorage("showCompletedTasks") private var showCompleted = true
    @ViewState private var newTaskTitle = ""
    @FocusState private var isNewTaskFieldFocused: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                // The pane title sits in the title bar strip, level with the Tasks button.
                paneHeader
                    .frame(height: proxy.safeAreaInsets.top)
                taskList
            }
            .ignoresSafeArea(edges: .top)
        }
        .background {
            // A scrim that sets the pane apart from the timer and lifts text contrast:
            // darker in Dark Mode, lighter in Light Mode.
            Rectangle()
                .fill(colorScheme == .dark ? Color.black.opacity(0.32) : Color.white.opacity(0.5))
                .overlay(alignment: .leading) {
                    Rectangle()
                        .fill(.separator)
                        .frame(width: 1)
                }
                .ignoresSafeArea()
        }
        .animation(.smooth(duration: 0.35), value: store.tasks)
        .animation(.smooth(duration: 0.35), value: store.activeTaskID)
        .onChange(of: store.wantsNewTaskFocus, initial: true) { _, wantsFocus in
            guard wantsFocus else { return }
            isNewTaskFieldFocused = true
            store.wantsNewTaskFocus = false
        }
    }

    private var paneHeader: some View {
        Text("To Do")
            .font(.title3.weight(.bold))
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 18)
            .background { TitleBarDragArea() }
            .accessibilityAddTraits(.isHeader)
    }

    private var taskList: some View {
        List {
            Section {
                ForEach(store.openTasks) { task in
                    TaskRow(task: task, isActive: task.id == store.activeTaskID)
                }
                .onMove { store.moveOpenTasks(fromOffsets: $0, toOffset: $1) }
            }

            if !store.doneTasks.isEmpty {
                Section(isExpanded: $showCompleted) {
                    ForEach(store.doneTasks) { task in
                        TaskRow(task: task, isActive: false)
                    }
                } header: {
                    HStack {
                        Text("Completed")
                            .foregroundStyle(PaneText.secondary)
                        Spacer()
                        Button("Clear") {
                            withAnimation(.smooth) { store.clearCompleted() }
                        }
                        .buttonStyle(.borderless)
                        .font(.caption)
                        .foregroundStyle(PaneText.secondary)
                        .padding(.trailing, 8)
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .overlay {
            if store.tasks.isEmpty {
                ContentUnavailableView {
                    Label {
                        Text("No Tasks")
                            .foregroundStyle(.primary)
                    } icon: {
                        Image(systemName: "checklist")
                            .foregroundStyle(PaneText.tertiary)
                    }
                } description: {
                    // Explicit break keeps two even lines at any pane width (no widowed word).
                    Text("Add a task, and each focus session\nwill count toward it.")
                        .font(.callout)
                        .foregroundStyle(PaneText.secondary)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            newTaskField
        }
    }

    private var newTaskField: some View {
        HStack(spacing: 8) {
            Image(systemName: "plus.circle.fill")
                .font(.title3)
                .foregroundStyle(engine.phase.tint)
                .symbolEffect(.bounce, value: store.tasks.count)

            TextField("New Task", text: $newTaskTitle, prompt: Text("New Task").foregroundStyle(PaneText.tertiary))
                .textFieldStyle(.plain)
                .focused($isNewTaskFieldFocused)
                .onSubmit(addTask)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .glassEffect(.regular.interactive(), in: .capsule)
        .padding(12)
    }

    private func addTask() {
        withAnimation(.bouncy) {
            store.add(title: newTaskTitle)
        }
        newTaskTitle = ""
        isNewTaskFieldFocused = true
    }
}

private struct TaskRow: View {
    let task: TaskItem
    let isActive: Bool

    @Environment(TaskStore.self) private var store
    @Environment(TimerEngine.self) private var engine
    @ViewState private var isHovering = false

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Button {
                withAnimation(.bouncy) { store.toggleDone(task.id) }
            } label: {
                Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(task.isDone ? AnyShapeStyle(tint) : AnyShapeStyle(PaneText.tertiary))
                    .contentTransition(.symbolEffect(.replace))
                    .symbolEffect(.bounce, value: task.isDone)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(task.isDone ? "Mark as not done" : "Mark as done")

            VStack(alignment: .leading, spacing: 4) {
                TextField("Task", text: titleBinding, axis: .vertical)
                    .textFieldStyle(.plain)
                    .strikethrough(task.isDone, color: PaneText.tertiary)
                    .foregroundStyle(task.isDone ? PaneText.secondary : .primary)

                PomodoroEstimate(task: task, tint: tint)
            }

            Spacer(minLength: 0)

            if isActive {
                Image(systemName: "scope")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(tint)
                    .symbolEffect(.pulse, isActive: engine.isRunning && engine.phase == .focus)
                    .transition(.scale.combined(with: .opacity))
                    .help("Current task")
            } else if isHovering && !task.isDone {
                Button {
                    withAnimation(.smooth) { store.setActive(task.id) }
                } label: {
                    Image(systemName: "scope")
                        .font(.callout)
                        .foregroundStyle(PaneText.secondary)
                }
                .buttonStyle(.plain)
                .transition(.opacity)
                .help("Focus on this task")
            }
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 4)
        .background {
            if isActive {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(tint.opacity(0.14))
                    .padding(.horizontal, -6)
                    .transition(.opacity)
            }
        }
        .contentShape(.rect)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.15)) { isHovering = hovering }
        }
        .contextMenu { contextMenu }
        .transition(.asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .opacity.combined(with: .scale(scale: 0.9))
        ))
    }

    @ViewBuilder
    private var contextMenu: some View {
        if !task.isDone {
            Button("Focus on This Task", systemImage: "scope") {
                store.setActive(task.id)
            }
            .disabled(isActive)

            Picker("Estimate", selection: estimateBinding) {
                ForEach(1...TaskStore.maxEstimate, id: \.self) { count in
                    Text("^[\(count) Pomodoro](inflect: true)").tag(count)
                }
            }
        }

        Button(
            task.isDone ? "Mark as Not Done" : "Mark as Done",
            systemImage: task.isDone ? "circle" : "checkmark.circle"
        ) {
            withAnimation(.bouncy) { store.toggleDone(task.id) }
        }

        Divider()

        Button("Delete", systemImage: "trash", role: .destructive) {
            withAnimation(.smooth) { store.delete(task.id) }
        }
    }

    private var tint: Color { TimerPhase.focus.tint }

    private var titleBinding: Binding<String> {
        Binding { task.title } set: { store.rename(task.id, to: $0) }
    }

    private var estimateBinding: Binding<Int> {
        Binding { task.estimate } set: { store.setEstimate(task.id, to: $0) }
    }
}

/// Dots for estimated Pomodoros, filled as they're completed. Click to change the estimate.
private struct PomodoroEstimate: View {
    let task: TaskItem
    let tint: Color

    @Environment(TaskStore.self) private var store

    var body: some View {
        Menu {
            ForEach(1...TaskStore.maxEstimate, id: \.self) { count in
                Button("^[\(count) Pomodoro](inflect: true)") {
                    withAnimation(.bouncy) { store.setEstimate(task.id, to: count) }
                }
            }
        } label: {
            HStack(spacing: 6) {
                HStack(spacing: 3) {
                    ForEach(0..<max(task.estimate, task.completedPomodoros), id: \.self) { index in
                        Circle()
                            .strokeBorder(tint.opacity(0.6), lineWidth: 1)
                            .background(Circle().fill(index < task.completedPomodoros ? tint : .clear))
                            .frame(width: 7, height: 7)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                Text("\(task.completedPomodoros)/\(task.estimate)")
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(PaneText.secondary)
                    .contentTransition(.numericText())
            }
            .contentShape(.rect)
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .menuIndicator(.hidden)
        .fixedSize()
        .disabled(task.isDone)
        .help("Estimated Pomodoros")
        .accessibilityLabel("\(task.completedPomodoros) of \(task.estimate) Pomodoros")
    }
}

import SwiftUI

struct TaskListView: View {
    @Environment(TaskStore.self) private var store
    @Environment(TimerEngine.self) private var engine

    @AppStorage("showCompletedTasks") private var showCompleted = true
    @ViewState private var newTaskTitle = ""
    @FocusState private var isNewTaskFieldFocused: Bool

    var body: some View {
        List {
            Section {
                ForEach(store.openTasks) { task in
                    TaskRow(task: task, isActive: task.id == store.activeTaskID)
                }
                .onMove { store.moveOpenTasks(fromOffsets: $0, toOffset: $1) }
            } header: {
                Text("To Do")
            }

            if !store.doneTasks.isEmpty {
                Section(isExpanded: $showCompleted) {
                    ForEach(store.doneTasks) { task in
                        TaskRow(task: task, isActive: false)
                    }
                } header: {
                    HStack {
                        Text("Completed")
                        Spacer()
                        Button("Clear") {
                            withAnimation(.smooth) { store.clearCompleted() }
                        }
                        .buttonStyle(.borderless)
                        .font(.caption)
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .overlay {
            if store.tasks.isEmpty {
                ContentUnavailableView {
                    Label("No Tasks", systemImage: "checklist")
                } description: {
                    Text("Add what you're working on, and each focus session will count toward it.")
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            newTaskField
        }
        .animation(.smooth(duration: 0.35), value: store.tasks)
        .animation(.smooth(duration: 0.35), value: store.activeTaskID)
        .onChange(of: store.wantsNewTaskFocus, initial: true) { _, wantsFocus in
            guard wantsFocus else { return }
            isNewTaskFieldFocused = true
            store.wantsNewTaskFocus = false
        }
    }

    private var newTaskField: some View {
        HStack(spacing: 8) {
            Image(systemName: "plus.circle.fill")
                .font(.title3)
                .foregroundStyle(engine.phase.tint)
                .symbolEffect(.bounce, value: store.tasks.count)

            TextField("New Task", text: $newTaskTitle)
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
                    .foregroundStyle(task.isDone ? AnyShapeStyle(tint) : AnyShapeStyle(.tertiary))
                    .contentTransition(.symbolEffect(.replace))
                    .symbolEffect(.bounce, value: task.isDone)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(task.isDone ? "Mark as not done" : "Mark as done")

            VStack(alignment: .leading, spacing: 4) {
                TextField("Task", text: titleBinding, axis: .vertical)
                    .textFieldStyle(.plain)
                    .strikethrough(task.isDone, color: .secondary)
                    .foregroundStyle(task.isDone ? .secondary : .primary)

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
                        .foregroundStyle(.secondary)
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
                    .foregroundStyle(.secondary)
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

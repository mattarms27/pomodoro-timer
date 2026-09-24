import Foundation
import Observation

struct TaskItem: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var isDone = false
    /// How many Pomodoros the user expects this task to take.
    var estimate = 1
    var completedPomodoros = 0
    var completedAt: Date?
}

/// The task list, persisted as JSON in Application Support.
@Observable
final class TaskStore {
    static let maxEstimate = 8

    private(set) var tasks: [TaskItem] = []
    /// The task that finished focus sessions are credited to.
    private(set) var activeTaskID: UUID?

    /// Set by the New Task command; the task list focuses its text field and clears it.
    var wantsNewTaskFocus = false

    @ObservationIgnored private let fileURL: URL

    init(fileURL: URL = TaskStore.defaultFileURL) {
        self.fileURL = fileURL
        load()
    }

    // MARK: Queries

    var openTasks: [TaskItem] { tasks.filter { !$0.isDone } }

    var doneTasks: [TaskItem] {
        tasks.filter(\.isDone).sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
    }

    var activeTask: TaskItem? {
        tasks.first { $0.id == activeTaskID }
    }

    // MARK: Editing

    func add(title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let task = TaskItem(title: trimmed)
        let insertionIndex = tasks.lastIndex { !$0.isDone }.map { $0 + 1 } ?? 0
        tasks.insert(task, at: insertionIndex)
        if activeTask == nil || activeTask?.isDone == true {
            activeTaskID = task.id
        }
        save()
    }

    func toggleDone(_ id: UUID) {
        update(id) { task in
            task.isDone.toggle()
            task.completedAt = task.isDone ? Date() : nil
        }
        // Finishing the current task hands focus to the next one in line.
        if id == activeTaskID, activeTask?.isDone == true {
            activeTaskID = openTasks.first?.id
            save()
        }
    }

    func rename(_ id: UUID, to title: String) {
        update(id) { $0.title = title }
    }

    func setEstimate(_ id: UUID, to estimate: Int) {
        update(id) { $0.estimate = min(max(estimate, 1), Self.maxEstimate) }
    }

    func setActive(_ id: UUID?) {
        guard activeTaskID != id else { return }
        activeTaskID = id
        save()
    }

    func delete(_ id: UUID) {
        tasks.removeAll { $0.id == id }
        if activeTaskID == id {
            activeTaskID = openTasks.first?.id
        }
        save()
    }

    func clearCompleted() {
        tasks.removeAll(where: \.isDone)
        save()
    }

    /// Reorders within the open tasks; completed tasks keep their own ordering.
    func moveOpenTasks(fromOffsets source: IndexSet, toOffset destination: Int) {
        var open = openTasks
        open.move(fromOffsets: source, toOffset: destination)
        tasks = open + tasks.filter(\.isDone)
        save()
    }

    /// Credits a finished focus session to the active task.
    func recordPomodoro() {
        guard let activeTaskID else { return }
        update(activeTaskID) { $0.completedPomodoros += 1 }
    }

    private func update(_ id: UUID, _ change: (inout TaskItem) -> Void) {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        change(&tasks[index])
        save()
    }

    // MARK: Persistence

    private struct Snapshot: Codable {
        var tasks: [TaskItem]
        var activeTaskID: UUID?
    }

    static var defaultFileURL: URL {
        URL.applicationSupportDirectory
            .appending(path: "PomodoroTimer", directoryHint: .isDirectory)
            .appending(path: "tasks.json")
    }

    private func load() {
        guard
            let data = try? Data(contentsOf: fileURL),
            let snapshot = try? JSONDecoder().decode(Snapshot.self, from: data)
        else { return }
        tasks = snapshot.tasks
        activeTaskID = snapshot.activeTaskID
    }

    private func save() {
        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let data = try JSONEncoder().encode(Snapshot(tasks: tasks, activeTaskID: activeTaskID))
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to save tasks: \(error)")
        }
    }
}

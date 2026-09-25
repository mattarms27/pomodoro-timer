import Foundation
import Observation

/// Drives the Pomodoro cycle. Time is derived from an end date rather than
/// counted down tick by tick, so the timer stays accurate across sleep and App Nap.
@Observable
final class TimerEngine {
    enum State: Equatable {
        case idle
        case running(endDate: Date)
        case paused(remaining: TimeInterval)
    }

    private(set) var phase: TimerPhase = .focus
    private(set) var state: State = .idle
    /// Focus sessions finished in the current cycle (resets after a long break).
    private(set) var completedInCycle = 0
    private(set) var stats: DailyStats
    /// Increments each time a phase finishes naturally; views use it to celebrate.
    private(set) var completionCount = 0

    /// Updated by the ticker; views read `remaining`, which depends on it.
    private var now = Date()

    /// Called after a phase finishes naturally (not when skipped).
    @ObservationIgnored var onPhaseCompleted: ((TimerPhase) -> Void)?

    @ObservationIgnored private let settings: AppSettings
    @ObservationIgnored private let notifier: Notifier
    @ObservationIgnored private var ticker: Task<Void, Never>?
    @ObservationIgnored private var activity: NSObjectProtocol?

    init(settings: AppSettings, notifier: Notifier) {
        self.settings = settings
        self.notifier = notifier
        self.stats = DailyStats.load()
    }

    // MARK: Derived state

    var duration: TimeInterval { settings.duration(for: phase) }

    var remaining: TimeInterval {
        switch state {
        case .idle: duration
        case .running(let endDate): max(0, endDate.timeIntervalSince(now))
        case .paused(let remaining): remaining
        }
    }

    /// 0 at the start of a phase, 1 when it's finished.
    var progress: Double {
        guard duration > 0 else { return 0 }
        return min(1, max(0, 1 - remaining / duration))
    }

    var isRunning: Bool {
        if case .running = state { true } else { false }
    }

    var isPaused: Bool {
        if case .paused = state { true } else { false }
    }

    var isIdle: Bool { state == .idle }

    /// Whole seconds left, rounded up so "25:00" shows for the full first second.
    var remainingSeconds: Int { Int(remaining.rounded(.up)) }

    var formattedRemaining: String {
        let seconds = remainingSeconds
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    // MARK: Controls

    func toggle() {
        isRunning ? pause() : start()
    }

    func start() {
        guard !isRunning else { return }
        now = Date()
        let endDate = now.addingTimeInterval(remaining)
        state = .running(endDate: endDate)
        notifier.schedulePhaseEnd(phase, at: endDate)
        startTicker()
    }

    func pause() {
        guard isRunning else { return }
        now = Date()
        state = .paused(remaining: remaining)
        stopTicker()
        notifier.cancelPending()
    }

    func reset() {
        stopTicker()
        notifier.cancelPending()
        state = .idle
    }

    /// Jump to the next phase without counting the current one as completed.
    func skip() {
        advance(completed: false)
    }

    func select(_ newPhase: TimerPhase) {
        guard newPhase != phase || !isIdle else { return }
        reset()
        phase = newPhase
    }

    // MARK: Cycle

    private func finishPhase() {
        let finished = phase
        if finished == .focus {
            stats.record(focusSeconds: duration)
        }
        completionCount += 1
        notifier.releasePending()
        notifier.playCompletionSound()
        onPhaseCompleted?(finished)
        advance(completed: true)
    }

    private func advance(completed: Bool) {
        let previous = phase
        reset()

        switch previous {
        case .focus:
            if completed { completedInCycle += 1 }
            let longBreakDue = completedInCycle > 0
                && completedInCycle % settings.sessionsBeforeLongBreak == 0
            phase = longBreakDue ? .longBreak : .shortBreak
        case .longBreak:
            completedInCycle = 0
            phase = .focus
        case .shortBreak:
            phase = .focus
        }

        let autoStart = phase.isBreak ? settings.autoStartBreaks : settings.autoStartFocus
        if completed && autoStart {
            start()
        }
    }

    // MARK: Ticking

    private func startTicker() {
        stopTicker()
        activity = ProcessInfo.processInfo.beginActivity(
            options: [.userInitiated, .idleSystemSleepDisabled],
            reason: "Pomodoro timer running"
        )
        ticker = Task { [weak self] in
            while !Task.isCancelled {
                guard let delay = self?.delayUntilNextTick() else { return }
                try? await Task.sleep(for: .seconds(delay), tolerance: .milliseconds(5))
                guard let self, !Task.isCancelled else { return }
                self.now = Date()
                if self.remaining <= 0 {
                    self.finishPhase()
                    return
                }
            }
        }
    }

    /// Ticks land on a fixed grid measured back from the end date, so each whole
    /// second is observed just after it rolls over. A free-running sleep drifts
    /// against that grid, which makes an occasional second visibly shorter.
    private func delayUntilNextTick() -> TimeInterval {
        let interval: TimeInterval = 0.2
        guard case .running(let endDate) = state else { return interval }
        let intoTick = max(0, endDate.timeIntervalSinceNow)
            .truncatingRemainder(dividingBy: interval)
        // Wake slightly past the boundary so rounding up already shows the new second.
        return intoTick + 0.01
    }

    private func stopTicker() {
        ticker?.cancel()
        ticker = nil
        if let activity {
            ProcessInfo.processInfo.endActivity(activity)
            self.activity = nil
        }
    }
}

/// Focus totals for the current day.
struct DailyStats: Codable, Equatable {
    var day: String
    var focusSessions = 0
    var focusSeconds: TimeInterval = 0

    private static let key = "dailyStats"

    static var today: String {
        Date().formatted(.iso8601.year().month().day())
    }

    static func load() -> DailyStats {
        guard
            let data = UserDefaults.standard.data(forKey: key),
            let stats = try? JSONDecoder().decode(DailyStats.self, from: data),
            stats.day == today
        else { return DailyStats(day: today) }
        return stats
    }

    mutating func record(focusSeconds seconds: TimeInterval) {
        if day != Self.today { self = DailyStats(day: Self.today) }
        focusSessions += 1
        focusSeconds += seconds
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.key)
        }
    }
}

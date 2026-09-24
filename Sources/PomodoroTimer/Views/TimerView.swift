import SwiftUI

struct TimerView: View {
    @Environment(TimerEngine.self) private var engine
    @Environment(AppSettings.self) private var settings
    @Environment(TaskStore.self) private var tasks

    var body: some View {
        VStack(spacing: 32) {
            Spacer(minLength: 12)

            ZStack {
                ProgressRing(fraction: 1 - engine.progress, tint: engine.phase.tint)
                    .animation(ringAnimation, value: engine.progress)

                VStack(spacing: 6) {
                    PhaseLabel(phase: engine.phase)

                    Text(engine.formattedRemaining)
                        .font(.system(size: 76, weight: .light, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText(countsDown: true))
                        .animation(.snappy, value: engine.remainingSeconds)

                    Text(statusText)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .frame(maxWidth: 220)
                        .contentTransition(.opacity)
                        .id(statusText)
                        .transition(.blurReplace)
                }
            }
            .frame(maxWidth: 330, maxHeight: 330)
            .aspectRatio(1, contentMode: .fit)
            .celebrates(trigger: engine.completionCount)

            SessionIndicator(
                completed: engine.completedInCycle,
                total: settings.sessionsBeforeLongBreak,
                currentProgress: engine.phase == .focus ? engine.progress : nil,
                tint: TimerPhase.focus.tint
            )

            TimerControls()

            Spacer(minLength: 12)

            TodaySummary(stats: engine.stats)
                .padding(.bottom, 16)
        }
        .padding(.horizontal, 32)
        .animation(.smooth(duration: 0.6), value: engine.phase)
        .animation(.smooth, value: engine.isRunning)
    }

    /// Short linear steps while ticking read as continuous motion; larger jumps
    /// (reset, phase change) get a springy sweep instead.
    private var ringAnimation: Animation {
        engine.isRunning ? .linear(duration: 0.2) : .spring(duration: 0.8, bounce: 0.15)
    }

    private var statusText: String {
        if engine.phase == .focus, !engine.isPaused, let task = tasks.activeTask {
            return task.title
        }
        return switch engine.state {
        case .idle: "Ready"
        case .running: engine.phase.isBreak ? "Take a breather" : "Stay focused"
        case .paused: "Paused"
        }
    }
}

private struct PhaseLabel: View {
    let phase: TimerPhase

    var body: some View {
        Label(phase.title, systemImage: phase.symbol)
            .font(.headline)
            .foregroundStyle(phase.tint)
            .contentTransition(.symbolEffect(.replace))
            .id(phase)
            .transition(.blurReplace)
    }
}

/// One capsule per focus session in the cycle. The current session stretches
/// out and fills as it progresses, like a page indicator.
struct SessionIndicator: View {
    let completed: Int
    let total: Int
    /// Progress of the in-flight focus session, or nil during a break.
    let currentProgress: Double?
    let tint: Color

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { index in
                let isCurrent = index == completed % max(total, 1) && currentProgress != nil
                let isDone = index < completed

                Capsule()
                    .fill(tint.opacity(0.2))
                    .overlay(alignment: .leading) {
                        GeometryReader { proxy in
                            Capsule()
                                .fill(tint)
                                .frame(width: proxy.size.width * fillAmount(isDone: isDone, isCurrent: isCurrent))
                        }
                    }
                    .clipShape(.capsule)
                    .frame(width: isCurrent ? 28 : 8, height: 8)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .glassEffect(.regular, in: .capsule)
        .animation(.bouncy, value: completed)
        .animation(.smooth, value: currentProgress == nil)
        .accessibilityElement()
        .accessibilityLabel("\(completed) of \(total) focus sessions complete")
    }

    private func fillAmount(isDone: Bool, isCurrent: Bool) -> Double {
        if isDone { return 1 }
        if isCurrent { return currentProgress ?? 0 }
        return 0
    }
}

private struct TodaySummary: View {
    let stats: DailyStats

    var body: some View {
        Group {
            if stats.focusSessions == 0 {
                Text("No focus sessions yet today")
            } else {
                Text("^[\(stats.focusSessions) session](inflect: true) · \(focusTime) focused today")
            }
        }
        .font(.callout)
        .foregroundStyle(.secondary)
        .contentTransition(.numericText())
    }

    private var focusTime: String {
        Duration.seconds(stats.focusSeconds)
            .formatted(.units(allowed: [.hours, .minutes], width: .abbreviated))
    }
}

/// A quick swell-and-settle when a phase completes.
private struct CelebrationEffect: ViewModifier {
    let trigger: Int

    func body(content: Content) -> some View {
        content.keyframeAnimator(initialValue: 1.0, trigger: trigger) { view, scale in
            view.scaleEffect(scale)
        } keyframes: { _ in
            SpringKeyframe(1.06, duration: 0.25, spring: .bouncy)
            SpringKeyframe(1.0, duration: 0.5, spring: .smooth)
        }
    }
}

private extension View {
    func celebrates(trigger: Int) -> some View {
        modifier(CelebrationEffect(trigger: trigger))
    }
}

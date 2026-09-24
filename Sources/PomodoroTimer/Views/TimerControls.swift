import SwiftUI

/// Play/pause, with reset and skip that morph out of it as Liquid Glass once a
/// session has started.
struct TimerControls: View {
    @Environment(TimerEngine.self) private var engine
    @Namespace private var glass

    var compact = false

    var body: some View {
        GlassEffectContainer(spacing: compact ? 12 : 20) {
            HStack(spacing: compact ? 12 : 20) {
                if !engine.isIdle {
                    GlassIconButton(
                        "Reset",
                        systemImage: "arrow.counterclockwise",
                        size: secondarySize
                    ) {
                        withAnimation(.bouncy) { engine.reset() }
                    }
                    .glassEffectID("reset", in: glass)
                }

                Button {
                    withAnimation(.bouncy) { engine.toggle() }
                } label: {
                    Image(systemName: engine.isRunning ? "pause.fill" : "play.fill")
                        .font(.system(size: primarySize * 0.36, weight: .semibold))
                        .contentTransition(.symbolEffect(.replace.offUp))
                        .foregroundStyle(.white)
                        .frame(width: primarySize, height: primarySize)
                        .contentShape(.circle)
                }
                .buttonStyle(.plain)
                .glassEffect(.regular.tint(engine.phase.tint).interactive(), in: .circle)
                .glassEffectID("toggle", in: glass)
                .accessibilityLabel(engine.isRunning ? "Pause" : "Start")
                .help(engine.isRunning ? "Pause (⌘↩)" : "Start (⌘↩)")

                if !engine.isIdle {
                    GlassIconButton(
                        "Skip",
                        systemImage: "forward.end.fill",
                        size: secondarySize
                    ) {
                        withAnimation(.bouncy) { engine.skip() }
                    }
                    .glassEffectID("skip", in: glass)
                }
            }
        }
        .animation(.bouncy(duration: 0.45), value: engine.isIdle)
    }

    private var primarySize: CGFloat { compact ? 48 : 80 }
    private var secondarySize: CGFloat { compact ? 34 : 52 }
}

struct GlassIconButton: View {
    let title: String
    let systemImage: String
    let size: CGFloat
    let action: () -> Void

    init(_ title: String, systemImage: String, size: CGFloat, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.size = size
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: size * 0.36, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(width: size, height: size)
                .contentShape(.circle)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: .circle)
        .accessibilityLabel(title)
        .help(title)
    }
}

import SwiftUI

/// A soft mesh-gradient wash in the phase's color. It drifts slowly while the
/// timer runs, which gives the window a quiet sense of motion without a
/// distracting animation.
struct PhaseBackground: View {
    let phase: TimerPhase
    let isRunning: Bool

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: !isRunning)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            MeshGradient(
                width: 3,
                height: 3,
                points: points(at: isRunning ? t : 0),
                colors: colors
            )
        }
        .background(.background)
        .animation(.smooth(duration: 0.9), value: phase)
        .ignoresSafeArea()
    }

    private var colors: [Color] {
        let tint = phase.tint
        let strength = colorScheme == .dark ? 1.25 : 1.0
        func wash(_ opacity: Double) -> Color { tint.opacity(opacity * strength) }
        return [
            .clear, wash(0.10), .clear,
            wash(0.14), wash(0.26), wash(0.10),
            wash(0.06), wash(0.16), .clear,
        ]
    }

    /// Interior points orbit gently; edge points stay pinned so the mesh fills the window.
    private func points(at t: TimeInterval) -> [SIMD2<Float>] {
        func drift(_ speed: Double, _ amount: Double) -> Float {
            Float(sin(t * speed) * amount)
        }
        return [
            [0, 0], [0.5 + drift(0.23, 0.08), 0], [1, 0],
            [0, 0.5 + drift(0.19, 0.06)],
            [0.5 + drift(0.31, 0.07), 0.45 + drift(0.27, 0.06)],
            [1, 0.5 + drift(0.17, 0.07)],
            [0, 1], [0.5 + drift(0.21, 0.09), 1], [1, 1],
        ]
    }
}

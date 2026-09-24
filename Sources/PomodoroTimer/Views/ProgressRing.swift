import SwiftUI

/// A ring that drains clockwise from 12 o'clock as the phase runs down.
struct ProgressRing: View {
    /// Fraction of the phase still remaining, 0...1.
    let fraction: Double
    let tint: Color
    var lineWidth: CGFloat = 14

    var body: some View {
        ZStack {
            Circle()
                .stroke(tint.opacity(0.14), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: fraction)
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: tint.opacity(0.45), radius: lineWidth * 0.7)

            // A bright knob riding the leading edge of the arc.
            GeometryReader { proxy in
                let radius = min(proxy.size.width, proxy.size.height) / 2
                Circle()
                    .fill(.white)
                    .frame(width: lineWidth * 0.5, height: lineWidth * 0.5)
                    .shadow(color: tint, radius: 4)
                    .offset(y: -radius)
                    .rotationEffect(.degrees(360 * fraction))
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .opacity(fraction > 0.002 && fraction < 0.999 ? 1 : 0)
            }
        }
        .padding(lineWidth / 2)
    }
}


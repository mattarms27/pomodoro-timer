import SwiftUI

/// One segment of the Pomodoro cycle.
enum TimerPhase: String, CaseIterable, Identifiable, Codable {
    case focus, shortBreak, longBreak

    var id: Self { self }

    var title: String {
        switch self {
        case .focus: "Focus"
        case .shortBreak: "Short Break"
        case .longBreak: "Long Break"
        }
    }

    var symbol: String {
        switch self {
        case .focus: "brain.head.profile"
        case .shortBreak: "cup.and.saucer.fill"
        case .longBreak: "sofa.fill"
        }
    }

    var tint: Color {
        switch self {
        case .focus: Color.red.mix(with: .orange, by: 0.3)
        case .shortBreak: .teal
        case .longBreak: .indigo
        }
    }

    var completionMessage: String {
        switch self {
        case .focus: "Nice work. Time for a break."
        case .shortBreak: "Break's over. Ready to focus?"
        case .longBreak: "You're recharged. Let's get back to it."
        }
    }

    var isBreak: Bool { self != .focus }
}

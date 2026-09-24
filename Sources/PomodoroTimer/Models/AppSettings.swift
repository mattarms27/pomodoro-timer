import AppKit
import Observation

/// How the app chooses between light and dark appearance.
enum AppearanceMode: String, CaseIterable, Identifiable {
    case system, light, dark

    var id: Self { self }

    var title: String {
        switch self {
        case .system: "Automatic"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    /// The saved mode, readable before `AppSettings` exists (e.g. at launch).
    static var stored: AppearanceMode {
        AppearanceMode(rawValue: UserDefaults.standard.string(forKey: "appearance") ?? "") ?? .system
    }

    var nsAppearance: NSAppearance? {
        switch self {
        case .system: nil
        case .light: NSAppearance(named: .aqua)
        case .dark: NSAppearance(named: .darkAqua)
        }
    }
}

/// User preferences, persisted to `UserDefaults`.
@Observable
final class AppSettings {
    static let alertSounds = ["Glass", "Hero", "Ping", "Purr", "Submarine", "Tink", "Blow", "Pop"]

    var focusMinutes: Int { didSet { store(focusMinutes, .focusMinutes) } }
    var shortBreakMinutes: Int { didSet { store(shortBreakMinutes, .shortBreakMinutes) } }
    var longBreakMinutes: Int { didSet { store(longBreakMinutes, .longBreakMinutes) } }
    var sessionsBeforeLongBreak: Int { didSet { store(sessionsBeforeLongBreak, .sessionsBeforeLongBreak) } }

    var autoStartBreaks: Bool { didSet { store(autoStartBreaks, .autoStartBreaks) } }
    var autoStartFocus: Bool { didSet { store(autoStartFocus, .autoStartFocus) } }

    var playSound: Bool { didSet { store(playSound, .playSound) } }
    var alertSound: String { didSet { store(alertSound, .alertSound) } }
    var showNotifications: Bool { didSet { store(showNotifications, .showNotifications) } }

    var showInMenuBar: Bool { didSet { store(showInMenuBar, .showInMenuBar) } }

    var appearance: AppearanceMode {
        didSet {
            store(appearance.rawValue, .appearance)
            applyAppearance()
        }
    }

    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [
            Key.focusMinutes.rawValue: 25,
            Key.shortBreakMinutes.rawValue: 5,
            Key.longBreakMinutes.rawValue: 15,
            Key.sessionsBeforeLongBreak.rawValue: 4,
            Key.autoStartBreaks.rawValue: true,
            Key.autoStartFocus.rawValue: false,
            Key.playSound.rawValue: true,
            Key.alertSound.rawValue: "Glass",
            Key.showNotifications.rawValue: true,
            Key.showInMenuBar.rawValue: true,
            Key.appearance.rawValue: AppearanceMode.system.rawValue,
        ])

        focusMinutes = defaults.integer(forKey: Key.focusMinutes.rawValue)
        shortBreakMinutes = defaults.integer(forKey: Key.shortBreakMinutes.rawValue)
        longBreakMinutes = defaults.integer(forKey: Key.longBreakMinutes.rawValue)
        sessionsBeforeLongBreak = defaults.integer(forKey: Key.sessionsBeforeLongBreak.rawValue)
        autoStartBreaks = defaults.bool(forKey: Key.autoStartBreaks.rawValue)
        autoStartFocus = defaults.bool(forKey: Key.autoStartFocus.rawValue)
        playSound = defaults.bool(forKey: Key.playSound.rawValue)
        alertSound = defaults.string(forKey: Key.alertSound.rawValue) ?? "Glass"
        showNotifications = defaults.bool(forKey: Key.showNotifications.rawValue)
        showInMenuBar = defaults.bool(forKey: Key.showInMenuBar.rawValue)
        appearance = AppearanceMode(rawValue: defaults.string(forKey: Key.appearance.rawValue) ?? "") ?? .system
    }

    func duration(for phase: TimerPhase) -> TimeInterval {
        let minutes = switch phase {
        case .focus: focusMinutes
        case .shortBreak: shortBreakMinutes
        case .longBreak: longBreakMinutes
        }
        return TimeInterval(minutes * 60)
    }

    func applyAppearance() {
        NSApp?.appearance = appearance.nsAppearance
    }

    func resetTimerDefaults() {
        focusMinutes = 25
        shortBreakMinutes = 5
        longBreakMinutes = 15
        sessionsBeforeLongBreak = 4
    }

    private func store(_ value: Any, _ key: Key) {
        defaults.set(value, forKey: key.rawValue)
    }

    private enum Key: String {
        case focusMinutes, shortBreakMinutes, longBreakMinutes, sessionsBeforeLongBreak
        case autoStartBreaks, autoStartFocus
        case playSound, alertSound, showNotifications
        case showInMenuBar, appearance
    }
}

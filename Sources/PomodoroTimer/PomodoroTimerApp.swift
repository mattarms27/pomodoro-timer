import SwiftUI

@main
struct PomodoroTimerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    @ViewState private var settings: AppSettings
    @ViewState private var notifier: Notifier
    @ViewState private var engine: TimerEngine

    init() {
        let settings = AppSettings()
        let notifier = Notifier(settings: settings)
        _settings = ViewState(initialValue: settings)
        _notifier = ViewState(initialValue: notifier)
        _engine = ViewState(initialValue: TimerEngine(settings: settings, notifier: notifier))
    }

    var body: some Scene {
        Window("Pomodoro Timer", id: WindowID.main) {
            ContentView()
                .environment(settings)
                .environment(notifier)
                .environment(engine)
                .task { notifier.requestAuthorization() }
        }
        .defaultSize(width: 860, height: 620)
        .windowToolbarStyle(.unified)
        .commands {
            TimerCommands(engine: engine, settings: settings)
        }

        Settings {
            SettingsView()
                .environment(settings)
                .environment(notifier)
        }

        MenuBarExtra(isInserted: $settings.showInMenuBar) {
            MenuBarView()
                .environment(settings)
                .environment(engine)
        } label: {
            MenuBarLabel(engine: engine)
        }
        .menuBarExtraStyle(.window)
    }
}

enum WindowID {
    static let main = "main"
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillFinishLaunching(_ notification: Notification) {
        // Apply the saved appearance before any window draws, so there's no flash.
        NSApp.appearance = AppearanceMode.stored.nsAppearance
    }

    /// Keep running (and timing) from the menu bar after the window closes.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}

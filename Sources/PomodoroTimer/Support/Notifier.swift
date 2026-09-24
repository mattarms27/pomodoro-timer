import AppKit
import UserNotifications

/// Plays the completion sound and schedules system notifications for phase ends.
final class Notifier: NSObject {
    private let settings: AppSettings
    /// Each phase run gets its own ID, so scheduling the next phase never
    /// replaces a notification that is about to be delivered.
    private var pendingRequestID: String?

    /// `UNUserNotificationCenter` requires a bundle identifier, which only exists
    /// when running from the assembled .app (not from `swift run`).
    private var center: UNUserNotificationCenter? {
        Bundle.main.bundleIdentifier == nil ? nil : .current()
    }

    init(settings: AppSettings) {
        self.settings = settings
        super.init()
        center?.delegate = self
    }

    func requestAuthorization() {
        center?.requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func schedulePhaseEnd(_ phase: TimerPhase, at date: Date) {
        guard settings.showNotifications, let center else { return }

        let content = UNMutableNotificationContent()
        content.title = "\(phase.title) complete"
        content.body = phase.completionMessage

        let interval = max(1, date.timeIntervalSinceNow)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let id = UUID().uuidString
        pendingRequestID = id
        center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }

    /// Cancels the notification for an interrupted phase.
    func cancelPending() {
        guard let id = pendingRequestID else { return }
        center?.removePendingNotificationRequests(withIdentifiers: [id])
        pendingRequestID = nil
    }

    /// Lets the current phase's notification deliver on its own.
    func releasePending() {
        pendingRequestID = nil
    }

    func playCompletionSound() {
        guard settings.playSound else { return }
        preview(sound: settings.alertSound)
    }

    func preview(sound name: String) {
        NSSound(named: NSSound.Name(name))?.play()
    }
}

extension Notifier: UNUserNotificationCenterDelegate {
    /// Show the banner even while the app is frontmost.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list]
    }
}

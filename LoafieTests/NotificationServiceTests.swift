import Foundation
import Testing
import UserNotifications
@testable import Loafie

@MainActor
struct NotificationServiceTests {

    @Test func initializationRemovesLegacyPerSessionAlarmPreferences() {
        let suiteName = "NotificationServiceTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        defaults.set(["legacy-event"], forKey: "loafie.disabledAlarmIdentifiers.legacy-session")
        let settings = SettingsStore(defaults: defaults)
        let service = NotificationService(center: .current(), settings: settings, defaults: defaults)
        _ = service

        #expect(defaults.stringArray(forKey: "loafie.disabledAlarmIdentifiers.legacy-session") == nil)
    }

    @Test func expiredPendingIdentifiersAreLimitedToLoafie() {
        let now = Date()
        let past = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: now.addingTimeInterval(-3_600)
        )
        let future = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: now.addingTimeInterval(3_600)
        )
        let content = UNMutableNotificationContent()
        let requests = [
            UNNotificationRequest(
                identifier: "session/old/past",
                content: content,
                trigger: UNCalendarNotificationTrigger(dateMatching: past, repeats: false)
            ),
            UNNotificationRequest(
                identifier: "session/current/future",
                content: content,
                trigger: UNCalendarNotificationTrigger(dateMatching: future, repeats: false)
            ),
            UNNotificationRequest(
                identifier: "other-app/past",
                content: content,
                trigger: UNCalendarNotificationTrigger(dateMatching: past, repeats: false)
            )
        ]

        #expect(
            NotificationService.expiredNotificationIdentifiers(from: requests, before: now)
                == ["session/old/past"]
        )
    }
}

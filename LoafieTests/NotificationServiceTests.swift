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
}

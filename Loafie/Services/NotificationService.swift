import Foundation
import Observation
import AudioToolbox
import UserNotifications

/// Local notification planning. Every session mutation triggers a full replan
/// of that session's pending notifications (cancel + reschedule).
@MainActor
@Observable
final class NotificationService {

    private let center: UNUserNotificationCenter
    private let settings: SettingsStore
    private let defaults: UserDefaults
    private let alarmKitService = AlarmKitService()
    private let delegate = NotificationService.Delegate()
    private var replanTask: Task<Void, Never>?

    /// Set when the user has denied permission; the UI shows a persistent hint.
    private(set) var authorizationDenied = false
    private(set) var lastSchedulingError: String?
    private(set) var lastSchedulingStatus: String?
    private(set) var scheduledAlarmCount = 0
    private(set) var scheduledAlarms: [ScheduledAlarm] = []

    var alarmKitAvailable: Bool { alarmKitService.isAvailable }
    var alarmKitAuthorized: Bool { alarmKitService.isAuthorized }

    init(
        center: UNUserNotificationCenter = .current(),
        settings: SettingsStore,
        defaults: UserDefaults = .standard
    ) {
        self.center = center
        self.settings = settings
        self.defaults = defaults
        for key in defaults.dictionaryRepresentation().keys
        where key.hasPrefix("loafie.disabledAlarmIdentifiers.") {
            defaults.removeObject(forKey: key)
        }
        center.delegate = delegate
        center.setNotificationCategories([
            UNNotificationCategory(
                identifier: "PLANNED_START",
                actions: [
                    UNNotificationAction(
                        identifier: "START_NOW",
                        title: String(localized: "Start now"),
                        options: [.foreground]
                    )
                ],
                intentIdentifiers: [],
                options: []
            )
        ])
        refreshAuthorizationState()
        scheduledAlarmCount = alarmKitService.scheduledCount
        scheduledAlarms = alarmKitService.scheduledAlarms
    }

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            authorizationDenied = !granted
            return granted
        } catch {
            authorizationDenied = true
            return false
        }
    }

    func requestAlarmKitAuthorization() async -> Bool {
        let authorized = await alarmKitService.requestAuthorization()
        lastSchedulingStatus = authorized
            ? String(localized: "System alarm permission granted.")
            : String(localized: "System alarm permission was not granted.")
        scheduledAlarmCount = alarmKitService.scheduledCount
        scheduledAlarms = alarmKitService.scheduledAlarms
        return authorized
    }

    func refreshDiagnostics() async {
        scheduledAlarmCount = alarmKitService.scheduledCount
        scheduledAlarms = alarmKitService.scheduledAlarms
        let settings = await center.notificationSettings()
        if self.settings.alarmKitEnabled, !alarmKitAvailable {
            lastSchedulingStatus = String(localized: "System alarms are not available on this device.")
        } else if self.settings.alarmKitEnabled, !alarmKitAuthorized {
            lastSchedulingStatus = String(localized: "System alarm permission is turned off.")
        } else if self.settings.notificationsEnabled, settings.authorizationStatus == .denied {
            lastSchedulingStatus = String(localized: "Notifications are denied in system settings.")
        } else if !self.settings.notificationsEnabled && !self.settings.alarmKitEnabled {
            lastSchedulingStatus = String(localized: "Notifications are disabled in Loafie.")
        } else {
            lastSchedulingStatus = nil
        }
    }

    func refreshAuthorizationState() {
        Task { @MainActor in
            let status = await center.notificationSettings().authorizationStatus
            authorizationDenied = status == .denied
        }
    }

    /// Plays a short preview for the selected notification sound.
    /// System sounds are used here because UNNotificationSound itself cannot
    /// be previewed while the app is in the foreground.
    func playPreview(for sound: NotificationSound) {
        let systemSoundID: SystemSoundID?
        switch sound {
        case .default:
            systemSoundID = 1007 // Standard received-message alert.
        case .ringtone:
            systemSoundID = 1001 // Standard ringtone alert.
        case .silent:
            systemSoundID = nil
        }
        if let systemSoundID {
            AudioServicesPlaySystemSound(systemSoundID)
        }
    }

    // MARK: - Replanning

    /// Cancels all pending notifications of a session and reschedules from
    /// current timestamps. Paused sessions keep no pending notifications.
    /// A new timer can also request cleanup of expired Loafie alarms first.
    func reschedule(for session: BakeSession, cleanupExpired: Bool = false) {
        let prefix = Self.prefix(for: session)
        replanTask?.cancel()
        lastSchedulingError = nil
        replanTask = Task { @MainActor [weak self] in
            guard let self else { return }
            let timestamp = Date()
            let requests = await center.pendingNotificationRequests()
            guard !Task.isCancelled else { return }
            var stale = Set(requests.map(\.identifier).filter { $0.hasPrefix(prefix) })
            if cleanupExpired {
                stale.formUnion(Self.expiredNotificationIdentifiers(from: requests, before: timestamp))
            }
            center.removePendingNotificationRequests(withIdentifiers: Array(stale))

            if cleanupExpired {
                let delivered = await center.deliveredNotifications()
                guard !Task.isCancelled else { return }
                let staleDelivered = delivered.map(\.request.identifier).filter { $0.hasPrefix(Self.loafiePrefix) }
                center.removeDeliveredNotifications(withIdentifiers: staleDelivered)
                await alarmKitService.cleanupExpired(before: timestamp)
                guard !Task.isCancelled else { return }
            }

            await alarmKitService.cancelAll(for: prefix)
            guard !Task.isCancelled else { return }
            scheduledAlarmCount = alarmKitService.scheduledCount
            scheduledAlarms = alarmKitService.scheduledAlarms
            guard !Task.isCancelled else { return }
            await schedulePending(for: session, prefix: prefix)
        }
    }

    func cancelAll(for session: BakeSession) {
        let prefix = Self.prefix(for: session)
        replanTask?.cancel()
        replanTask = Task { @MainActor in
            let requests = await center.pendingNotificationRequests()
            let stale = requests.map(\.identifier).filter { $0.hasPrefix(prefix) }
            center.removePendingNotificationRequests(withIdentifiers: stale)
            await alarmKitService.cancelAll(for: prefix)
            scheduledAlarmCount = alarmKitService.scheduledCount
            scheduledAlarms = alarmKitService.scheduledAlarms
        }
    }

    private func schedulePending(for session: BakeSession, prefix: String) async {
        guard !Task.isCancelled else { return }
        guard settings.notificationsEnabled || settings.alarmKitEnabled else { return }

        for event in ReminderPlanner.events(for: session) {
            guard !Task.isCancelled else { return }
            await bakePlan(event)
        }
    }

    private static func prefix(for session: BakeSession) -> String {
        "session/\(session.id)/"
    }

    private static let loafiePrefix = "session/"

    static func expiredNotificationIdentifiers(
        from requests: [UNNotificationRequest],
        before date: Date
    ) -> [String] {
        requests.compactMap { request in
            guard request.identifier.hasPrefix(loafiePrefix),
                  let trigger = request.trigger,
                  let nextTriggerDate = nextTriggerDate(for: trigger),
                  nextTriggerDate <= date else {
                return nil
            }
            return request.identifier
        }
    }

    private static func nextTriggerDate(for trigger: UNNotificationTrigger) -> Date? {
        if let calendarTrigger = trigger as? UNCalendarNotificationTrigger {
            return calendarTrigger.nextTriggerDate()
        }
        if let intervalTrigger = trigger as? UNTimeIntervalNotificationTrigger {
            return intervalTrigger.nextTriggerDate()
        }
        return nil
    }

    func quietHoursSuppressedAlarmEvents(for session: BakeSession) -> [ReminderPlanEvent] {
        guard settings.alarmKitEnabled else { return [] }
        return ReminderPlanner.events(for: session).filter { settings.isInSleepWindow($0.date) }
    }

    private func bakePlan(_ event: ReminderPlanEvent) async {
        guard !Task.isCancelled else { return }
        if settings.notificationsEnabled {
            await scheduleNotification(event)
        }

        guard settings.alarmKitEnabled else { return }
        guard !settings.isInSleepWindow(event.date) else { return }
        guard let sessionID = sessionID(for: event.identifier) else { return }
        guard alarmKitService.isAvailable else {
            lastSchedulingStatus = String(localized: "System alarms are not available on this device.")
            return
        }
        guard alarmKitService.isAuthorized else {
            lastSchedulingStatus = String(localized: "System alarm permission is turned off.")
            return
        }

        if await alarmKitService.schedule(
            identifier: event.identifier,
            sessionID: sessionID,
            at: event.date,
            title: event.title
        ) {
            scheduledAlarmCount = alarmKitService.scheduledCount
            scheduledAlarms = alarmKitService.scheduledAlarms
            lastSchedulingStatus = String(localized: "System alarm scheduled.")
        } else {
            lastSchedulingStatus = String(localized: "A system alarm could not be scheduled.")
        }
    }

    private func scheduleNotification(_ event: ReminderPlanEvent) async {
        let content = UNMutableNotificationContent()
        content.title = event.title
        content.body = event.body
        content.sound = notificationSound
        content.interruptionLevel = .timeSensitive
        if event.identifier.hasSuffix("planned-start") {
            content.categoryIdentifier = "PLANNED_START"
        }
        if let sessionID = event.identifier.split(separator: "/").dropFirst().first,
           let url = timerURL(for: event.identifier) {
            content.userInfo = [
                "sessionID": String(sessionID),
                "url": url.absoluteString
            ]
        }
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: event.date
        )
        let request = UNNotificationRequest(
            identifier: event.identifier,
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        )
        do {
            try await center.add(request)
        } catch {
            lastSchedulingError = String(localized: "A reminder could not be scheduled.")
            #if DEBUG
            print("Failed to bakePlan local notification \(event.identifier): \(error)")
            #endif
        }
    }

    private var notificationSound: UNNotificationSound? {
        switch settings.notificationSound {
        case .default: .default
        case .ringtone: .defaultRingtone
        case .silent: nil
        }
    }

    private func timerURL(for identifier: String) -> URL? {
        guard let sessionID = sessionID(for: identifier) else { return nil }
        return URL(string: "loafie://session/\(sessionID.uuidString)")
    }

    private func sessionID(for identifier: String) -> UUID? {
        let components = identifier.split(separator: "/").map(String.init)
        guard components.count >= 2 else { return nil }
        return UUID(uuidString: components[1])
    }

    private class Delegate: NSObject, UNUserNotificationCenterDelegate {
        nonisolated func userNotificationCenter(
            _ center: UNUserNotificationCenter,
            willPresent notification: UNNotification
        ) async -> UNNotificationPresentationOptions {
            [.banner, .sound]
        }

        nonisolated func userNotificationCenter(
            _ center: UNUserNotificationCenter,
            didReceive response: UNNotificationResponse
        ) async {
            guard let rawID = response.notification.request.content.userInfo["sessionID"] as? String,
                  let id = UUID(uuidString: rawID) else { return }
            if response.actionIdentifier == "START_NOW" {
                NotificationCenter.default.post(
                    name: .plannedSessionStartRequested,
                    object: id
                )
            } else {
                NotificationCenter.default.post(
                    name: .sessionNotificationOpened,
                    object: id
                )
            }
        }
    }
}

extension SessionStep {
    var displayTitle: String {
        if !title.isEmpty { return title }
        return type.localizedTitle
    }
}

extension Notification.Name {
    nonisolated static let plannedSessionStartRequested = Notification.Name("LoafiePlannedSessionStartRequested")
    nonisolated static let sessionNotificationOpened = Notification.Name("LoafieSessionNotificationOpened")
}

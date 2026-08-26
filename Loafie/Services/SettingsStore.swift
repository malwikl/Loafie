import Foundation
import Observation

enum NotificationSound: String, CaseIterable, Identifiable {
    case `default`
    case ringtone
    case silent

    var id: String { rawValue }

    var title: String {
        switch self {
        case .default: String(localized: "Default")
        case .ringtone: String(localized: "Ringtone")
        case .silent: String(localized: "Silent")
        }
    }
}

/// Global app settings, backed by UserDefaults.
@MainActor
@Observable
final class SettingsStore {

    private let defaults: UserDefaults
    private var notificationSoundValue: NotificationSound
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let raw = defaults.string(forKey: Key.notificationSound),
           let value = NotificationSound(rawValue: raw) {
            self.notificationSoundValue = value
        } else {
            self.notificationSoundValue = (defaults.object(forKey: Key.soundEnabled) as? Bool == false)
                ? .silent
                : .default
        }
        if defaults.object(forKey: Key.alarmKitEnabled) == nil,
           defaults.string(forKey: Key.reminderDeliveryMode) == "alarmKit" {
            defaults.set(true, forKey: Key.alarmKitEnabled)
        }
    }

    private enum Key {
        static let notificationsEnabled = "notificationsEnabled"
        static let notificationSound = "notificationSound"
        static let alarmKitEnabled = "alarmKitEnabled"
        static let alarmKitPrompted = "alarmKitPrompted"
        static let reminderDeliveryMode = "reminderDeliveryMode"
        static let soundEnabled = "soundEnabled" // Legacy key.
        static let hapticsEnabled = "hapticsEnabled"
        static let sleepModeEnabled = "sleepModeEnabled"
        static let sleepModeStartHour = "sleepModeStartHour"
        static let sleepModeEndHour = "sleepModeEndHour"
        static let sleepModeStartMinute = "sleepModeStartMinute"
        static let sleepModeEndMinute = "sleepModeEndMinute"
        static let askBeforePlanAdjustment = "askBeforePlanAdjustment"
    }

    var notificationsEnabled: Bool {
        get { defaults.object(forKey: Key.notificationsEnabled) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Key.notificationsEnabled) }
    }

    var notificationSound: NotificationSound {
        get { notificationSoundValue }
        set {
            notificationSoundValue = newValue
            defaults.set(newValue.rawValue, forKey: Key.notificationSound)
        }
    }

    var alarmKitEnabled: Bool {
        get { defaults.object(forKey: Key.alarmKitEnabled) as? Bool ?? false }
        set { defaults.set(newValue, forKey: Key.alarmKitEnabled) }
    }

    var hasPromptedForAlarmKit: Bool {
        get { defaults.bool(forKey: Key.alarmKitPrompted) }
        set { defaults.set(newValue, forKey: Key.alarmKitPrompted) }
    }

    var hapticsEnabled: Bool {
        get { defaults.object(forKey: Key.hapticsEnabled) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Key.hapticsEnabled) }
    }

    var askBeforePlanAdjustment: Bool {
        get { defaults.object(forKey: Key.askBeforePlanAdjustment) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Key.askBeforePlanAdjustment) }
    }

    var sleepModeEnabled: Bool {
        get { defaults.bool(forKey: Key.sleepModeEnabled) }
        set { defaults.set(newValue, forKey: Key.sleepModeEnabled) }
    }

    var sleepModeStartMinute: Int {
        get {
            if let minute = defaults.object(forKey: Key.sleepModeStartMinute) as? Int {
                return minute
            }
            return (defaults.object(forKey: Key.sleepModeStartHour) as? Int ?? 22) * 60
        }
        set { defaults.set(newValue, forKey: Key.sleepModeStartMinute) }
    }

    var sleepModeEndMinute: Int {
        get {
            if let minute = defaults.object(forKey: Key.sleepModeEndMinute) as? Int {
                return minute
            }
            return (defaults.object(forKey: Key.sleepModeEndHour) as? Int ?? 7) * 60
        }
        set { defaults.set(newValue, forKey: Key.sleepModeEndMinute) }
    }

    /// Whether a date falls inside the sleep window (overnight windows supported).
    func isInSleepWindow(_ date: Date) -> Bool {
        guard sleepModeEnabled else { return false }
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        let minute = (components.hour ?? 0) * 60 + (components.minute ?? 0)
        if sleepModeStartMinute == sleepModeEndMinute { return false }
        if sleepModeStartMinute < sleepModeEndMinute {
            return minute >= sleepModeStartMinute && minute < sleepModeEndMinute
        }
        return minute >= sleepModeStartMinute || minute < sleepModeEndMinute
    }
}

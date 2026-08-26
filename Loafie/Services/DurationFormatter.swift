import Foundation

enum DurationFormatter {
    /// Compact duration like "8 h 30 min" or "45 min".
    static func string(from interval: TimeInterval) -> String {
        let totalMinutes = Int(interval.rounded() / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours > 0 && minutes > 0 {
            return String(localized: "\(hours) h \(minutes) min")
        } else if hours > 0 {
            return String(localized: "\(hours) h")
        } else {
            return String(localized: "\(minutes) min")
        }
    }

    /// Clock-style countdown: "4:32:10" or "32:10". Monospaced rendering is done by the view.
    static func countdown(from interval: TimeInterval) -> String {
        let clamped = max(0, interval)
        let totalSeconds = Int(clamped.rounded(.up))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

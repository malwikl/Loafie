import Foundation

/// Pure fold-round scheduling and validation. Spec: "x times every n minutes",
/// optional first-reminder offset; last round must not end after bulk ends.
enum FoldReminderCalculator {

    /// Absolute offsets (seconds) of each round from bulk start.
    static func roundOffsets(
        repetitions: Int,
        interval: TimeInterval,
        firstReminderOffset: TimeInterval
    ) -> [TimeInterval] {
        guard repetitions > 0 else { return [] }
        return (0..<repetitions).map { firstReminderOffset + TimeInterval($0) * interval }
    }

    static func lastRoundOffset(
        repetitions: Int,
        interval: TimeInterval,
        firstReminderOffset: TimeInterval
    ) -> TimeInterval? {
        roundOffsets(
            repetitions: repetitions,
            interval: interval,
            firstReminderOffset: firstReminderOffset
        ).last
    }

    static func isValid(
        isEnabled: Bool,
        repetitions: Int,
        interval: TimeInterval,
        firstReminderOffset: TimeInterval,
        bulkDuration: TimeInterval
    ) -> Bool {
        guard isEnabled, repetitions > 0 else { return true }
        guard let last = lastRoundOffset(
            repetitions: repetitions,
            interval: interval,
            firstReminderOffset: firstReminderOffset
        ) else { return true }
        return last <= bulkDuration
    }
}

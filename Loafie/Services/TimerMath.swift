import Foundation

/// Pure timestamp-based timer math. Truth lives in stored timestamps,
/// never in a foreground tick timer.
enum TimerMath {

    struct ColdWindow: Equatable {
        let minimumEnd: Date
        let recommendedEnd: Date
        let maximumEnd: Date
    }

    static func coldWindow(
        startedAt: Date,
        target: TimeInterval,
        minimum: TimeInterval?,
        maximum: TimeInterval?,
        manualAdjustment: TimeInterval = 0,
        accumulatedPause: TimeInterval = 0
    ) -> ColdWindow {
        let base = startedAt.addingTimeInterval(accumulatedPause + manualAdjustment)
        return ColdWindow(
            minimumEnd: base.addingTimeInterval(minimum ?? target),
            recommendedEnd: base.addingTimeInterval(target),
            maximumEnd: base.addingTimeInterval(maximum ?? target)
        )
    }

    static func reminderDate(
        stepStart: Date,
        stepDuration: TimeInterval,
        stepAdjustment: TimeInterval = 0,
        pauseDuration: TimeInterval = 0,
        offset: TimeInterval,
        mode: ReminderTriggerMode,
        previousDate: Date? = nil
    ) -> Date {
        switch mode {
        case .afterStepStart:
            return stepStart.addingTimeInterval(offset + pauseDuration + stepAdjustment)
        case .afterPreviousReminder:
            return (previousDate ?? stepStart).addingTimeInterval(offset)
        case .beforeStepEnd:
            return stepStart
                .addingTimeInterval(stepDuration + stepAdjustment + pauseDuration)
                .addingTimeInterval(-offset)
        }
    }

    /// Signed remaining seconds for a step. Negative means overdue.
    static func remaining(
        startedAt: Date,
        plannedDuration: TimeInterval,
        manualAdjustment: TimeInterval = 0,
        accumulatedPause: TimeInterval = 0,
        pausedAt: Date? = nil,
        now: Date = Date()
    ) -> TimeInterval {
        let effectiveNow = pausedAt ?? now
        let elapsed = max(0, effectiveNow.timeIntervalSince(startedAt) - accumulatedPause)
        return plannedDuration + manualAdjustment - elapsed
    }

    /// Planned end date of a step, accounting for adjustment and past pause time.
    static func plannedEnd(
        startedAt: Date,
        plannedDuration: TimeInterval,
        manualAdjustment: TimeInterval = 0,
        accumulatedPause: TimeInterval = 0
    ) -> Date {
        startedAt
            .addingTimeInterval(plannedDuration)
            .addingTimeInterval(manualAdjustment)
            .addingTimeInterval(accumulatedPause)
    }
}

/// Classification of a cold step against its min/target/max window.
enum ColdStepState: String, Equatable {
    /// Elapsed time below minimum.
    case running
    /// Minimum reached, target not yet: earliest ready.
    case earliestReady
    /// Target reached: bake-ready.
    case bakeReady
    /// Maximum exceeded: warning.
    case exceededMaximum

    static func classify(
        startedAt: Date,
        target: TimeInterval,
        minimum: TimeInterval?,
        maximum: TimeInterval?,
        manualAdjustment: TimeInterval = 0,
        accumulatedPause: TimeInterval = 0,
        pausedAt: Date? = nil,
        now: Date = Date()
    ) -> ColdStepState {
        let effectiveNow = pausedAt ?? now
        let elapsed = max(0, effectiveNow.timeIntervalSince(startedAt) - accumulatedPause)
        let adjustedTarget = target + manualAdjustment
        let adjustedMaximum = (maximum ?? target) + manualAdjustment
        let adjustedMinimum = (minimum ?? target) + manualAdjustment

        if elapsed >= adjustedMaximum { return .exceededMaximum }
        if elapsed >= adjustedTarget { return .bakeReady }
        if elapsed >= adjustedMinimum { return .earliestReady }
        return .running
    }
}

import Foundation

struct BakePlanTimelineEntry: Identifiable {
    let step: BakeStepDefinition
    let startOffset: TimeInterval
    let endOffset: TimeInterval
    let reminders: [ReminderProjection]
    let folds: [FoldReminderProjection]

    var id: UUID { step.id }

    func startDate(anchor: Date) -> Date {
        anchor.addingTimeInterval(startOffset)
    }

    func endDate(anchor: Date) -> Date {
        anchor.addingTimeInterval(endOffset)
    }
}

struct ReminderProjection: Identifiable {
    let timer: ReminderDefinition
    let offset: TimeInterval

    var id: UUID { timer.id }

    func date(anchor: Date) -> Date {
        anchor.addingTimeInterval(offset)
    }
}

struct FoldReminderProjection: Identifiable {
    let number: Int
    let offset: TimeInterval

    var id: String { "fold-\(number)-\(offset)" }

    func date(anchor: Date) -> Date {
        anchor.addingTimeInterval(offset)
    }
}

enum BakePlanTimelineCalculator {
    static func projections(for bakePlan: BakePlan) -> [BakePlanTimelineEntry] {
        var cursor: TimeInterval = 0

        return bakePlan.enabledSteps.map { step in
            let start = cursor
            let end = start + step.effectiveDuration
            cursor = end

            var previousDate: Date?
            let reminders = step.sortedReminders.map { timer in
                let triggerDate = TimerMath.reminderDate(
                    stepStart: Date(timeIntervalSince1970: 0),
                    stepDuration: step.effectiveDuration,
                    offset: timer.offset,
                    mode: timer.triggerMode,
                    previousDate: previousDate
                )
                previousDate = triggerDate
                return ReminderProjection(
                    timer: timer,
                    offset: start + triggerDate.timeIntervalSince1970
                )
            }

            let folds: [FoldReminderProjection]
            if let fold = step.foldReminderConfiguration,
               step.type.supportsFolding,
               fold.isEnabled {
                folds = FoldReminderCalculator.roundOffsets(
                    repetitions: fold.repetitions,
                    interval: fold.interval,
                    firstReminderOffset: fold.firstReminderOffset
                ).enumerated().map { index, offset in
                    FoldReminderProjection(number: index + 1, offset: start + offset)
                }
            } else {
                folds = []
            }

            return BakePlanTimelineEntry(
                step: step,
                startOffset: start,
                endOffset: end,
                reminders: reminders,
                folds: folds
            )
        }
    }
}

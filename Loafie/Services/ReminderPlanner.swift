import Foundation

/// Produces the currently actionable reminders for a baking session.
/// Both delivery channels and the timeline use this single source of truth.
struct ReminderPlanEvent: Identifiable, Equatable {
    let identifier: String
    let date: Date
    let title: String
    let body: String

    var id: String { identifier }
}

enum ReminderPlanner {

    static func events(for session: BakeSession, now: Date = Date()) -> [ReminderPlanEvent] {
        let prefix = "session/\(session.id)/"

        if session.status == .planned,
           let plannedStartAt = session.plannedStartAt,
           plannedStartAt > now {
            return [
                ReminderPlanEvent(
                    identifier: prefix + "planned-start",
                    date: plannedStartAt,
                    title: String(localized: "Time to start baking"),
                    body: String(localized: "Start \(session.bakePlanName) now.")
                )
            ]
        }

        guard session.status == .active,
              let step = session.activeStep,
              step.status == .active,
              let startedAt = step.startedAt else {
            return []
        }

        let pauseDuration = step.accumulatedPause
        var events: [ReminderPlanEvent] = []
        let stepEnd = TimerMath.plannedEnd(
            startedAt: startedAt,
            plannedDuration: step.plannedDuration,
            manualAdjustment: step.manualAdjustment,
            accumulatedPause: pauseDuration
        )
        if stepEnd > now {
            events.append(
                ReminderPlanEvent(
                    identifier: prefix + "step/\(step.id)/end",
                    date: stepEnd,
                    title: String(localized: "Step finished"),
                    body: stepEndBody(for: step, in: session)
                )
            )
        }

        if step.isColdStep, let maximum = step.maximumDuration {
            let maximumEnd = TimerMath.plannedEnd(
                startedAt: startedAt,
                plannedDuration: maximum,
                manualAdjustment: step.manualAdjustment,
                accumulatedPause: pauseDuration
            )
            if maximumEnd > now {
                events.append(
                    ReminderPlanEvent(
                        identifier: prefix + "step/\(step.id)/coldmax",
                        date: maximumEnd,
                        title: String(localized: "Latest Fridge Time Reached"),
                        body: String(localized: "The dough has reached the latest recommended fridge time. Check it and bake soon.")
                    )
                )
            }
        }

        var previousReminderDate: Date?
        for reminder in step.sortedReminders {
            let scheduledAt = TimerMath.reminderDate(
                stepStart: startedAt,
                stepDuration: step.plannedDuration,
                stepAdjustment: step.manualAdjustment,
                pauseDuration: pauseDuration,
                offset: reminder.offset,
                mode: reminder.triggerMode,
                previousDate: previousReminderDate
            )
            previousReminderDate = scheduledAt
            if reminder.status == .pending, scheduledAt > now {
                events.append(
                    ReminderPlanEvent(
                        identifier: prefix + "subtimer/\(reminder.id)",
                        date: scheduledAt,
                        title: reminder.displayTitle,
                    body: String(localized: "Reminder during \(step.displayTitle)")
                    )
                )
            }
        }

        for round in step.sortedFoldReminders
        where (round.status == .pending || round.status == .postponed) && round.scheduledAt > now {
            events.append(
                ReminderPlanEvent(
                    identifier: prefix + "fold/\(round.id)",
                    date: round.scheduledAt,
                    title: foldTitle(for: step),
                    body: String(localized: "Round \(round.number) of \(step.foldRepetitions)")
                )
            )
        }

        return events.sorted { $0.date < $1.date }
    }

    private static func stepEndBody(for step: SessionStep, in session: BakeSession) -> String {
        let nextTitle = session.activeStepIndex.flatMap {
            session.sortedSteps[safe: $0 + 1]?.displayTitle
        }
        if let nextTitle {
            return String(localized: "\(step.displayTitle) finished. Next: \(nextTitle).")
        }
        return String(localized: "\(step.displayTitle) finished.")
    }

    private static func foldTitle(for step: SessionStep) -> String {
        if let raw = step.foldTechniqueRaw, let technique = FoldTechnique(rawValue: raw) {
            switch technique {
            case .stretchAndFold:
                return String(localized: "Time to stretch & fold")
            case .coilFold:
                return String(localized: "Time for a coil fold")
            case .custom:
                return step.foldCustomName ?? String(localized: "Time to fold")
            }
        }
        return String(localized: "Time to stretch & fold")
    }
}

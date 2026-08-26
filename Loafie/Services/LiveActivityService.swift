import ActivityKit
import Foundation
import os

@MainActor
final class LiveActivityService {
    private var currentActivity: Activity<LoafieLiveActivityAttributes>?
    private let runningSessionProvider: () -> BakeSession?
    private let logger = Logger(subsystem: "de.kloeffer.loafies", category: "LiveActivity")

    init(runningSessionProvider: @escaping () -> BakeSession? = { nil }) {
        self.runningSessionProvider = runningSessionProvider
    }

    /// Begins or updates the Live Activity for the provided session.
    func startOrUpdate(for session: BakeSession) {
        guard session.status.isRunning else {
            logger.debug("Skipping Live Activity because session is not running")
            return
        }

        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            logger.error("Live Activities are disabled by the system")
            return
        }

        let state = makeState(from: session)
        let content = makeContent(from: state)

        if let matchingActivity = Activity<LoafieLiveActivityAttributes>.activities.first(where: {
            $0.attributes.sessionID == session.id.uuidString
        }) {
            currentActivity = matchingActivity
        }
        if let activity = currentActivity {
            Task {
                await activity.update(content)
            }
        } else {
            let attributes = LoafieLiveActivityAttributes(
                bakePlanName: session.bakePlanName,
                sessionID: session.id.uuidString
            )
            do {
                currentActivity = try Activity.request(
                    attributes: attributes,
                    content: content,
                    pushType: nil
                )
            } catch {
                logger.error("Failed to start Live Activity: \(String(describing: error), privacy: .public)")
            }
        }
    }

    /// Updates an already running Live Activity.
    func update(for session: BakeSession) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled, let activity = currentActivity else { return }
        let state = makeState(from: session)
        let content = makeContent(from: state)
        Task {
            await activity.update(content)
        }
    }

    /// Ends the Live Activity.
    func end(for session: BakeSession) {
        let sessionID = session.id.uuidString
        var activities = Activity<LoafieLiveActivityAttributes>.activities.filter {
            $0.attributes.sessionID == sessionID
        }
        if let currentActivity,
           !activities.contains(where: { $0.id == currentActivity.id }) {
            activities.append(currentActivity)
        }

        currentActivity = nil
        guard !activities.isEmpty else { return }

        let state = makeState(from: session)
        let content = makeContent(from: state)

        Task {
            for activity in activities {
                await activity.end(content, dismissalPolicy: .immediate)
            }
        }
    }

    /// Removes every Loafie Live Activity, used when no bake is running.
    func endAll() {
        let activities = Activity<LoafieLiveActivityAttributes>.activities
        currentActivity = nil
        guard !activities.isEmpty else { return }

        Task {
            for activity in activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }

    // MARK: - Refresh

    func refreshNow() {
        guard let session = runningSessionProvider(),
              session.status.isRunning else {
            endAll()
            return
        }

        startOrUpdate(for: session)
    }

    // MARK: - State construction

    func makeState(from session: BakeSession) -> LoafieLiveActivityAttributes.ContentState {
        let step = session.activeStep
        let sortedSteps = session.sortedSteps
        let nextStep = sortedSteps.first { $0.status == .pending }

        guard let step else {
            let completedStep = sortedSteps.last { $0.status == .completed }
            return LoafieLiveActivityAttributes.ContentState(
                stepTitle: nextStep?.displayTitle ?? String(localized: "Finished"),
                remainingSeconds: 0,
                nextStepTitle: nextStep?.displayTitle,
                isPaused: false,
                presentation: .waitingForNextStep,
                completedStepTitle: completedStep?.displayTitle,
                stepInstructions: nextStep?.notes,
                nextStepIsManual: nextStep?.isManualStep
            )
        }

        let isManualStep = step.isManualStep
        let remaining: Double
        let stepEndDate: Date?
        if !isManualStep, let startedAt = step.startedAt {
            remaining = TimerMath.remaining(
                startedAt: startedAt,
                plannedDuration: step.plannedDuration,
                manualAdjustment: step.manualAdjustment,
                accumulatedPause: step.accumulatedPause,
                pausedAt: session.pausedAt,
                now: Date()
            )
            stepEndDate = TimerMath.plannedEnd(
                startedAt: startedAt,
                plannedDuration: step.plannedDuration,
                manualAdjustment: step.manualAdjustment,
                accumulatedPause: step.accumulatedPause
            )
        } else {
            remaining = 0
            stepEndDate = nil
        }

        let now = Date()
        let nextSub = isManualStep ? nil : step.pendingReminders.first
        let nextSubDate: Date? = nextSub.flatMap { reminder in
            guard let startedAt = step.startedAt else { return nil }
            return scheduledDate(for: reminder, in: step, startedAt: startedAt)
        }
        let nextFold = isManualStep ? nil : step.sortedFoldReminders
            .filter { reminder in
                reminder.status == .pending || reminder.status == .due || reminder.status == .postponed
            }
            .min { $0.scheduledAt < $1.scheduledAt }
        let nextFoldDate = nextFold?.scheduledAt

        let nextReminderTitle: String?
        let nextReminderDate: Date?
        let nextReminderIsFold: Bool
        let nextFoldNumber: Int?
        switch (nextSubDate, nextFoldDate) {
        case let (subDate?, foldDate?) where foldDate < subDate:
            nextReminderTitle = nil
            nextReminderDate = foldDate
            nextReminderIsFold = true
            nextFoldNumber = nextFold?.number
        case let (subDate?, _):
            nextReminderTitle = nextSub?.displayTitle
            nextReminderDate = subDate
            nextReminderIsFold = false
            nextFoldNumber = nil
        case let (nil, foldDate?):
            nextReminderTitle = nil
            nextReminderDate = foldDate
            nextReminderIsFold = true
            nextFoldNumber = nextFold?.number
        case (nil, nil):
            nextReminderTitle = nil
            nextReminderDate = nil
            nextReminderIsFold = false
            nextFoldNumber = nil
        }
        let nextReminderSeconds = nextReminderDate.map {
            $0.timeIntervalSince(session.pausedAt ?? now)
        }

        let currentIndex = session.activeStepIndex ?? -1
        let followingStep = sortedSteps[safe: currentIndex + 1]
        return LoafieLiveActivityAttributes.ContentState(
            stepTitle: step.displayTitle,
            remainingSeconds: remaining,
            stepEndDate: stepEndDate,
            nextStepTitle: followingStep?.displayTitle,
            nextReminderTitle: nextReminderTitle,
            nextReminderIsFold: nextReminderIsFold,
            nextFoldNumber: nextFoldNumber,
            nextReminderDate: nextReminderDate,
            nextReminderSeconds: nextReminderSeconds,
            isPaused: session.status == .paused,
            presentation: isManualStep ? .manual : .timed,
            stepInstructions: isManualStep ? step.notes : nil,
            nextStepIsManual: followingStep?.isManualStep
        )
    }

    private func makeContent(
        from state: LoafieLiveActivityAttributes.ContentState
    ) -> ActivityContent<LoafieLiveActivityAttributes.ContentState> {
        ActivityContent(
            state: state,
            // Time-based views recalculate from absolute dates in the widget
            // process, including while the app is suspended. The phase can
            // also remain active after its target time, so it isn't stale.
            staleDate: nil
        )
    }

    private func scheduledDate(
        for target: SessionReminder,
        in step: SessionStep,
        startedAt: Date
    ) -> Date? {
        var previousDate: Date?
        for reminder in step.sortedReminders {
            let date = TimerMath.reminderDate(
                stepStart: startedAt,
                stepDuration: step.plannedDuration,
                stepAdjustment: step.manualAdjustment,
                pauseDuration: step.accumulatedPause,
                offset: reminder.offset,
                mode: reminder.triggerMode,
                previousDate: previousDate
            )
            previousDate = date
            if reminder.id == target.id {
                return date
            }
        }
        return nil
    }
}

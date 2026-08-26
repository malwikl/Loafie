import Foundation
import Observation
import SwiftData

/// Central session lifecycle engine. All mutations persist timestamps;
/// notifications are replanned after every mutation.
@MainActor
@Observable
final class SessionStore {

    enum SessionError: Error, Equatable {
        case sessionAlreadyRunning
        case noActiveStep
    }

    let modelContext: ModelContext
    var notificationService: NotificationService?
    var liveActivityService: LiveActivityService?
    private let settings: SettingsStore?

    @ObservationIgnored private var now: () -> Date

    init(
        modelContext: ModelContext,
        notificationService: NotificationService? = nil,
        liveActivityService: LiveActivityService? = nil,
        settings: SettingsStore? = nil,
        now: @escaping () -> Date = Date.init
    ) {
        self.modelContext = modelContext
        self.notificationService = notificationService
        self.liveActivityService = liveActivityService
        self.settings = settings
        self.now = now
    }

    // MARK: - Queries

    func runningSession() -> BakeSession? {
        let active = SessionStatus.active.rawValue
        let paused = SessionStatus.paused.rawValue
        let descriptor = FetchDescriptor<BakeSession>(
            predicate: #Predicate { $0.statusRaw == active || $0.statusRaw == paused }
        )
        return try? modelContext.fetch(descriptor).first
    }

    func currentSession() -> BakeSession? {
        let planned = SessionStatus.planned.rawValue
        let active = SessionStatus.active.rawValue
        let paused = SessionStatus.paused.rawValue
        let descriptor = FetchDescriptor<BakeSession>(
            predicate: #Predicate {
                $0.statusRaw == planned || $0.statusRaw == active || $0.statusRaw == paused
            }
        )
        return try? modelContext.fetch(descriptor).first
    }

    /// Reconciles all timestamp-derived outputs after the app returns from suspension.
    /// Suspension never changes the session timestamps or step status.
    func reconcileAfterLifecycleChange() {
        guard let session = currentSession() else {
            liveActivityService?.endAll()
            return
        }
        ensurePlannedTimes(for: session)
        if session.status.isRunning {
            refreshFoldStates(session)
            liveActivityService?.startOrUpdate(for: session)
        }
        notificationService?.reschedule(for: session)
        try? modelContext.save()
    }

    // MARK: - Start / Cancel

    /// Starts a session from a bakePlan by deep-copying its enabled steps.
    /// Fails with `sessionAlreadyRunning` if another session is active or paused.
    @discardableResult
    func start(bakePlan: BakePlan) throws -> BakeSession {
        if currentSession() != nil {
            throw SessionError.sessionAlreadyRunning
        }
        let timestamp = now()
        let session = BakeSession(
            bakePlanID: bakePlan.id,
            bakePlanName: bakePlan.name,
            startedAt: timestamp,
            autoAdvanceSteps: bakePlan.autoAdvanceSteps
        )
        for (index, definition) in bakePlan.enabledSteps.enumerated() {
            let step = SessionStep(from: definition, sortIndex: index)
            step.session = session
            session.steps.append(step)
        }
        assignPlannedTimes(to: session, from: timestamp)
        modelContext.insert(session)
        bakePlan.lastUsedAt = timestamp

        if !session.sortedSteps.isEmpty {
            activateStep(at: 0, in: session, at: timestamp)
        } else {
            session.status = .completed
        }
        sessionDidChange(session)
        liveActivityService?.startOrUpdate(for: session)
        return session
    }

    /// Creates a session snapshot that waits until the requested start time.
    @discardableResult
    func plan(bakePlan: BakePlan, startAt: Date) throws -> BakeSession {
        let target = startAt.addingTimeInterval(bakePlan.typicalDuration)
        return try plan(
            bakePlan: bakePlan,
            target: target,
            mode: .readyToSlice,
            plannedStartAt: startAt
        )
    }

    /// Creates a manually-started waiting session from a backwards plan.
    @discardableResult
    func plan(
        bakePlan: BakePlan,
        target: Date,
        mode: BakeStartPlanner.TargetMode,
        plannedStartAt: Date? = nil
    ) throws -> BakeSession {
        if currentSession() != nil {
            throw SessionError.sessionAlreadyRunning
        }

        let planning = BakeStartPlanner.result(bakePlan: bakePlan, target: target, mode: mode)
        let selectedStart = plannedStartAt ?? planning.recommendedStart

        let session = BakeSession(
            bakePlanID: bakePlan.id,
            bakePlanName: bakePlan.name,
            startedAt: selectedStart,
            plannedStartAt: selectedStart,
            planningTargetAt: target,
            planningTargetModeRaw: mode.rawValue,
            planningEarliestStartAt: planning.earliestStart,
            planningLatestStartAt: planning.latestStart,
            autoAdvanceSteps: bakePlan.autoAdvanceSteps
        )
        // `BakeSession` defaults to active for the immediate-start path.
        // A backwards-planned session remains waiting until its start time.
        session.status = .planned
        for (index, definition) in bakePlan.enabledSteps.enumerated() {
            let step = SessionStep(from: definition, sortIndex: index)
            step.session = session
            session.steps.append(step)
        }
        assignPlannedTimes(to: session, from: selectedStart)
        modelContext.insert(session)
        bakePlan.lastUsedAt = now()
        sessionDidChange(session)
        return session
    }

    func startPlannedSession(_ session: BakeSession) {
        guard session.status == .planned else { return }
        let timestamp = now()
        session.status = .active
        session.plannedStartAt = nil
        session.startedAt = timestamp
        if session.sortedSteps.isEmpty {
            session.status = .completed
        } else {
            activateStep(at: 0, in: session, at: timestamp)
        }
        sessionDidChange(session)
        liveActivityService?.startOrUpdate(for: session)
    }

    func cancel(_ session: BakeSession) {
        session.status = .cancelled
        session.pausedAt = nil
        session.activeStepIndex = nil
        sessionDidChange(session)
        liveActivityService?.end(for: session)
    }

    // MARK: - Pause / Resume

    func pause(_ session: BakeSession) {
        guard session.status == .active, let step = session.activeStep else { return }
        session.status = .paused
        session.pausedAt = now()
        step.status = .paused
        sessionDidChange(session)
        liveActivityService?.startOrUpdate(for: session)
    }

    func resume(_ session: BakeSession) {
        guard session.status == .paused, let step = session.activeStep,
              let pausedAt = session.pausedAt else { return }
        step.accumulatedPause += now().timeIntervalSince(pausedAt)
        step.status = .active
        session.status = .active
        session.pausedAt = nil
        sessionDidChange(session)
        liveActivityService?.startOrUpdate(for: session)
    }

    // MARK: - Extend

    func extend(_ session: BakeSession, by seconds: TimeInterval) {
        guard session.status.isRunning, let step = session.activeStep else { return }
        step.manualAdjustment += seconds
        sessionDidChange(session)
        liveActivityService?.startOrUpdate(for: session)
    }

    @discardableResult
    func extendCurrentStep(for sessionID: UUID, by seconds: TimeInterval) -> Bool {
        guard seconds > 0,
              let session = runningSession(),
              session.id == sessionID,
              session.activeStep != nil else { return false }
        extend(session, by: seconds)
        return true
    }

    // MARK: - Step completion

    /// Completes the active step. The last step completes the session;
    /// otherwise the user starts the next step manually.
    func completeActiveStep(_ session: BakeSession) {
        guard session.status.isRunning, let step = session.activeStep else { return }
        let completionDate = now()
        let wasEarly = step.startedAt.map {
            completionDate < TimerMath.plannedEnd(
                startedAt: $0,
                plannedDuration: step.plannedDuration,
                manualAdjustment: step.manualAdjustment,
                accumulatedPause: step.accumulatedPause + (session.pausedAt.map { completionDate.timeIntervalSince($0) } ?? 0)
            )
        } ?? false
        finish(step: step, session: session, as: .completed)

        let steps = session.sortedSteps
        guard let currentIndex = session.activeStepIndex else { return }
        let isLast = currentIndex == steps.count - 1

        if !isLast && wasEarly && (settings?.askBeforePlanAdjustment ?? true) {
            session.pendingPlanAdjustmentStepID = step.id
        }

        if isLast {
            session.status = .completed
            session.activeStepIndex = nil
            sessionDidChange(session)
            liveActivityService?.end(for: session)
        } else {
            session.activeStepIndex = nil
            sessionDidChange(session)
            liveActivityService?.startOrUpdate(for: session)
        }
    }

    func resolvePlanAdjustment(for session: BakeSession, adjust: Bool) {
        guard let stepID = session.pendingPlanAdjustmentStepID else { return }
        session.pendingPlanAdjustmentStepID = nil
        if adjust,
           let completedAt = session.sortedSteps.first(where: { $0.id == stepID })?.completedAt {
            session.plannedStartAt = completedAt
            shiftPendingPlan(for: session, after: stepID, from: completedAt)
        }
        sessionDidChange(session)
        liveActivityService?.startOrUpdate(for: session)
    }

    /// Starts the next pending step. An overdue active step is completed implicitly.
    func startNextStep(_ session: BakeSession) {
        if let step = session.activeStep, step.status == .active || step.status == .paused {
            finish(step: step, session: session, as: .completed)
        }
        let steps = session.sortedSteps
        guard let nextIndex = steps.firstIndex(where: { $0.status == .pending }) else {
            session.status = .completed
            session.activeStepIndex = nil
            sessionDidChange(session)
            liveActivityService?.end(for: session)
            return
        }
        session.status = .active
        session.pausedAt = nil
        activateStep(at: nextIndex, in: session, at: now())
        sessionDidChange(session)
        liveActivityService?.startOrUpdate(for: session)
    }

    private func finish(step: SessionStep, session: BakeSession, as status: BakeStepStatus) {
        let timestamp = now()
        if session.status == .paused, let pausedAt = session.pausedAt {
            step.accumulatedPause += timestamp.timeIntervalSince(pausedAt)
            session.pausedAt = nil
            session.status = .active
        }
        step.status = status
        step.completedAt = timestamp
        if let startedAt = step.startedAt {
            step.effectiveDuration = timestamp.timeIntervalSince(startedAt) - step.accumulatedPause
        }
    }

    // MARK: - Fold rounds

    func completeFoldReminder(_ round: SessionFoldReminder) {
        round.status = .completed
        round.completedAt = now()
        if let session = round.step?.session {
            sessionDidChange(session)
        }
    }

    func postponeFoldReminder(_ round: SessionFoldReminder, by seconds: TimeInterval = 600) {
        round.postponedBy += seconds
        round.scheduledAt = now().addingTimeInterval(seconds)
        round.status = .postponed
        if let session = round.step?.session {
            sessionDidChange(session)
        }
    }

    /// Marks fold rounds due whose scheduled time has passed. Persisted so state
    /// survives app restarts.
    func refreshFoldStates(_ session: BakeSession) {
        let timestamp = now()
        for step in session.steps {
            for round in step.foldReminders
            where round.status == .pending && round.scheduledAt <= timestamp {
                round.status = .due
            }
            refreshReminderStates(step: step, at: timestamp)
        }
    }

    // MARK: - Reminders

    /// Marks sub-timers as triggered once their scheduled time has passed.
    private func refreshReminderStates(step: SessionStep, at timestamp: Date) {
        guard let startedAt = step.startedAt else { return }
        var previousDate: Date?
        for reminder in step.sortedReminders {
            let scheduledAt = TimerMath.reminderDate(
                stepStart: startedAt,
                stepDuration: step.plannedDuration,
                stepAdjustment: step.manualAdjustment,
                pauseDuration: step.accumulatedPause,
                offset: reminder.offset,
                mode: reminder.triggerMode,
                previousDate: previousDate
            )
            previousDate = scheduledAt
            if reminder.status == .pending && scheduledAt <= timestamp {
                reminder.status = .triggered
            }
        }
    }

    func completeReminder(_ reminder: SessionReminder) {
        reminder.status = .completed
        reminder.completedAt = now()
        if let session = reminder.step?.session {
            sessionDidChange(session)
            liveActivityService?.startOrUpdate(for: session)
        }
    }

    func toggleReminder(_ reminder: SessionReminder) {
        if reminder.status == .completed {
            reminder.status = .pending
            reminder.completedAt = nil
        } else if reminder.status == .pending || reminder.status == .triggered {
            reminder.status = .completed
            reminder.completedAt = now()
        }
        guard let session = reminder.step?.session else { return }
        sessionDidChange(session)
        liveActivityService?.startOrUpdate(for: session)
    }

    // MARK: - Internals

    private func activateStep(at index: Int, in session: BakeSession, at date: Date) {
        guard let step = session.sortedSteps[safe: index] else { return }
        if step.plannedStartAt == nil {
            let previousEnd = session.sortedSteps[safe: index - 1]?.plannedEndAt ?? date
            step.plannedStartAt = previousEnd
            step.plannedEndAt = previousEnd.addingTimeInterval(step.plannedDuration)
        }
        step.status = .active
        step.startedAt = date
        session.activeStepIndex = index

        if step.foldIsEnabled, step.foldRepetitions > 0, let startedAt = step.startedAt {
            let offsets = FoldReminderCalculator.roundOffsets(
                repetitions: step.foldRepetitions,
                interval: step.foldInterval,
                firstReminderOffset: step.foldFirstOffset
            )
            for (roundIndex, offset) in offsets.enumerated() {
                let round = SessionFoldReminder(
                    number: roundIndex + 1,
                    scheduledAt: startedAt.addingTimeInterval(offset)
                )
                round.step = step
                step.foldReminders.append(round)
            }
        }

        for reminder in step.sortedReminders {
            reminder.status = .pending
        }
    }

    private func assignPlannedTimes(to session: BakeSession, from start: Date) {
        var cursor = start
        for step in session.sortedSteps {
            step.plannedStartAt = cursor
            step.plannedEndAt = cursor.addingTimeInterval(step.plannedDuration)
            cursor = step.plannedEndAt ?? cursor
        }
    }

    private func ensurePlannedTimes(for session: BakeSession) {
        guard session.sortedSteps.contains(where: { $0.plannedStartAt == nil || $0.plannedEndAt == nil }) else { return }
        assignPlannedTimes(to: session, from: session.startedAt)
    }

    private func shiftPendingPlan(for session: BakeSession, after stepID: UUID, from start: Date) {
        guard let completedIndex = session.sortedSteps.firstIndex(where: {
            $0.id == stepID
        }) else { return }
        var cursor = start
        for step in session.sortedSteps.dropFirst(completedIndex + 1)
        where step.status == .pending {
            step.plannedStartAt = cursor
            step.plannedEndAt = cursor.addingTimeInterval(step.plannedDuration)
            cursor = step.plannedEndAt ?? cursor
        }
    }

    private func sessionDidChange(_ session: BakeSession) {
        notificationService?.reschedule(for: session)
        NotificationCenter.default.post(name: .sessionDidChange, object: session)
    }
}

extension Notification.Name {
    static let sessionDidChange = Notification.Name("LoafieSessionDidChange")
}

import Foundation
import WatchConnectivity

/// iPhone-side WatchConnectivity manager.
///
/// - Publishes a compact, Codable snapshot of the running session via
///   `updateApplicationContext`.
/// - Receives quick-action messages from the Watch, validates them on the
///   iPhone and persists the result through `SessionStore`.
@MainActor
final class WatchSessionManager: NSObject {

    private let sessionStore: SessionStore
    private var session: BakeSession? { sessionStore.runningSession() }

    init(sessionStore: SessionStore) {
        self.sessionStore = sessionStore
        super.init()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sessionDidChange),
            name: .sessionDidChange,
            object: nil
        )
    }

    @objc private func sessionDidChange() {
        sendSnapshot()
    }

    func activate() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    /// Encodes the current running session into an application-context update.
    func sendSnapshot() {
        guard WCSession.isSupported() else { return }
        let context = makeSnapshot()
        do {
            let data = try JSONEncoder().encode(context)
            let dictionary = ["snapshot": data]
            try? WCSession.default.updateApplicationContext(dictionary)
        } catch {
            // Silently ignore encoding failures; the next state change will retry.
        }
    }

    func makeSnapshot() -> WatchSessionSnapshot {
        guard let session else {
            return WatchSessionSnapshot(
                sessionID: nil,
                bakePlanName: nil,
                status: SessionStatus.cancelled.rawValue,
                step: nil
            )
        }

        let active = session.activeStep
        let steps = session.sortedSteps
        let nextIndex = active.flatMap { steps.firstIndex(of: $0).map { $0 + 1 } }
        let nextStep = nextIndex.flatMap { steps[safe: $0] }

        var remaining: TimeInterval?
        if let active, let startedAt = active.startedAt {
            remaining = TimerMath.remaining(
                startedAt: startedAt,
                plannedDuration: active.plannedDuration,
                manualAdjustment: active.manualAdjustment,
                accumulatedPause: active.accumulatedPause,
                pausedAt: session.pausedAt,
                now: Date()
            )
        }

        var coldState: String?
        if let active, active.isColdStep, let startedAt = active.startedAt {
            coldState = ColdStepState.classify(
                startedAt: startedAt,
                target: active.plannedDuration,
                minimum: active.minimumDuration,
                maximum: active.maximumDuration,
                manualAdjustment: active.manualAdjustment,
                accumulatedPause: active.accumulatedPause,
                pausedAt: session.pausedAt,
                now: Date()
            ).rawValue
        }

        let foldSnapshot: WatchFoldReminderSnapshot? = active.flatMap { step in
            step.nextDueFoldReminder.map { round in
                WatchFoldReminderSnapshot(
                    id: round.id.uuidString,
                    number: round.number,
                    total: step.foldRepetitions,
                    status: round.status.rawValue,
                    scheduledAt: round.scheduledAt
                )
            }
        }

        let stepSnapshot = active.map { step in
            WatchStepSnapshot(
                id: step.id.uuidString,
                title: step.displayTitle,
                symbolName: step.type.symbolName,
                status: step.status.rawValue,
                remainingSeconds: remaining ?? 0,
                targetDate: active.flatMap { step in
                    guard let startedAt = step.startedAt else { return nil }
                    return TimerMath.plannedEnd(startedAt: startedAt, plannedDuration: step.plannedDuration, manualAdjustment: step.manualAdjustment, accumulatedPause: step.accumulatedPause)
                },
                isColdStep: step.isColdStep,
                coldState: coldState,
                nextStepTitle: nextStep?.displayTitle,
                foldReminder: foldSnapshot,
                allowedActions: allowedActions(for: step, session: session)
            )
        }

        return WatchSessionSnapshot(
            sessionID: session.id.uuidString,
            bakePlanName: session.bakePlanName,
            status: session.status.rawValue,
            step: stepSnapshot
        )
    }

    private func allowedActions(for step: SessionStep, session: BakeSession) -> [String] {
        guard session.status.isRunning else { return [] }
        var actions: [String] = [
            WatchAction.completeStep.rawValue,
            WatchAction.togglePause.rawValue,
            WatchAction.extendStep.rawValue
        ]
        if step.foldIsEnabled && step.foldRepetitions > 0 {
            actions.append(contentsOf: [
                WatchAction.completeFoldReminder.rawValue,
                WatchAction.postponeFoldReminder.rawValue
            ])
        }
        return actions
    }

    // MARK: - Action handling

    func handleAction(_ action: WatchAction, payload: [String: Any]) {
        guard let session else { return }
        switch action {
        case .requestSnapshot:
            sendSnapshot()
        case .completeStep:
            if session.status.isRunning {
                sessionStore.completeActiveStep(session)
            }
        case .togglePause:
            if session.status == .active {
                sessionStore.pause(session)
            } else if session.status == .paused {
                sessionStore.resume(session)
            }
        case .extendStep:
            guard let seconds = payload["seconds"] as? TimeInterval, seconds > 0 else { return }
            sessionStore.extend(session, by: seconds)
        case .completeFoldReminder:
            guard let id = payload["foldReminderID"] as? String,
                  let round = findFoldReminder(id: id, in: session) else { return }
            sessionStore.completeFoldReminder(round)
        case .postponeFoldReminder:
            guard let id = payload["foldReminderID"] as? String,
                  let round = findFoldReminder(id: id, in: session) else { return }
            sessionStore.postponeFoldReminder(round)
        }
        sendSnapshot()
    }

    private func findFoldReminder(id: String, in session: BakeSession) -> SessionFoldReminder? {
        session.sortedSteps.lazy.flatMap(\.foldReminders).first { $0.id.uuidString == id }
    }
}

// MARK: - WCSessionDelegate

extension WatchSessionManager: WCSessionDelegate {

    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        Task { @MainActor in
            self.sendSnapshot()
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        guard let raw = message["action"] as? String,
              let action = WatchAction(rawValue: raw) else {
            replyHandler(["ok": false])
            return
        }
        Task { @MainActor [weak self] in
            self?.handleAction(action, payload: message)
            replyHandler(["ok": true])
        }
    }
}

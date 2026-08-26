import Foundation
import Testing
@testable import Loafie

@MainActor
struct LiveActivityStateTests {

    @Test func absoluteTimerDatesSurviveActivityStateEncoding() throws {
        let phaseEnd = Date(timeIntervalSince1970: 3_600)
        let reminderDate = Date(timeIntervalSince1970: 1_200)
        let state = LoafieLiveActivityAttributes.ContentState(
            stepTitle: "Bulk",
            remainingSeconds: 900,
            stepEndDate: phaseEnd,
            nextStepTitle: "Shape",
            nextReminderTitle: "Fold",
            nextReminderIsFold: true,
            nextFoldNumber: 2,
            nextReminderDate: reminderDate,
            nextReminderSeconds: 300
        )

        let encoded = try JSONEncoder().encode(state)
        let decoded = try JSONDecoder().decode(
            LoafieLiveActivityAttributes.ContentState.self,
            from: encoded
        )

        #expect(decoded.stepEndDate == phaseEnd)
        #expect(decoded.nextReminderDate == reminderDate)
        #expect(decoded.nextReminderSeconds == 300)
        #expect(decoded.nextReminderIsFold == true)
        #expect(decoded.nextFoldNumber == 2)
        #expect(decoded.presentation == .timed)
    }

    @Test func pausedStateKeepsFrozenFallback() {
        let state = LoafieLiveActivityAttributes.ContentState(
            stepTitle: "Bulk",
            remainingSeconds: 120,
            nextReminderTitle: "Fold",
            nextReminderDate: Date(timeIntervalSince1970: 600),
            nextReminderSeconds: 45,
            isPaused: true
        )

        #expect(state.isPaused)
        #expect(state.nextReminderSeconds == 45)
    }

    @Test func completedStepWaitsForTheNextStepInsteadOfShowingTheSessionAsFinished() {
        let session = BakeSession(bakePlanID: UUID(), bakePlanName: "Test")
        let completed = SessionStep(
            from: BakeStepDefinition(type: .autolyse, title: "Autolyse", duration: 30 * 60, sortIndex: 0),
            sortIndex: 0
        )
        let next = SessionStep(
            from: BakeStepDefinition(type: .mix, title: "Mischen", duration: nil, notes: "Mehl und Wasser verbinden.", sortIndex: 1),
            sortIndex: 1
        )
        completed.status = .completed
        session.steps = [completed, next]

        let state = LiveActivityService().makeState(from: session)

        #expect(state.presentation == .waitingForNextStep)
        #expect(state.completedStepTitle == "Autolyse")
        #expect(state.stepTitle == "Mischen")
        #expect(state.nextStepIsManual == true)
        #expect(state.stepInstructions == "Mehl und Wasser verbinden.")
    }

    @Test func manualStepDoesNotPublishAnEndDate() {
        let session = BakeSession(bakePlanID: UUID(), bakePlanName: "Test")
        let step = SessionStep(
            from: BakeStepDefinition(type: .shaping, title: "Formen", duration: nil, notes: "Teig formen.", sortIndex: 0),
            sortIndex: 0
        )
        step.status = .active
        step.startedAt = Date(timeIntervalSince1970: 1_000)
        session.steps = [step]
        session.activeStepIndex = 0

        let state = LiveActivityService().makeState(from: session)

        #expect(state.presentation == .manual)
        #expect(state.stepEndDate == nil)
        #expect(state.stepInstructions == "Teig formen.")
    }
}

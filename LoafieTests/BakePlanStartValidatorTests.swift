import Foundation
import Testing
@testable import Loafie

struct BakePlanStartValidatorTests {

    @Test func validOvernightScheduleHasNoIssues() {
        let bakePlan = BakePlanTemplates.makeBakePlan(name: "Overnight", timing: .coldFinalProof)

        #expect(BakePlanStartValidator.issues(for: bakePlan).isEmpty)
    }

    @Test func invalidColdWindowIsReported() {
        let step = BakeStepDefinition(
            type: .coldFinalProof,
            duration: 12 * 3600,
            minimumDuration: 14 * 3600,
            maximumDuration: 24 * 3600,
            sortIndex: 0
        )
        let bakePlan = makeBakePlan(with: step)

        #expect(BakePlanStartValidator.issues(for: bakePlan).map(\.id) == ["cold-window-\(step.id.uuidString)"])
    }

    @Test func foldAfterBulkIsReported() {
        let step = BakeStepDefinition(
            type: .bulkRoomTemperature,
            duration: 90 * 60,
            sortIndex: 0,
            foldReminderConfiguration: FoldReminderConfiguration(
                repetitions: 4,
                interval: 30 * 60,
                firstReminderOffset: 30 * 60
            )
        )
        let bakePlan = makeBakePlan(with: step)

        #expect(BakePlanStartValidator.issues(for: bakePlan).map(\.id) == ["folds-\(step.id.uuidString)"])
    }

    @Test func invalidReminderDetailsAreReported() {
        let timer = ReminderDefinition(
            title: "Lower temperature",
            offset: 2 * 3600,
            sortIndex: 0,
            type: .lowerTemperature
        )
        let step = BakeStepDefinition(
            type: .bake,
            duration: 45 * 60,
            sortIndex: 0,
            reminders: [timer]
        )
        let bakePlan = makeBakePlan(with: step)

        #expect(
            BakePlanStartValidator.issues(for: bakePlan).map(\.id) == [
                "timer-offset-\(timer.id.uuidString)",
                "timer-temperature-\(timer.id.uuidString)",
            ]
        )
    }

    @Test func invalidDisabledStepDoesNotBlockStarting() {
        let step = BakeStepDefinition(
            type: .coldFinalProof,
            duration: 12 * 3600,
            minimumDuration: 14 * 3600,
            maximumDuration: 24 * 3600,
            isEnabled: false,
            sortIndex: 0
        )
        let bakePlan = makeBakePlan(with: step)

        #expect(BakePlanStartValidator.issues(for: bakePlan).isEmpty)
    }

    private func makeBakePlan(with step: BakeStepDefinition) -> BakePlan {
        let bakePlan = BakePlan(name: "Test", timing: .sameDay)
        bakePlan.steps = [step]
        return bakePlan
    }
}

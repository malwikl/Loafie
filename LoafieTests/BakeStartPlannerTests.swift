import Testing
import Foundation
@testable import Loafie

@MainActor
struct BakeStartPlannerTests {

    @Test func bakeStartTarget() {
        let bakePlan = makeBakePlan()
        let target = makeDate(hour: 8, minute: 0)
        let start = BakeStartPlanner.suggestedStart(
            bakePlan: bakePlan,
            target: target,
            mode: .bakeStart
        )
        // autolyse 30m + mix 10m + bulk 4h + bench 20m + final 90m = 6h30m
        let offset = target.timeIntervalSince(start)
        #expect(offset == 6 * 3600 + 30 * 60)
    }

    @Test func readyToSliceTarget() {
        let bakePlan = makeBakePlan()
        let target = makeDate(hour: 12, minute: 0)
        let start = BakeStartPlanner.suggestedStart(
            bakePlan: bakePlan,
            target: target,
            mode: .readyToSlice
        )
        // total: 6h30m + bake 45m + cooling 60m = 8h15m
        let offset = target.timeIntervalSince(start)
        #expect(offset == 8 * 3600 + 15 * 60)
    }

    @Test func coldWindowUsesMaximumForEarliestAndMinimumForLatest() {
        let bakePlan = BakePlan(name: "Overnight", timing: .coldFinalProof)
        bakePlan.steps = [
            BakeStepDefinition(type: .bulkRoomTemperature, duration: 2 * 3600, sortIndex: 0),
            BakeStepDefinition(
                type: .coldFinalProof,
                duration: 12 * 3600,
                minimumDuration: 8 * 3600,
                maximumDuration: 24 * 3600,
                sortIndex: 1
            ),
            BakeStepDefinition(type: .bake, duration: 45 * 60, sortIndex: 2),
        ]
        let target = makeDate(hour: 8, minute: 0)
        let result = BakeStartPlanner.result(bakePlan: bakePlan, target: target, mode: .bakeStart)

        #expect(result.recommendedStart == target.addingTimeInterval(-(14 * 3600)))
        #expect(result.earliestStart == target.addingTimeInterval(-(26 * 3600)))
        #expect(result.latestStart == target.addingTimeInterval(-(10 * 3600)))
    }

    // MARK: - Helpers

    private func makeBakePlan() -> BakePlan {
        let bakePlan = BakePlan(name: "Test", timing: .sameDay)
        bakePlan.steps = [
            BakeStepDefinition(type: BakeStepType.autolyse, duration: 30 * 60, sortIndex: 0),
            BakeStepDefinition(type: BakeStepType.mix, duration: 10 * 60, sortIndex: 1),
            BakeStepDefinition(type: BakeStepType.bulkRoomTemperature, duration: 4 * 3600, sortIndex: 2),
            BakeStepDefinition(type: BakeStepType.benchRest, duration: 20 * 60, sortIndex: 3),
            BakeStepDefinition(type: BakeStepType.finalProofRoomTemperature, duration: 90 * 60, sortIndex: 4),
            BakeStepDefinition(type: BakeStepType.bake, duration: 45 * 60, sortIndex: 5),
            BakeStepDefinition(type: BakeStepType.cooling, duration: 60 * 60, sortIndex: 6),
        ]
        return bakePlan
    }

    private func makeDate(hour: Int, minute: Int) -> Date {
        var components = DateComponents()
        components.year = 2026
        components.month = 8
        components.day = 16
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components) ?? Date()
    }
}

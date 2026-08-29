import Foundation
import Testing
@testable import Loafie

@MainActor
struct OvernightPlanAdjusterTests {

    @Test func earlyStartExtendsColdPhaseAndKeepsBakeStart() {
        let start = date(hour: 0)
        let actualStart = start.addingTimeInterval(-2 * 60 * 60)
        let target = date(hour: 8)
        let steps = makeSteps(coldDuration: 8 * 3600, minimum: 6 * 3600, maximum: 10 * 3600)

        let result = OvernightPlanAdjuster.result(
            steps: steps,
            actualStart: actualStart,
            target: target,
            mode: .bakeStart
        )

        #expect(result == .adjusted(9 * 3600))
        #expect(steps[0].plannedDuration == 60 * 60)
        #expect(steps[1].plannedDuration == 9 * 3600)
        #expect(steps[2].plannedDuration == 45 * 60)
    }

    @Test func lateStartShortensColdPhaseAndKeepsReadyToSlice() {
        let actualStart = date(hour: 0)
        let target = date(hour: 12)
        let steps = makeSteps(coldDuration: 10 * 3600, minimum: 6 * 3600, maximum: 12 * 3600, includeCooling: true)

        let result = OvernightPlanAdjuster.result(
            steps: steps,
            actualStart: actualStart,
            target: target,
            mode: .readyToSlice
        )

        let expectedDuration = TimeInterval(9 * 3600 + 15 * 60)
        #expect(result == .adjusted(expectedDuration))
        #expect(steps[2].plannedDuration == 45 * 60)
        #expect(steps[3].plannedDuration == 60 * 60)
    }

    @Test func exactBoundariesAreAllowed() {
        let steps = makeSteps(coldDuration: 8 * 3600, minimum: 8 * 3600, maximum: 10 * 3600)

        #expect(OvernightPlanAdjuster.result(steps: steps, actualStart: date(hour: 0), target: date(hour: 9), mode: .bakeStart) == .adjusted(8 * 3600))
        #expect(OvernightPlanAdjuster.result(steps: steps, actualStart: date(hour: -2), target: date(hour: 9), mode: .bakeStart) == .adjusted(10 * 3600))
    }

    @Test func outsideWindowBlocksAdjustment() {
        let steps = makeSteps(coldDuration: 8 * 3600, minimum: 8 * 3600, maximum: 10 * 3600)

        #expect(OvernightPlanAdjuster.result(steps: steps, actualStart: date(hour: 1), target: date(hour: 9), mode: .bakeStart) == .outsideColdWindow)
    }

    private func makeSteps(
        coldDuration: TimeInterval,
        minimum: TimeInterval,
        maximum: TimeInterval,
        includeCooling: Bool = false
    ) -> [SessionStep] {
        let definitions = [
            BakeStepDefinition(type: .kneading, duration: 60 * 60, sortIndex: 0),
            BakeStepDefinition(type: .coldFinalProof, duration: coldDuration, minimumDuration: minimum, maximumDuration: maximum, sortIndex: 1),
            BakeStepDefinition(type: .bake, duration: 45 * 60, sortIndex: 2),
        ] + (includeCooling ? [BakeStepDefinition(type: .cooling, duration: 60 * 60, sortIndex: 3)] : [])
        return definitions.enumerated().map { SessionStep(from: $0.element, sortIndex: $0.offset) }
    }

    private func date(hour: Int) -> Date {
        Date(timeIntervalSince1970: TimeInterval(hour * 3600))
    }
}

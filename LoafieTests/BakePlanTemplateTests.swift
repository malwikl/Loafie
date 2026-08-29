import Testing
@testable import Loafie

struct BakePlanTemplateTests {

    @Test(arguments: BakePlanTiming.allCases)
    func everyTemplateStartsWithOptionalSourdoughBuild(timing: BakePlanTiming) {
        let steps = BakePlanTemplates.makeSteps(for: timing)
        let first = steps.first

        #expect(first?.type == .sourdoughBuild)
        #expect(first?.isEnabled == false)
        #expect((first?.duration ?? -1) == 10 * 3600)
        #expect((first?.minimumDuration ?? -1) == 8 * 3600)
        #expect((first?.maximumDuration ?? -1) == 12 * 3600)
    }
}

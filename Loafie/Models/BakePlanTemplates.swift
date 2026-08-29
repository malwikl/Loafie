import Foundation

/// Builds default step sets for each bake-plan timing option.
enum BakePlanTemplates {

    static func makeBakePlan(name: String, timing: BakePlanTiming) -> BakePlan {
        let bakePlan = BakePlan(name: name, timing: timing)
        bakePlan.steps = makeSteps(for: timing)
        for step in bakePlan.steps {
            step.bakePlan = bakePlan
            step.foldReminderConfiguration?.step = step
            for reminder in step.reminders ?? [] {
                reminder.step = step
            }
        }
        return bakePlan
    }

    static func makeSteps(for timing: BakePlanTiming) -> [BakeStepDefinition] {
        switch timing {
        case .sameDay: sameDaySteps()
        case .coldFinalProof: coldFinalProofSteps()
        case .coldBulk: coldBulkSteps()
        }
    }

    // MARK: - Building blocks

    private static func sourdoughBuild(_ index: inout Int) -> BakeStepDefinition {
        defer { index += 1 }
        return BakeStepDefinition(
            type: .sourdoughBuild,
            duration: 10 * 3600,
            minimumDuration: 8 * 3600,
            maximumDuration: 12 * 3600,
            isEnabled: false,
            sortIndex: index
        )
    }

    private static func autolyse(_ index: inout Int) -> BakeStepDefinition {
        defer { index += 1 }
        return BakeStepDefinition(
            type: .autolyse,
            duration: 30 * 60,
            isEnabled: false,
            sortIndex: index
        )
    }

    private static func mix(_ index: inout Int) -> BakeStepDefinition {
        defer { index += 1 }
        return BakeStepDefinition(
            type: .mix,
            duration: 0,
            sortIndex: index
        )
    }

    private static func kneading(_ index: inout Int) -> BakeStepDefinition {
        defer { index += 1 }
        return BakeStepDefinition(
            type: .kneading,
            duration: 10 * 60,
            sortIndex: index
        )
    }

    private static func bulkRoom(_ index: inout Int, hours: Double, folds: Bool) -> BakeStepDefinition {
        defer { index += 1 }
        let fold = FoldReminderConfiguration(
            isEnabled: folds,
            repetitions: 2,
            interval: 60 * 60,
            firstReminderOffset: 60 * 60
        )
        return BakeStepDefinition(
            type: .bulkRoomTemperature,
            duration: hours * 3600,
            sortIndex: index,
            foldReminderConfiguration: fold
        )
    }

    private static func benchRest(_ index: inout Int) -> BakeStepDefinition {
        defer { index += 1 }
        return BakeStepDefinition(
            type: .benchRest,
            duration: 20 * 60,
            isEnabled: false,
            sortIndex: index
        )
    }

    private static func shaping(_ index: inout Int) -> BakeStepDefinition {
        defer { index += 1 }
        return BakeStepDefinition(
            type: .shaping,
            duration: 0,
            sortIndex: index
        )
    }

    private static func finalProofRoom(_ index: inout Int) -> BakeStepDefinition {
        defer { index += 1 }
        let preheat = ReminderDefinition(
            title: String(localized: "Preheat oven"),
            offset: 45 * 60,
            sortIndex: 0,
            type: .preheatOven,
            triggerMode: .beforeStepEnd
        )
        return BakeStepDefinition(
            type: .finalProofRoomTemperature,
            duration: 90 * 60,
            sortIndex: index,
            reminders: [preheat]
        )
    }

    private static func bake(_ index: inout Int) -> BakeStepDefinition {
        defer { index += 1 }
        let lidRemoval = ReminderDefinition(
            title: String(localized: "Remove lid"),
            offset: 20 * 60,
            sortIndex: 0,
            type: .removeSteam,
            triggerMode: .afterStepStart
        )
        return BakeStepDefinition(
            type: .bake,
            duration: 45 * 60,
            temperatureCelsius: 250,
            sortIndex: index,
            reminders: [lidRemoval]
        )
    }

    private static func cooling(_ index: inout Int) -> BakeStepDefinition {
        defer { index += 1 }
        return BakeStepDefinition(
            type: .cooling,
            duration: 60 * 60,
            isEnabled: false,
            sortIndex: index
        )
    }

    private static func coldFinalProof(_ index: inout Int) -> BakeStepDefinition {
        defer { index += 1 }
        let preheat = ReminderDefinition(
            title: String(localized: "Preheat oven"),
            offset: 45 * 60,
            sortIndex: 0,
            type: .preheatOven,
            triggerMode: .beforeStepEnd
        )
        return BakeStepDefinition(
            type: .coldFinalProof,
            duration: 12 * 3600,
            minimumDuration: 8 * 3600,
            maximumDuration: 24 * 3600,
            sortIndex: index,
            reminders: [preheat]
        )
    }

    private static func bulkCold(_ index: inout Int) -> BakeStepDefinition {
        defer { index += 1 }
        return BakeStepDefinition(
            type: .bulkCold,
            duration: 18 * 3600,
            minimumDuration: 12 * 3600,
            maximumDuration: 24 * 3600,
            sortIndex: index
        )
    }

    // MARK: - Paths

    private static func sameDaySteps() -> [BakeStepDefinition] {
        var i = 0
        return [
            sourdoughBuild(&i),
            autolyse(&i),
            mix(&i),
            kneading(&i),
            bulkRoom(&i, hours: 4, folds: true),
            benchRest(&i),
            shaping(&i),
            finalProofRoom(&i),
            bake(&i),
            cooling(&i),
        ]
    }

    private static func coldFinalProofSteps() -> [BakeStepDefinition] {
        var i = 0
        return [
            sourdoughBuild(&i),
            autolyse(&i),
            mix(&i),
            kneading(&i),
            bulkRoom(&i, hours: 4, folds: true),
            benchRest(&i),
            shaping(&i),
            coldFinalProof(&i),
            bake(&i),
            cooling(&i),
        ]
    }

    private static func coldBulkSteps() -> [BakeStepDefinition] {
        var i = 0
        return [
            sourdoughBuild(&i),
            autolyse(&i),
            mix(&i),
            kneading(&i),
            bulkRoom(&i, hours: 1, folds: false),
            bulkCold(&i),
            benchRest(&i),
            shaping(&i),
            finalProofRoom(&i),
            bake(&i),
            cooling(&i),
        ]
    }
}

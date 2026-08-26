import Foundation

/// Backward planning: computes a suggested start from a desired bake time.
enum BakeStartPlanner {

    enum TargetMode: String, Codable, CaseIterable, Identifiable {
        /// Target is the start of the single "Bake" step.
        case bakeStart
        /// Target is "bread ready to slice": bake + cooling included.
        case readyToSlice

        var id: Self { self }
    }

    enum DurationVariant {
        case minimum
        case target
        case maximum
    }

    struct Result {
        let target: Date
        let mode: TargetMode
        let recommendedStart: Date
        let earliestStart: Date
        let latestStart: Date
    }

    static func result(bakePlan: BakePlan, target: Date, mode: TargetMode) -> Result {
        let targetDuration = duration(bakePlan: bakePlan, mode: mode, variant: .target)
        let minimumDuration = duration(bakePlan: bakePlan, mode: mode, variant: .minimum)
        let maximumDuration = duration(bakePlan: bakePlan, mode: mode, variant: .maximum)

        return Result(
            target: target,
            mode: mode,
            recommendedStart: target.addingTimeInterval(-targetDuration),
            earliestStart: target.addingTimeInterval(-maximumDuration),
            latestStart: target.addingTimeInterval(-minimumDuration)
        )
    }

    static func suggestedStart(bakePlan: BakePlan, target: Date, mode: TargetMode) -> Date {
        result(bakePlan: bakePlan, target: target, mode: mode).recommendedStart
    }

    static func duration(
        bakePlan: BakePlan,
        mode: TargetMode,
        variant: DurationVariant
    ) -> TimeInterval {
        let steps: [BakeStepDefinition]
        switch mode {
        case .bakeStart:
            steps = Array(bakePlan.enabledSteps.prefix { $0.type != .bake })
        case .readyToSlice:
            steps = bakePlan.enabledSteps
        }

        return steps.reduce(0) { total, step in
            total + duration(for: step, variant: variant)
        }
    }

    private static func duration(for step: BakeStepDefinition, variant: DurationVariant) -> TimeInterval {
        let target = step.effectiveDuration
        guard step.type.isColdStep else { return target }

        switch variant {
        case .minimum:
            return max(0, min(step.minimumDuration ?? target, target))
        case .target:
            return target
        case .maximum:
            return max(target, step.maximumDuration ?? target)
        }
    }

    /// Projected timeline entries from a start date, for preview.
    static func projections(bakePlan: BakePlan, from start: Date) -> [(step: BakeStepDefinition, start: Date, end: Date)] {
        var cursor = start
        return bakePlan.enabledSteps.map { step in
            let end = cursor.addingTimeInterval(step.effectiveDuration)
            defer { cursor = end }
            return (step, cursor, end)
        }
    }
}

import Foundation

/// Calculates the only schedule change allowed when a planned overnight bake
/// starts at a different time: the duration of its cold phase.
enum OvernightPlanAdjuster {

    enum Result: Equatable {
        case notApplicable
        case adjusted(TimeInterval)
        case outsideColdWindow
    }

    static func result(
        steps: [SessionStep],
        actualStart: Date,
        target: Date,
        mode: BakeStartPlanner.TargetMode
    ) -> Result {
        let coldSteps = steps.enumerated().filter { $0.element.isColdStep }
        guard coldSteps.count == 1,
              let cold = coldSteps.first else {
            return .notApplicable
        }

        let coldIndex = cold.offset
        let targetEndIndex: Int
        switch mode {
        case .bakeStart:
            guard let bakeIndex = steps.firstIndex(where: { $0.type == .bake }), bakeIndex > coldIndex else {
                return .notApplicable
            }
            targetEndIndex = bakeIndex
        case .readyToSlice:
            targetEndIndex = steps.count
        }

        let fixedBefore = steps[..<coldIndex].reduce(0) { $0 + $1.plannedDuration }
        let fixedAfter = steps[(coldIndex + 1)..<targetEndIndex].reduce(0) { $0 + $1.plannedDuration }
        let adjustedDuration = target.timeIntervalSince(actualStart)
            - fixedBefore
            - fixedAfter

        let minimum = cold.element.minimumDuration ?? cold.element.plannedDuration
        let maximum = cold.element.maximumDuration ?? cold.element.plannedDuration
        guard adjustedDuration >= minimum, adjustedDuration <= maximum else {
            return .outsideColdWindow
        }
        return .adjusted(adjustedDuration)
    }
}

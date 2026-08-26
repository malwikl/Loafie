import Foundation

/// Validates the timing details required to start a bakePlan.
enum BakePlanStartValidator {

    struct Issue: Identifiable, Hashable {
        let id: String
        let message: String
    }

    static func issues(for bakePlan: BakePlan) -> [Issue] {
        bakePlan.enabledSteps.flatMap(issues(for:))
    }

    private static func issues(for step: BakeStepDefinition) -> [Issue] {
        var issues: [Issue] = []

        if isInvalidColdWindow(for: step) {
            issues.append(
                Issue(
                    id: "cold-window-\(step.id.uuidString)",
                    message: String(
                            localized: "\(step.displayTitle): set the fridge times in this order: minimum, usual, maximum."
                    )
                )
            )
        }

        if isInvalidFoldConfiguration(for: step) {
            issues.append(
                Issue(
                    id: "folds-\(step.id.uuidString)",
                    message: String(
                            localized: "\(step.displayTitle): move the last fold earlier so all folds happen during bulk fermentation."
                    )
                )
            )
        }

        for timer in step.sortedReminders {
            if timer.offset < 0 || timer.offset > step.effectiveDuration {
                issues.append(
                    Issue(
                        id: "timer-offset-\(timer.id.uuidString)",
                        message: String(
                            localized: "\(step.displayTitle): move this reminder so it falls within the step."
                        )
                    )
                )
            }

            if timer.type == .lowerTemperature, timer.targetTemperatureCelsius == nil {
                issues.append(
                    Issue(
                        id: "timer-temperature-\(timer.id.uuidString)",
                        message: String(
                            localized: "\(step.displayTitle): enter the oven temperature for this reminder."
                        )
                    )
                )
            }
        }

        return issues
    }

    private static func isInvalidColdWindow(for step: BakeStepDefinition) -> Bool {
        guard step.type.isColdStep else { return false }

        let target = step.effectiveDuration
        let minimum = step.minimumDuration ?? target
        let maximum = step.maximumDuration ?? target
        return minimum < 0 || minimum > target || maximum < target
    }

    private static func isInvalidFoldConfiguration(for step: BakeStepDefinition) -> Bool {
        guard let fold = step.foldReminderConfiguration, step.type.supportsFolding else { return false }

        return !FoldReminderCalculator.isValid(
            isEnabled: fold.isEnabled,
            repetitions: fold.repetitions,
            interval: fold.interval,
            firstReminderOffset: fold.firstReminderOffset,
            bulkDuration: step.effectiveDuration
        )
    }
}

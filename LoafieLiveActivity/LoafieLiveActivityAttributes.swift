import ActivityKit
import Foundation

enum LoafieLiveActivityPresentation: String, Codable, Hashable {
    case timed
    case manual
    case waitingForNextStep
}

/// Shared attributes for the baking Live Activity. This file is compiled into
/// both the main app target and the Live Activity widget extension target.
struct LoafieLiveActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var stepTitle: String
        var remainingSeconds: Double
        var stepEndDate: Date?
        var nextStepTitle: String?
        var nextReminderTitle: String?
        var nextReminderIsFold: Bool?
        var nextFoldNumber: Int?
        /// Absolute trigger date for the next reminder while the step is active.
        var nextReminderDate: Date?
        /// Frozen fallback used while the step is paused.
        var nextReminderSeconds: Double?
        var isPaused: Bool
        /// Optional for compatibility with Live Activities created before these states existed.
        private var presentationRaw: String?
        var completedStepTitle: String?
        var stepInstructions: String?
        var nextStepIsManual: Bool?

        var presentation: LoafieLiveActivityPresentation {
            LoafieLiveActivityPresentation(rawValue: presentationRaw ?? "") ?? .timed
        }

        init(
            stepTitle: String,
            remainingSeconds: Double,
            stepEndDate: Date? = nil,
            nextStepTitle: String? = nil,
            nextReminderTitle: String? = nil,
            nextReminderIsFold: Bool = false,
            nextFoldNumber: Int? = nil,
            nextReminderDate: Date? = nil,
            nextReminderSeconds: Double? = nil,
            isPaused: Bool = false,
            presentation: LoafieLiveActivityPresentation = .timed,
            completedStepTitle: String? = nil,
            stepInstructions: String? = nil,
            nextStepIsManual: Bool? = nil
        ) {
            self.stepTitle = stepTitle
            self.remainingSeconds = remainingSeconds
            self.stepEndDate = stepEndDate
            self.nextStepTitle = nextStepTitle
            self.nextReminderTitle = nextReminderTitle
            self.nextReminderIsFold = nextReminderIsFold
            self.nextFoldNumber = nextFoldNumber
            self.nextReminderDate = nextReminderDate
            self.nextReminderSeconds = nextReminderSeconds
            self.isPaused = isPaused
            self.presentationRaw = presentation.rawValue
            self.completedStepTitle = completedStepTitle
            self.stepInstructions = stepInstructions
            self.nextStepIsManual = nextStepIsManual
        }
    }

    var bakePlanName: String
    var sessionID: String
}

import Foundation
import SwiftData

@Model
final class BakeSession {
    @Attribute(.unique) var id: UUID
    var bakePlanID: UUID
    var bakePlanName: String
    var startedAt: Date
    var plannedStartAt: Date?
    var planningTargetAt: Date?
    var planningTargetModeRaw: String?
    var planningEarliestStartAt: Date?
    var planningLatestStartAt: Date?
    var statusRaw: String
    var activeStepIndex: Int?
    /// Set while paused; nil while running.
    var pausedAt: Date?
    var autoAdvanceSteps: Bool
    /// ID of a step completed before its target, awaiting the user's plan decision.
    var pendingPlanAdjustmentStepID: UUID?

    @Relationship(deleteRule: .cascade, inverse: \SessionStep.session)
    var steps: [SessionStep]

    init(
        id: UUID = UUID(),
        bakePlanID: UUID,
        bakePlanName: String,
        startedAt: Date = Date(),
        plannedStartAt: Date? = nil,
        planningTargetAt: Date? = nil,
        planningTargetModeRaw: String? = nil,
        planningEarliestStartAt: Date? = nil,
        planningLatestStartAt: Date? = nil,
        autoAdvanceSteps: Bool = true
    ) {
        self.id = id
        self.bakePlanID = bakePlanID
        self.bakePlanName = bakePlanName
        self.startedAt = startedAt
        self.plannedStartAt = plannedStartAt
        self.planningTargetAt = planningTargetAt
        self.planningTargetModeRaw = planningTargetModeRaw
        self.planningEarliestStartAt = planningEarliestStartAt
        self.planningLatestStartAt = planningLatestStartAt
        self.statusRaw = SessionStatus.active.rawValue
        self.autoAdvanceSteps = autoAdvanceSteps
        self.pendingPlanAdjustmentStepID = nil
        self.steps = []
    }

    var status: SessionStatus {
        get { SessionStatus(rawValue: statusRaw) ?? .active }
        set { statusRaw = newValue.rawValue }
    }

    var sortedSteps: [SessionStep] {
        steps.sorted { $0.sortIndex < $1.sortIndex }
    }

    var activeStep: SessionStep? {
        guard let activeStepIndex else { return nil }
        return sortedSteps[safe: activeStepIndex]
    }
}

@Model
final class SessionStep {
    @Attribute(.unique) var id: UUID
    /// Original BakeStepDefinition id for traceability.
    var definitionID: UUID
    var typeRaw: String
    var title: String
    var duration: TimeInterval?
    var minimumDuration: TimeInterval?
    var maximumDuration: TimeInterval?
    var temperatureCelsius: Int?
    var notes: String?
    var sortIndex: Int

    var statusRaw: String
    var startedAt: Date?
    var completedAt: Date?
    /// The bakePlan projection captured when the session was created or adjusted.
    var plannedStartAt: Date?
    var plannedEndAt: Date?
    var effectiveDuration: TimeInterval?
    /// Manual extension (positive) in seconds.
    var manualAdjustment: TimeInterval
    /// Cumulated pause seconds for this step.
    var accumulatedPause: TimeInterval

    // Fold configuration snapshot (flattened).
    var foldIsEnabled: Bool
    var foldTechniqueRaw: String?
    var foldCustomName: String?
    var foldRepetitions: Int
    var foldInterval: TimeInterval
    var foldFirstOffset: TimeInterval

    var session: BakeSession?

    @Relationship(deleteRule: .cascade, inverse: \SessionFoldReminder.step)
    var foldReminders: [SessionFoldReminder]

    @Relationship(deleteRule: .cascade, inverse: \SessionReminder.step)
    var reminders: [SessionReminder]?

    init(from definition: BakeStepDefinition, sortIndex: Int) {
        self.id = UUID()
        self.definitionID = definition.id
        self.typeRaw = definition.typeRaw
        self.title = definition.title
        self.duration = definition.duration
        self.minimumDuration = definition.minimumDuration
        self.maximumDuration = definition.maximumDuration
        self.temperatureCelsius = definition.temperatureCelsius
        self.notes = definition.notes
        self.sortIndex = sortIndex
        self.statusRaw = BakeStepStatus.pending.rawValue
        self.manualAdjustment = 0
        self.accumulatedPause = 0
        self.plannedStartAt = nil
        self.plannedEndAt = nil

        let fold = definition.foldReminderConfiguration
        self.foldIsEnabled = fold?.isEnabled ?? false
        self.foldTechniqueRaw = fold?.techniqueRaw
        self.foldCustomName = fold?.customTechniqueName
        self.foldRepetitions = fold?.repetitions ?? 0
        self.foldInterval = fold?.interval ?? 0
        self.foldFirstOffset = fold?.firstReminderOffset ?? 0
        self.foldReminders = []
        self.reminders = definition.sortedReminders.enumerated().map { index, sub in
            SessionReminder(from: sub, sortIndex: index)
        }
    }

    var type: BakeStepType {
        BakeStepType(rawValue: typeRaw) ?? .custom
    }

    var status: BakeStepStatus {
        get { BakeStepStatus(rawValue: statusRaw) ?? .pending }
        set { statusRaw = newValue.rawValue }
    }

    var plannedDuration: TimeInterval {
        duration ?? 0
    }

    /// A phase without a positive duration is completed deliberately by the baker.
    /// It must never be presented as a zero-length countdown.
    var isManualStep: Bool {
        plannedDuration <= 0
    }

    var isColdStep: Bool {
        type.isColdStep
    }

    var sortedFoldReminders: [SessionFoldReminder] {
        foldReminders.sorted { $0.number < $1.number }
    }

    var nextDueFoldReminder: SessionFoldReminder? {
        sortedFoldReminders.first { $0.status == .due || $0.status == .postponed }
    }

    var sortedReminders: [SessionReminder] {
        (reminders ?? []).sorted { $0.sortIndex < $1.sortIndex }
    }

    /// Reminders that are still pending or triggered but not yet completed.
    var pendingReminders: [SessionReminder] {
        sortedReminders.filter { $0.status == .pending || $0.status == .triggered }
    }
}

@Model
final class SessionFoldReminder {
    @Attribute(.unique) var id: UUID
    var number: Int
    var scheduledAt: Date
    var statusRaw: String
    var completedAt: Date?
    var postponedBy: TimeInterval
    var step: SessionStep?

    init(number: Int, scheduledAt: Date) {
        self.id = UUID()
        self.number = number
        self.scheduledAt = scheduledAt
        self.statusRaw = SessionFoldReminderStatus.pending.rawValue
        self.postponedBy = 0
    }

    var status: SessionFoldReminderStatus {
        get { SessionFoldReminderStatus(rawValue: statusRaw) ?? .pending }
        set { statusRaw = newValue.rawValue }
    }
}

@Model
final class SessionReminder {
    @Attribute(.unique) var id: UUID
    /// Original ReminderDefinition id for traceability.
    var definitionID: UUID
    var title: String
    var typeRaw: String?
    var triggerModeRaw: String?
    var targetTemperatureCelsius: Int?
    /// Seconds after the step starts, or seconds before the step ends.
    var offset: TimeInterval
    var sortIndex: Int
    var statusRaw: String
    var completedAt: Date?
    var step: SessionStep?

    init(from definition: ReminderDefinition, sortIndex: Int) {
        self.id = UUID()
        self.definitionID = definition.id
        self.title = definition.title
        self.typeRaw = definition.typeRaw
        self.triggerModeRaw = definition.triggerModeRaw
        self.targetTemperatureCelsius = definition.targetTemperatureCelsius
        self.offset = definition.offset
        self.sortIndex = sortIndex
        self.statusRaw = ReminderStatus.pending.rawValue
    }

    var status: ReminderStatus {
        get { ReminderStatus(rawValue: statusRaw) ?? .pending }
        set { statusRaw = newValue.rawValue }
    }

    var type: ReminderType {
        get { ReminderType(rawValue: typeRaw ?? "") ?? .custom }
        set { typeRaw = newValue.rawValue }
    }

    var triggerMode: ReminderTriggerMode {
        get { ReminderTriggerMode(rawValue: triggerModeRaw ?? "") ?? .afterStepStart }
        set { triggerModeRaw = newValue.rawValue }
    }

    var displayTitle: String {
        if type == .custom { return title }
        if type == .lowerTemperature, let temperature = targetTemperatureCelsius {
            return String(localized: "Lower the oven temperature to \(temperature) °C")
        }
        return type.defaultTitle
    }
}

enum ReminderStatus: String, Codable {
    case pending
    case triggered
    case completed
    case skipped
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

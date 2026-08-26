import Foundation
import SwiftData

@Model
final class BakePlan {
    @Attribute(.unique) var id: UUID
    var name: String
    var createdAt: Date
    var updatedAt: Date
    var lastUsedAt: Date?
    var timingRaw: String
    var autoAdvanceSteps: Bool

    @Relationship(deleteRule: .cascade, inverse: \BakeStepDefinition.bakePlan)
    var steps: [BakeStepDefinition]

    init(
        id: UUID = UUID(),
        name: String,
        timing: BakePlanTiming,
        createdAt: Date = Date(),
        autoAdvanceSteps: Bool = true
    ) {
        self.id = id
        self.name = name
        self.timingRaw = timing.rawValue
        self.createdAt = createdAt
        self.updatedAt = createdAt
        self.autoAdvanceSteps = autoAdvanceSteps
        self.steps = []
    }

    var timing: BakePlanTiming {
        get { BakePlanTiming(rawValue: timingRaw) ?? .sameDay }
        set { timingRaw = newValue.rawValue }
    }

    var sortedSteps: [BakeStepDefinition] {
        steps.sorted { $0.sortIndex < $1.sortIndex }
    }

    var enabledSteps: [BakeStepDefinition] {
        sortedSteps.filter(\.isEnabled)
    }

    /// Typical total duration using target values for cold steps.
    var typicalDuration: TimeInterval {
        enabledSteps.reduce(0) { $0 + $1.effectiveDuration }
    }
}

@Model
final class BakeStepDefinition {
    @Attribute(.unique) var id: UUID
    var typeRaw: String
    /// Custom title override. Empty means "use localized name of type".
    var title: String
    var duration: TimeInterval?
    var minimumDuration: TimeInterval?
    var maximumDuration: TimeInterval?
    var temperatureCelsius: Int?
    var isEnabled: Bool
    var notes: String?
    var sortIndex: Int
    var bakePlan: BakePlan?

    @Relationship(deleteRule: .cascade, inverse: \FoldReminderConfiguration.step)
    var foldReminderConfiguration: FoldReminderConfiguration?

    @Relationship(deleteRule: .cascade, inverse: \ReminderDefinition.step)
    var reminders: [ReminderDefinition]?

    init(
        id: UUID = UUID(),
        type: BakeStepType,
        title: String = "",
        duration: TimeInterval? = nil,
        minimumDuration: TimeInterval? = nil,
        maximumDuration: TimeInterval? = nil,
        temperatureCelsius: Int? = nil,
        isEnabled: Bool = true,
        notes: String? = nil,
        sortIndex: Int,
        foldReminderConfiguration: FoldReminderConfiguration? = nil,
        reminders: [ReminderDefinition]? = nil
    ) {
        self.id = id
        self.typeRaw = type.rawValue
        self.title = title
        self.duration = duration
        self.minimumDuration = minimumDuration
        self.maximumDuration = maximumDuration
        self.temperatureCelsius = temperatureCelsius
        self.isEnabled = isEnabled
        self.notes = notes
        self.sortIndex = sortIndex
        self.foldReminderConfiguration = foldReminderConfiguration
        self.reminders = reminders
    }

    var type: BakeStepType {
        get { BakeStepType(rawValue: typeRaw) ?? .custom }
        set { typeRaw = newValue.rawValue }
    }

    var sortedReminders: [ReminderDefinition] {
        (reminders ?? []).sorted { $0.sortIndex < $1.sortIndex }
    }

    /// Target duration; cold steps may define only min/target/max windows.
    var effectiveDuration: TimeInterval {
        duration ?? 0
    }
}

@Model
final class FoldReminderConfiguration {
    var isEnabled: Bool
    var techniqueRaw: String
    var customTechniqueName: String?
    /// x: number of fold rounds.
    var repetitions: Int
    /// n: interval between rounds.
    var interval: TimeInterval
    /// Offset from bulk start to first round.
    var firstReminderOffset: TimeInterval
    var step: BakeStepDefinition?

    init(
        isEnabled: Bool = true,
        technique: FoldTechnique = .stretchAndFold,
        customTechniqueName: String? = nil,
        repetitions: Int = 4,
        interval: TimeInterval = 30 * 60,
        firstReminderOffset: TimeInterval = 30 * 60
    ) {
        self.isEnabled = isEnabled
        self.techniqueRaw = technique.rawValue
        self.customTechniqueName = customTechniqueName
        self.repetitions = repetitions
        self.interval = interval
        self.firstReminderOffset = firstReminderOffset
    }

    var technique: FoldTechnique {
        get { FoldTechnique(rawValue: techniqueRaw) ?? .stretchAndFold }
        set { techniqueRaw = newValue.rawValue }
    }
}

@Model
final class ReminderDefinition {
    @Attribute(.unique) var id: UUID
    var title: String
    var typeRaw: String?
    var triggerModeRaw: String?
    var targetTemperatureCelsius: Int?
    /// Seconds after the step starts, or seconds before the step ends.
    var offset: TimeInterval
    var sortIndex: Int
    var step: BakeStepDefinition?

    init(
        id: UUID = UUID(),
        title: String,
        offset: TimeInterval,
        sortIndex: Int,
        type: ReminderType = .custom,
        triggerMode: ReminderTriggerMode = .afterStepStart,
        targetTemperatureCelsius: Int? = nil
    ) {
        self.id = id
        self.title = title
        self.typeRaw = type.rawValue
        self.triggerModeRaw = triggerMode.rawValue
        self.targetTemperatureCelsius = targetTemperatureCelsius
        self.offset = offset
        self.sortIndex = sortIndex
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

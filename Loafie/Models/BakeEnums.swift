import Foundation

enum BakePlanTiming: String, Codable, CaseIterable, Identifiable {
    case sameDay
    case coldFinalProof
    case coldBulk

    var id: String { rawValue }
}

enum BakeStartMode: String, Codable, CaseIterable, Identifiable {
    case startNow
    case planBackwards

    var id: String { rawValue }
}

enum ReminderType: String, Codable, CaseIterable, Identifiable {
    case openLid
    case removeSteam
    case lowerTemperature
    case preheatOven
    case custom

    var id: String { rawValue }

    var defaultTitle: String {
        switch self {
        case .openLid: String(localized: "Open the lid")
        case .removeSteam: String(localized: "Remove steam")
        case .lowerTemperature: String(localized: "Lower the oven temperature")
        case .preheatOven: String(localized: "Preheat the oven")
        case .custom: String(localized: "Custom")
        }
    }
}

enum ReminderTriggerMode: String, Codable, CaseIterable, Identifiable {
    case afterStepStart
    case afterPreviousReminder
    case beforeStepEnd

    var id: String { rawValue }

    var title: String {
        switch self {
        case .afterStepStart: String(localized: "After this step starts")
        case .afterPreviousReminder: String(localized: "After the previous reminder")
        case .beforeStepEnd: String(localized: "Before this step ends")
        }
    }
}

enum BakeStepType: String, Codable, CaseIterable {
    case autolyse
    case mix
    case kneading
    case bulkRoomTemperature
    case bulkCold
    case benchRest
    case shaping
    case finalProofRoomTemperature
    case coldFinalProof
    case bake
    case cooling
    case custom

    var symbolName: String {
        switch self {
        case .autolyse: "drop.fill"
        case .mix: "arrow.triangle.2.circlepath"
        case .kneading: "gearshape.2.fill"
        case .bulkRoomTemperature: "tray.fill"
        case .bulkCold: "snowflake"
        case .benchRest: "pause.circle.fill"
        case .shaping: "bread.slices.fill"
        case .finalProofRoomTemperature: "clock.fill"
        case .coldFinalProof: "refrigerator.fill"
        case .bake: "oven.fill"
        case .cooling: "wind"
        case .custom: "timer"
        }
    }

    var isColdStep: Bool {
        self == .bulkCold || self == .coldFinalProof
    }

    var supportsFolding: Bool {
        self == .bulkRoomTemperature
    }

    /// Steps that are commonly skipped and therefore disabled by default in templates.
    var isOptional: Bool {
        switch self {
        case .autolyse, .mix, .benchRest, .shaping, .cooling, .custom: true
        case .bulkRoomTemperature, .bulkCold, .finalProofRoomTemperature,
                .coldFinalProof, .bake, .kneading: false
        }
    }

    /// Whether this step type can host sub-timers (e.g. preheat, lid removal).
    var supportsReminders: Bool {
        self == .finalProofRoomTemperature || self == .coldFinalProof || self == .bake
    }
}

enum FoldTechnique: String, Codable, CaseIterable, Identifiable {
    case stretchAndFold
    case coilFold
    case custom

    var id: String { rawValue }
}

enum SessionStatus: String, Codable {
    case planned
    case active
    case paused
    case completed
    case cancelled

    var isRunning: Bool {
        self == .active || self == .paused
    }
}

enum BakeStepStatus: String, Codable {
    case pending
    case active
    case paused
    case completed
    case skipped
}

enum SessionFoldReminderStatus: String, Codable {
    case pending
    case due
    case completed
    case postponed
    case skipped
}

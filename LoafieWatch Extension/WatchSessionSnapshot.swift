import Foundation

enum WatchAction: String {
    case requestSnapshot
    case completeStep
    case togglePause
    case extendStep
    case completeFoldReminder
    case postponeFoldReminder
}

struct WatchSessionSnapshot: Codable {
    let sessionID: String?
    let bakePlanName: String?
    let status: String
    let step: WatchStepSnapshot?
}

struct WatchStepSnapshot: Codable {
    let id: String
    let title: String
    let symbolName: String
    let status: String
    let remainingSeconds: TimeInterval
    let targetDate: Date?
    let isColdStep: Bool
    let coldState: String?
    let nextStepTitle: String?
    let foldReminder: WatchFoldReminderSnapshot?
    let allowedActions: [String]
}

struct WatchFoldReminderSnapshot: Codable {
    let id: String
    let number: Int
    let total: Int
    let status: String
    let scheduledAt: Date?
}

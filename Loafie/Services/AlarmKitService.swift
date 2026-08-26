import Foundation
import SwiftUI

struct ScheduledAlarm: Identifiable, Codable, Equatable {
    let identifier: String
    let title: String
    let scheduledAt: Date

    var id: String { identifier }
}

#if canImport(AlarmKit)
import AlarmKit

@MainActor
final class AlarmKitService {
    private let backend: (any AlarmBackend)?

    init() {
        if #available(iOS 26.0, *) { backend = AlarmKitBackend() }
        else { backend = nil }
    }

    var isAuthorized: Bool { backend?.isAuthorized == true }
    var isAvailable: Bool { backend != nil }
    var scheduledCount: Int { backend?.scheduledCount ?? 0 }
    var scheduledAlarms: [ScheduledAlarm] { backend?.scheduledAlarms ?? [] }
    func requestAuthorization() async -> Bool { await backend?.requestAuthorization() ?? false }
    func cancelAll(for prefix: String) async { await backend?.cancelAll(for: prefix) }
    func schedule(identifier: String, sessionID: UUID, at date: Date, title: String) async -> Bool {
        await backend?.schedule(identifier: identifier, sessionID: sessionID, at: date, title: title) ?? false
    }
}

@MainActor
private protocol AlarmBackend {
    var isAuthorized: Bool { get }
    var scheduledCount: Int { get }
    var scheduledAlarms: [ScheduledAlarm] { get }
    func requestAuthorization() async -> Bool
    func cancelAll(for prefix: String) async
    func schedule(identifier: String, sessionID: UUID, at date: Date, title: String) async -> Bool
}

@available(iOS 26.0, *)
@MainActor
private final class AlarmKitBackend: AlarmBackend {
    private let manager = AlarmManager.shared
    private let defaults = UserDefaults.standard
    private let idsKey = "loafie.alarmKit.ids"
    private let entriesKey = "loafie.alarmKit.entries"

    var isAuthorized: Bool { manager.authorizationState == .authorized }
    var scheduledCount: Int { storedIDs().count }
    var scheduledAlarms: [ScheduledAlarm] {
        storedEntries().values.sorted { $0.scheduledAt < $1.scheduledAt }
    }

    func requestAuthorization() async -> Bool {
        do { return try await manager.requestAuthorization() == .authorized }
        catch { return false }
    }

    func cancelAll(for prefix: String) async {
        var ids = storedIDs()
        var entries = storedEntries()
        for entry in ids.filter({ $0.key.hasPrefix(prefix) }) {
            try? manager.cancel(id: entry.value)
            ids.removeValue(forKey: entry.key)
            entries.removeValue(forKey: entry.key)
        }
        save(ids: ids, entries: entries)
    }

    func schedule(identifier: String, sessionID: UUID, at date: Date, title: String) async -> Bool {
        guard date > Date(), isAuthorized else { return false }
        let id = UUID()
        let stopButton = AlarmButton(
            text: LocalizedStringResource(stringLiteral: "Stop"),
            textColor: .white,
            systemImageName: "stop.fill"
        )
        let addTimeButton = AlarmButton(
            text: LocalizedStringResource(stringLiteral: "Add 10 min"),
            textColor: .white,
            systemImageName: "plus.circle.fill"
        )
        let alert = AlarmPresentation.Alert(
            title: LocalizedStringResource(stringLiteral: title),
            stopButton: stopButton,
            secondaryButton: addTimeButton,
            secondaryButtonBehavior: .custom
        )
        let attributes = AlarmAttributes(
            presentation: AlarmPresentation(alert: alert),
            metadata: LoafieAlarmMetadata(title: title),
            tintColor: .orange
        )
        let configuration = AlarmManager.AlarmConfiguration.alarm(
            schedule: Alarm.Schedule.fixed(date),
            attributes: attributes,
            stopIntent: OpenLoafieTimerIntent(sessionID: sessionID),
            secondaryIntent: ExtendCurrentStepIntent(sessionID: sessionID)
        )
        do {
            _ = try await manager.schedule(id: id, configuration: configuration)
            var ids = storedIDs()
            ids[identifier] = id
            var entries = storedEntries()
            entries[identifier] = ScheduledAlarm(
                identifier: identifier,
                title: title,
                scheduledAt: date
            )
            save(ids: ids, entries: entries)
            return true
        } catch {
            #if DEBUG
            print("Failed to schedule AlarmKit alarm: \(error)")
            #endif
            return false
        }
    }

    private func storedIDs() -> [String: UUID] {
        guard let values = defaults.array(forKey: idsKey) as? [[String]] else { return [:] }
        return Dictionary(uniqueKeysWithValues: values.compactMap { value in
            guard value.count == 2, let id = UUID(uuidString: value[1]) else { return nil }
            return (value[0], id)
        })
    }

    private func storedEntries() -> [String: ScheduledAlarm] {
        guard let data = defaults.data(forKey: entriesKey),
              let entries = try? JSONDecoder().decode([ScheduledAlarm].self, from: data) else {
            return [:]
        }
        return Dictionary(uniqueKeysWithValues: entries.map { ($0.identifier, $0) })
    }

    private func save(ids: [String: UUID], entries: [String: ScheduledAlarm]) {
        defaults.set(ids.map { [$0.key, $0.value.uuidString] }, forKey: idsKey)
        let values = entries.values.sorted { $0.scheduledAt < $1.scheduledAt }
        defaults.set(try? JSONEncoder().encode(values), forKey: entriesKey)
    }
}

private struct LoafieAlarmMetadata: AlarmMetadata {
    let title: String
}
#else

@MainActor
final class AlarmKitService {
    var isAuthorized: Bool { false }
    var isAvailable: Bool { false }
    var scheduledCount: Int { 0 }
    var scheduledAlarms: [ScheduledAlarm] { [] }
    func requestAuthorization() async -> Bool { false }
    func cancelAll(for prefix: String) async {}
    func schedule(identifier: String, sessionID: UUID, at date: Date, title: String) async -> Bool { false }
}

#endif

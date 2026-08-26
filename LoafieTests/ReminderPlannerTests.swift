import Foundation
import Testing
@testable import Loafie

@MainActor
struct ReminderPlannerTests {

    @Test func activeStepProducesEndAndReminderNotifications() {
        let start = Date(timeIntervalSince1970: 10_000)
        let definition = BakeStepDefinition(
            type: .finalProofRoomTemperature,
            duration: 2 * 3600,
            sortIndex: 0,
            reminders: [
                ReminderDefinition(title: "Preheat", offset: 30 * 60, sortIndex: 0),
            ]
        )
        let session = BakeSession(bakePlanID: UUID(), bakePlanName: "Test", startedAt: start)
        let step = SessionStep(from: definition, sortIndex: 0)
        step.session = session
        step.status = .active
        step.startedAt = start
        session.steps = [step]
        session.activeStepIndex = 0

        let events = ReminderPlanner.events(for: session, now: start)

        #expect(events.map(\.identifier).contains { $0.hasSuffix("/end") })
        #expect(events.map(\.identifier).contains { $0.contains("/subtimer/") })
    }

    @Test func sleepWindowSupportsMinutePrecisionAndOvernightRanges() {
        let suiteName = "ReminderPlannerTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let settings = SettingsStore(defaults: defaults)
        settings.sleepModeEnabled = true
        settings.sleepModeStartMinute = 22 * 60 + 30
        settings.sleepModeEndMinute = 7 * 60 + 15

        #expect(settings.isInSleepWindow(makeDate(hour: 22, minute: 30)))
        #expect(settings.isInSleepWindow(makeDate(hour: 6, minute: 59)))
        #expect(!settings.isInSleepWindow(makeDate(hour: 7, minute: 15)))
        #expect(!settings.isInSleepWindow(makeDate(hour: 18, minute: 0)))
    }

    private func makeDate(hour: Int, minute: Int) -> Date {
        var components = DateComponents()
        components.year = 2026
        components.month = 8
        components.day = 25
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components) ?? Date()
    }
}

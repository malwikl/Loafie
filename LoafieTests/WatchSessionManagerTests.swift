import Testing
import SwiftData
import Foundation
@testable import Loafie

@MainActor
struct WatchSessionManagerTests {

    private static func makeContainer() throws -> ModelContainer {
        let schema = Schema([
            BakePlan.self,
            BakeStepDefinition.self,
            FoldReminderConfiguration.self,
            ReminderDefinition.self,
            BakeSession.self,
            SessionStep.self,
            SessionFoldReminder.self,
            SessionReminder.self,
        ])
        return try ModelContainer(
            for: schema,
            configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)]
        )
    }

    private static func makeBakePlan(in context: ModelContext) -> BakePlan {
        let bakePlan = BakePlan(name: "WatchTest", timing: .sameDay)
        bakePlan.steps = [
            BakeStepDefinition(type: .autolyse, duration: 30 * 60, sortIndex: 0),
            BakeStepDefinition(type: .bulkRoomTemperature, duration: 4 * 3600, sortIndex: 1),
            BakeStepDefinition(type: .bake, duration: 45 * 60, sortIndex: 2),
        ]
        context.insert(bakePlan)
        return bakePlan
    }

    private static func makeFoldBakePlan(in context: ModelContext) -> BakePlan {
        let bakePlan = BakePlan(name: "WatchFoldTest", timing: .sameDay)
        let fold = FoldReminderConfiguration(
            isEnabled: true,
            technique: .stretchAndFold,
            repetitions: 4,
            interval: 30 * 60,
            firstReminderOffset: 30 * 60
        )
        bakePlan.steps = [
            BakeStepDefinition(type: .autolyse, duration: 30 * 60, sortIndex: 0),
            BakeStepDefinition(
                type: .bulkRoomTemperature,
                duration: 4 * 3600,
                sortIndex: 1,
                foldReminderConfiguration: fold
            ),
            BakeStepDefinition(type: .bake, duration: 45 * 60, sortIndex: 2),
        ]
        context.insert(bakePlan)
        return bakePlan
    }

    @Test func snapshotIncludesActivePhase() async throws {
        let container = try Self.makeContainer()
        let context = ModelContext(container)
        let bakePlan = Self.makeBakePlan(in: context)
        let store = SessionStore(modelContext: context) { Date(timeIntervalSince1970: 0) }
        let session = try store.start(bakePlan: bakePlan)
        let manager = WatchSessionManager(sessionStore: store)

        let snapshot = manager.makeSnapshot()

        #expect(snapshot.sessionID == session.id.uuidString)
        #expect(snapshot.bakePlanName == "WatchTest")
        #expect(snapshot.status == SessionStatus.active.rawValue)
        #expect(snapshot.step?.title == session.activeStep?.displayTitle)
        #expect(snapshot.step?.allowedActions.contains(WatchAction.completeStep.rawValue) == true)
    }

    @Test func completeStepActionAdvances() async throws {
        let container = try Self.makeContainer()
        let context = ModelContext(container)
        let bakePlan = Self.makeBakePlan(in: context)
        let store = SessionStore(modelContext: context) { Date(timeIntervalSince1970: 0) }
        let manager = WatchSessionManager(sessionStore: store)
        _ = try store.start(bakePlan: bakePlan)

        manager.handleAction(.completeStep, payload: [:])

        #expect(store.runningSession()?.activeStep == nil)
        #expect(store.runningSession()?.sortedSteps.first { $0.status == .pending }?.type == .bulkRoomTemperature)
    }

    @Test func togglePauseAction() async throws {
        let container = try Self.makeContainer()
        let context = ModelContext(container)
        let bakePlan = Self.makeBakePlan(in: context)
        let store = SessionStore(modelContext: context) { Date(timeIntervalSince1970: 0) }
        let manager = WatchSessionManager(sessionStore: store)
        _ = try store.start(bakePlan: bakePlan)

        manager.handleAction(.togglePause, payload: [:])
        #expect(store.runningSession()?.status == .paused)

        manager.handleAction(.togglePause, payload: [:])
        #expect(store.runningSession()?.status == .active)
    }

    @Test func extendStepAction() async throws {
        let container = try Self.makeContainer()
        let context = ModelContext(container)
        let bakePlan = Self.makeBakePlan(in: context)
        let store = SessionStore(modelContext: context) { Date(timeIntervalSince1970: 0) }
        let manager = WatchSessionManager(sessionStore: store)
        _ = try store.start(bakePlan: bakePlan)

        manager.handleAction(.extendStep, payload: ["seconds": TimeInterval(300)])

        #expect(store.runningSession()?.activeStep?.manualAdjustment == 300)
    }

    @Test func completeFoldReminderAction() async throws {
        let container = try Self.makeContainer()
        let context = ModelContext(container)
        let bakePlan = Self.makeFoldBakePlan(in: context)
        let store = SessionStore(modelContext: context) { Date(timeIntervalSince1970: 0) }
        let manager = WatchSessionManager(sessionStore: store)
        _ = try store.start(bakePlan: bakePlan)
        store.completeActiveStep(store.runningSession()!)
        store.startNextStep(store.runningSession()!)
        let round = try #require(store.runningSession()?.activeStep?.sortedFoldReminders.first)

        manager.handleAction(.completeFoldReminder, payload: ["foldReminderID": round.id.uuidString])

        #expect(round.status == .completed)
    }
}

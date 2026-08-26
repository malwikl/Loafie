import Testing
import SwiftData
import Foundation
@testable import Loafie

@MainActor
struct SessionStoreTests {

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
        let bakePlan = BakePlan(name: "Test", timing: BakePlanTiming.sameDay)
        let steps: [BakeStepDefinition] = [
            BakeStepDefinition(type: BakeStepType.autolyse, duration: 30 * 60, sortIndex: 0),
            BakeStepDefinition(type: BakeStepType.bulkRoomTemperature, duration: 4 * 3600, sortIndex: 1),
            BakeStepDefinition(type: BakeStepType.bake, duration: 45 * 60, sortIndex: 2),
        ]
        bakePlan.steps = steps
        context.insert(bakePlan)
        return bakePlan
    }

    @Test func startCreatesActiveSession() async throws {
        let container = try Self.makeContainer()
        let context = ModelContext(container)
        let bakePlan = Self.makeBakePlan(in: context)
        let store = SessionStore(modelContext: context) { Date(timeIntervalSince1970: 0) }

        let session = try store.start(bakePlan: bakePlan)

        #expect(session.status == SessionStatus.active)
        #expect(session.activeStep?.type == BakeStepType.autolyse)
        #expect(store.runningSession()?.id == session.id)
        #expect(session.sortedSteps.first?.plannedStartAt == Date(timeIntervalSince1970: 0))
    }

    @Test func reminderCanBeCheckedAndUnchecked() async throws {
        let container = try Self.makeContainer()
        let context = ModelContext(container)
        let bakePlan = Self.makeBakePlan(in: context)
        let timer = ReminderDefinition(title: "Fold", offset: 60, sortIndex: 0)
        bakePlan.steps[0].reminders = [timer]
        let store = SessionStore(modelContext: context) { Date(timeIntervalSince1970: 0) }
        let session = try store.start(bakePlan: bakePlan)
        let reminder = try #require(session.activeStep?.sortedReminders.first)

        store.toggleReminder(reminder)
        #expect(reminder.status == .completed)
        #expect(reminder.completedAt != nil)

        store.toggleReminder(reminder)
        #expect(reminder.status == .pending)
        #expect(reminder.completedAt == nil)
    }

    @Test func extendCurrentStepOnlyUpdatesMatchingRunningSession() async throws {
        let container = try Self.makeContainer()
        let context = ModelContext(container)
        let bakePlan = Self.makeBakePlan(in: context)
        let store = SessionStore(modelContext: context) { Date(timeIntervalSince1970: 0) }
        let session = try store.start(bakePlan: bakePlan)
        let step = try #require(session.activeStep)

        #expect(store.extendCurrentStep(for: session.id, by: 10 * 60))
        #expect(step.manualAdjustment == 10 * 60)
        #expect(!store.extendCurrentStep(for: UUID(), by: 10 * 60))
        #expect(!store.extendCurrentStep(for: session.id, by: 0))
    }

    @Test func planCreatesWaitingSessionAndStartsIt() async throws {
        let start = Date(timeIntervalSince1970: 1000)
        let planned = start.addingTimeInterval(3600)
        let container = try Self.makeContainer()
        let context = ModelContext(container)
        let bakePlan = Self.makeBakePlan(in: context)
        let store = SessionStore(modelContext: context) { start }

        let session = try store.plan(bakePlan: bakePlan, startAt: planned)

        #expect(session.status == .planned)
        #expect(session.plannedStartAt == planned)
        #expect(session.activeStep == nil)

        store.startPlannedSession(session)
        #expect(session.status == .active)
        #expect(session.activeStep?.type == .autolyse)
        #expect(session.plannedStartAt == nil)
    }

    @Test func backwardsPlanStoresTargetAndWindow() async throws {
        let now = Date(timeIntervalSince1970: 1000)
        let container = try Self.makeContainer()
        let context = ModelContext(container)
        let bakePlan = Self.makeBakePlan(in: context)
        let store = SessionStore(modelContext: context) { now }
        let target = now.addingTimeInterval(10 * 3600)

        let session = try store.plan(bakePlan: bakePlan, target: target, mode: .bakeStart)

        #expect(session.status == .planned)
        #expect(session.planningTargetAt == target)
        #expect(session.planningTargetModeRaw == BakeStartPlanner.TargetMode.bakeStart.rawValue)
        #expect(session.planningEarliestStartAt != nil)
        #expect(session.planningLatestStartAt != nil)
    }

    @Test func secondStartFailsWhenSessionRunning() async throws {
        let container = try Self.makeContainer()
        let context = ModelContext(container)
        let bakePlan = Self.makeBakePlan(in: context)
        let store = SessionStore(modelContext: context) { Date(timeIntervalSince1970: 0) }
        _ = try store.start(bakePlan: bakePlan)

        #expect(throws: SessionStore.SessionError.sessionAlreadyRunning) {
            try store.start(bakePlan: bakePlan)
        }
    }

    @Test func pauseFreezesRemainingTime() async throws {
        let start = Date(timeIntervalSince1970: 0)
        var current = start
        let container = try Self.makeContainer()
        let context = ModelContext(container)
        let bakePlan = Self.makeBakePlan(in: context)
        let store = SessionStore(modelContext: context) { current }
        let session = try store.start(bakePlan: bakePlan)

        current = start.addingTimeInterval(1)
        store.pause(session)
        #expect(session.status == SessionStatus.paused)
        #expect(session.activeStep?.status == BakeStepStatus.paused)

        current = start.addingTimeInterval(2)
        store.resume(session)
        #expect(session.status == SessionStatus.active)

        current = start.addingTimeInterval(120)
        let remaining = TimerMath.remaining(
            startedAt: session.activeStep?.startedAt ?? start,
            plannedDuration: session.activeStep?.plannedDuration ?? 0,
            accumulatedPause: session.activeStep?.accumulatedPause ?? 0,
            pausedAt: session.pausedAt,
            now: current
        )
        // pause 1 sec, elapsed 119 sec, remaining 1681 sec
        #expect(abs(remaining - (30 * 60 - 119)) < 2)
    }

    @Test func completeLastStepFinishesSession() async throws {
        let start = Date(timeIntervalSince1970: 0)
        let container = try Self.makeContainer()
        let context = ModelContext(container)
        let bakePlan = Self.makeBakePlan(in: context)
        let store = SessionStore(modelContext: context) { start }
        let session = try store.start(bakePlan: bakePlan)

        store.completeActiveStep(session) // autolyse done
        store.startNextStep(session)      // bulk
        store.completeActiveStep(session) // bulk done
        store.startNextStep(session)      // bake
        #expect(session.activeStep?.type == BakeStepType.bake)

        store.completeActiveStep(session)
        #expect(session.status == SessionStatus.completed)
        #expect(session.activeStepIndex == nil)
    }

    @Test func foldRemindersGeneratedForBulkPhase() async throws {
        let start = Date(timeIntervalSince1970: 0)
        let container = try Self.makeContainer()
        let context = ModelContext(container)
        let bakePlan = Self.foldTestBakePlan(in: context)
        let store = SessionStore(modelContext: context) { start }

        let session = try store.start(bakePlan: bakePlan)
        store.completeActiveStep(session) // autolyse done
        store.startNextStep(session)      // bulk
        let bulk = session.activeStep
        #expect(bulk?.type == BakeStepType.bulkRoomTemperature)
        #expect(bulk?.foldReminders.count == 4)
        #expect(bulk?.sortedFoldReminders.first?.scheduledAt == start.addingTimeInterval(30 * 60))
    }

    @Test func completeFoldReminderMarksItDone() async throws {
        let start = Date(timeIntervalSince1970: 0)
        let container = try Self.makeContainer()
        let context = ModelContext(container)
        let bakePlan = Self.foldTestBakePlan(in: context)
        let store = SessionStore(modelContext: context) { start }

        let session = try store.start(bakePlan: bakePlan)
        store.completeActiveStep(session)
        store.startNextStep(session)
        let round = try #require(session.activeStep?.sortedFoldReminders.first)
        store.completeFoldReminder(round)
        #expect(round.status == SessionFoldReminderStatus.completed)
    }

    @Test func unfinishedFoldRemindersRemainVisibleAfterStepCompletion() async throws {
        let start = Date(timeIntervalSince1970: 0)
        let container = try Self.makeContainer()
        let context = ModelContext(container)
        let bakePlan = Self.foldTestBakePlan(in: context)
        let store = SessionStore(modelContext: context) { start }

        let session = try store.start(bakePlan: bakePlan)
        store.completeActiveStep(session)
        store.startNextStep(session)
        let bulk = try #require(session.activeStep)
        let firstRound = try #require(bulk.sortedFoldReminders.first)
        store.completeFoldReminder(firstRound)

        store.completeActiveStep(session)

        #expect(firstRound.status == .completed)
        #expect(bulk.sortedFoldReminders.dropFirst().allSatisfy { $0.status != .completed })
    }

    private static func foldTestBakePlan(in context: ModelContext) -> BakePlan {
        let bakePlan = BakePlan(name: "FoldTest", timing: BakePlanTiming.sameDay)
        let fold = FoldReminderConfiguration(
            isEnabled: true,
            technique: FoldTechnique.stretchAndFold,
            repetitions: 4,
            interval: 30 * 60,
            firstReminderOffset: 30 * 60
        )
        let steps: [BakeStepDefinition] = [
            BakeStepDefinition(type: BakeStepType.autolyse, duration: 30 * 60, sortIndex: 0),
            BakeStepDefinition(
                type: BakeStepType.bulkRoomTemperature,
                duration: 4 * 3600,
                sortIndex: 1,
                foldReminderConfiguration: fold
            ),
            BakeStepDefinition(type: BakeStepType.bake, duration: 45 * 60, sortIndex: 2),
        ]
        bakePlan.steps = steps
        context.insert(bakePlan)
        return bakePlan
    }
}

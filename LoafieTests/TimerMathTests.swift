import Testing
import Foundation
@testable import Loafie

@MainActor
struct TimerMathTests {

    @Test func reminderAfterStepStart() {
        let start = Date(timeIntervalSince1970: 0)
        let result = TimerMath.reminderDate(
            stepStart: start,
            stepDuration: 3600,
            offset: 600,
            mode: .afterStepStart
        )
        #expect(result == start.addingTimeInterval(600))
    }

    @Test func reminderBeforeStepEnd() {
        let start = Date(timeIntervalSince1970: 0)
        let result = TimerMath.reminderDate(
            stepStart: start,
            stepDuration: 3600,
            offset: 600,
            mode: .beforeStepEnd
        )
        #expect(result == start.addingTimeInterval(3000))
    }

    @Test func reminderCanStartAfterPreviousReminder() {
        let start = Date(timeIntervalSince1970: 0)
        let first = TimerMath.reminderDate(
            stepStart: start,
            stepDuration: 3600,
            offset: 600,
            mode: .afterStepStart
        )
        let second = TimerMath.reminderDate(
            stepStart: start,
            stepDuration: 3600,
            offset: 300,
            mode: .afterPreviousReminder,
            previousDate: first
        )

        #expect(first == start.addingTimeInterval(600))
        #expect(second == start.addingTimeInterval(900))
    }

    @Test func remainingTimeDecreases() {
        let start = Date(timeIntervalSince1970: 0)
        let remaining = TimerMath.remaining(
            startedAt: start,
            plannedDuration: 600,
            now: start.addingTimeInterval(100)
        )
        #expect(remaining == 500)
    }

    @Test func pausedTimeDoesNotCount() {
        let start = Date(timeIntervalSince1970: 0)
        let remaining = TimerMath.remaining(
            startedAt: start,
            plannedDuration: 600,
            accumulatedPause: 50,
            pausedAt: Date(timeIntervalSince1970: 120),
            now: Date(timeIntervalSince1970: 200)
        )
        // elapsed = 120 - 50 = 70; remaining = 600 - 70 = 530
        #expect(remaining == 530)
    }

    @Test func overdueReturnsNegative() {
        let start = Date(timeIntervalSince1970: 0)
        let remaining = TimerMath.remaining(
            startedAt: start,
            plannedDuration: 600,
            now: start.addingTimeInterval(700)
        )
        #expect(remaining == -100)
    }

    @Test func manualExtensionAddsTime() {
        let start = Date(timeIntervalSince1970: 0)
        let remaining = TimerMath.remaining(
            startedAt: start,
            plannedDuration: 600,
            manualAdjustment: 120,
            now: start.addingTimeInterval(600)
        )
        #expect(remaining == 120)
    }

    @Test func coldStepStateTransitions() {
        let start = Date(timeIntervalSince1970: 0)
        let target: TimeInterval = 12 * 3600
        let min: TimeInterval = 8 * 3600
        let max: TimeInterval = 24 * 3600

        #expect(
            ColdStepState.classify(
                startedAt: start, target: target, minimum: min, maximum: max,
                now: start.addingTimeInterval(4 * 3600)
            ) == .running
        )
        #expect(
            ColdStepState.classify(
                startedAt: start, target: target, minimum: min, maximum: max,
                now: start.addingTimeInterval(10 * 3600)
            ) == .earliestReady
        )
        #expect(
            ColdStepState.classify(
                startedAt: start, target: target, minimum: min, maximum: max,
                now: start.addingTimeInterval(15 * 3600)
            ) == .bakeReady
        )
        #expect(
            ColdStepState.classify(
                startedAt: start, target: target, minimum: min, maximum: max,
                now: start.addingTimeInterval(25 * 3600)
        ) == .exceededMaximum
        )
    }

    @Test func coldWindowReturnsAbsoluteBoundaries() {
        let start = Date(timeIntervalSince1970: 1_000)
        let window = TimerMath.coldWindow(
            startedAt: start,
            target: 12 * 3600,
            minimum: 8 * 3600,
            maximum: 24 * 3600
        )

        #expect(window.minimumEnd == start.addingTimeInterval(8 * 3600))
        #expect(window.recommendedEnd == start.addingTimeInterval(12 * 3600))
        #expect(window.maximumEnd == start.addingTimeInterval(24 * 3600))
    }
}

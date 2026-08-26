import Testing
@testable import Loafie

struct FoldReminderCalculatorTests {

    @Test func validFoldReminderSchedule() {
        let offsets = FoldReminderCalculator.roundOffsets(
            repetitions: 4,
            interval: 30 * 60,
            firstReminderOffset: 30 * 60
        )
        #expect(offsets == [1800, 3600, 5400, 7200])
        #expect(
            FoldReminderCalculator.isValid(
                isEnabled: true,
                repetitions: 4,
                interval: 30 * 60,
                firstReminderOffset: 30 * 60,
                bulkDuration: 4 * 3600
            )
        )
    }

    @Test func zeroRoundsIsAlwaysValid() {
        #expect(
            FoldReminderCalculator.isValid(
                isEnabled: true,
                repetitions: 0,
                interval: 30 * 60,
                firstReminderOffset: 30 * 60,
                bulkDuration: 1
            )
        )
    }

    @Test func disabledFoldsAreAlwaysValid() {
        #expect(
            FoldReminderCalculator.isValid(
                isEnabled: false,
                repetitions: 20,
                interval: 5 * 60,
                firstReminderOffset: 0,
                bulkDuration: 1
            )
        )
    }

    @Test func lastRoundExactlyAtEndIsValid() {
        #expect(
            FoldReminderCalculator.isValid(
                isEnabled: true,
                repetitions: 3,
                interval: 60 * 60,
                firstReminderOffset: 2 * 3600,
                bulkDuration: 4 * 3600
            )
        )
    }

    @Test func lastRoundPastEndIsInvalid() {
        #expect(
            !FoldReminderCalculator.isValid(
                isEnabled: true,
                repetitions: 4,
                interval: 30 * 60,
                firstReminderOffset: 30 * 60,
                bulkDuration: 90 * 60
            )
        )
    }
}

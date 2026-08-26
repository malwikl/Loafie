import Foundation

/// Projects start/end dates of all steps of a session for the timeline view.
struct StepProjection: Equatable {
    let stepID: UUID
    let plannedStart: Date
    let plannedEnd: Date
    let actualStart: Date?
    let actualEnd: Date?

    var projectedStart: Date { plannedStart }
    var projectedEnd: Date { plannedEnd }
}

enum TimelineCalculator {

    /// Walks steps in order. Completed steps use actual timestamps; the active
    /// step projects from its stored start + adjustments; pending steps chain
    /// sequentially from the previous projected end.
    static func projections(for session: BakeSession, now: Date = Date()) -> [StepProjection] {
        var cursor = session.startedAt
        var result: [StepProjection] = []

        for step in session.sortedSteps {
            let plannedStart = step.plannedStartAt ?? cursor
            let plannedEnd = step.plannedEndAt ?? plannedStart.addingTimeInterval(step.plannedDuration)
            result.append(
                StepProjection(
                    stepID: step.id,
                    plannedStart: plannedStart,
                    plannedEnd: plannedEnd,
                    actualStart: step.startedAt,
                    actualEnd: step.completedAt
                )
            )
            cursor = plannedEnd
        }
        return result
    }
}

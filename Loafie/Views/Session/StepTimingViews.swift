import SwiftUI

struct TimerReadoutView: View {
    let step: SessionStep
    let session: BakeSession

    var body: some View {
        TimelineView(.periodic(from: Date(), by: 1)) { _ in
            VStack(spacing: 4) {
                if step.plannedDuration > 0 {
                    Text(DurationFormatter.countdown(from: remaining))
                        .font(.system(size: 54, weight: .bold, design: .monospaced))
                        .monospacedDigit()
                }
                if step.plannedDuration > 0, remaining < 0 {
                    Text("Overdue by \(DurationFormatter.string(from: abs(remaining)))")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.timerPaused)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var remaining: TimeInterval {
        TimerMath.remaining(
            startedAt: step.startedAt ?? Date(),
            plannedDuration: step.plannedDuration,
            manualAdjustment: step.manualAdjustment,
            accumulatedPause: step.accumulatedPause,
            pausedAt: session.pausedAt,
            now: Date()
        )
    }
}

struct ManualStepGuidanceView: View {
    let step: SessionStep

    var body: some View {
        if step.isManualStep, let notes = step.notes, !notes.isEmpty {
            Text(notes)
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(Color.crustGold.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: LoafieDesign.cardRadius))
        }
    }
}

struct StepNotesButton: View {
    let notes: String?
    let stepTitle: String
    @State private var isShowingNotes = false

    private var hasNotes: Bool {
        guard let notes else { return false }
        return !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        if hasNotes {
            Button {
                isShowingNotes = true
            } label: {
                Image(systemName: "info.circle")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Information for \(stepTitle)")
            .popover(isPresented: $isShowingNotes) {
                Text(notes ?? "")
                    .font(.body)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .frame(minWidth: 220, maxWidth: 320, alignment: .leading)
                    .padding()
                    .presentationCompactAdaptation(.popover)
            }
        }
    }
}

struct ColdStepStatusView: View {
    let step: SessionStep
    let session: BakeSession

    var body: some View {
        if step.isColdStep {
            let state = ColdStepState.classify(
                startedAt: step.startedAt ?? Date(),
                target: step.plannedDuration,
                minimum: step.minimumDuration,
                maximum: step.maximumDuration,
                manualAdjustment: step.manualAdjustment,
                accumulatedPause: step.accumulatedPause,
                pausedAt: session.pausedAt,
                now: Date()
            )
            let window = TimerMath.coldWindow(
                startedAt: step.startedAt ?? Date(),
                target: step.plannedDuration,
                minimum: step.minimumDuration,
                maximum: step.maximumDuration,
                manualAdjustment: step.manualAdjustment,
                accumulatedPause: step.accumulatedPause
            )

            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: statusSymbol(for: state))
                    Text(statusText(for: state))
                        .fontWeight(.semibold)
                }
                .foregroundStyle(statusColor(for: state))
                Text("Earliest: \(window.minimumEnd, format: .dateTime.hour().minute()) · usual: \(window.recommendedEnd, format: .dateTime.hour().minute()) · latest: \(window.maximumEnd, format: .dateTime.hour().minute())")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.doughBeige)
            .clipShape(RoundedRectangle(cornerRadius: LoafieDesign.cardRadius))
        }
    }

    private func statusSymbol(for state: ColdStepState) -> String {
        switch state {
        case .running: "refrigerator"
        case .earliestReady: "checkmark.circle"
        case .bakeReady: "checkmark.circle.fill"
        case .exceededMaximum: "exclamationmark.triangle.fill"
        }
    }

    private func statusText(for state: ColdStepState) -> String {
        switch state {
        case .running: String(localized: "Still in the fridge")
        case .earliestReady: String(localized: "Earliest recommended time")
        case .bakeReady: String(localized: "Ready to continue")
        case .exceededMaximum: String(localized: "Latest recommended time passed")
        }
    }

    private func statusColor(for state: ColdStepState) -> Color {
        switch state {
        case .running: .accentColor
        case .earliestReady: .blue
        case .bakeReady: .green
        case .exceededMaximum: .red
        }
    }
}

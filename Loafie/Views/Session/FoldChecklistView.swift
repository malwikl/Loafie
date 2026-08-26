import SwiftUI

/// A checklist for every fold round belonging to the active bulk step.
struct FoldChecklistView: View {
    @Environment(SessionStore.self) private var sessionStore
    let step: SessionStep

    private var rounds: [SessionFoldReminder] {
        step.sortedFoldReminders
    }

    var body: some View {
        guard step.foldIsEnabled, step.foldRepetitions > 0, !rounds.isEmpty else {
            return AnyView(EmptyView())
        }

        let completed = rounds.filter { $0.status == .completed }.count
        return AnyView(
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Folds")
                        .font(.headline)
                    Spacer()
                    Text("\(completed) / \(rounds.count) done")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                ForEach(rounds) { round in
                    FoldChecklistRow(
                        round: round
                    ) {
                        Haptics.impact(.medium)
                        sessionStore.completeFoldReminder(round)
                    } postpone: {
                        Haptics.impact(.light)
                        sessionStore.postponeFoldReminder(round)
                    }
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.doughBeige.opacity(0.72))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        )
    }

}

private struct FoldChecklistRow: View {
    let round: SessionFoldReminder
    let complete: () -> Void
    let postpone: () -> Void

    private var isDue: Bool {
        (round.status == .due || round.status == .postponed) && round.scheduledAt <= Date()
    }

    var body: some View {
        HStack(spacing: 10) {
            Button(action: complete) {
                Image(systemName: round.status == .completed ? "checkmark.square.fill" : "square")
                    .foregroundStyle(round.status == .completed ? Color.green : Color.crustGold)
                    .font(.title3)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .disabled(round.status == .completed)
            .accessibilityLabel("Fold \(round.number)")
            .accessibilityValue(statusText)

            Text("Fold \(round.number)")
                .font(.body.weight(.medium))

            Spacer()

            Text(statusText)
                .font(.caption)
                .foregroundStyle(isDue ? Color.orange : .secondary)

            if isDue && round.status != .completed {
                Button(action: postpone) {
                    Image(systemName: "clock.arrow.circlepath")
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Postpone 10 minutes")
                .help("Postpone 10 minutes")
                .buttonStyle(.borderless)
            }

        }
        .frame(minHeight: 44)
    }

    private var statusText: String {
        if round.status == .completed {
            return String(localized: "Done")
        }
        if isDue {
            return String(localized: "Due")
        }
        return round.scheduledAt.formatted(date: .omitted, time: .shortened)
    }
}

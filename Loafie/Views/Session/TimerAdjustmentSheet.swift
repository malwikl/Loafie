import SwiftUI

/// A short, self-contained editor for the absolute end time of the active
/// timer. It previews the resulting plan before committing a mutation.
struct TimerAdjustmentSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SessionStore.self) private var sessionStore

    let session: BakeSession
    let step: SessionStep
    @State private var endingAt: Date

    init(session: BakeSession, step: SessionStep) {
        self.session = session
        self.step = step

        let now = Date()
        let currentEnd = step.startedAt.map {
            TimerMath.plannedEnd(
                startedAt: $0,
                plannedDuration: step.plannedDuration,
                manualAdjustment: step.manualAdjustment,
                accumulatedPause: step.accumulatedPause
            )
        } ?? now
        // An expired timer restarts with a full original duration from now,
        // without replacing its historical start time.
        let initialEnd = currentEnd <= now
            ? now.addingTimeInterval(step.plannedDuration)
            : currentEnd
        _endingAt = State(initialValue: initialEnd)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("New end time") {
                    DatePicker(
                        "End time",
                        selection: $endingAt,
                        in: Date()...,
                        displayedComponents: [.hourAndMinute]
                    )
                    LabeledContent("Remaining time") {
                        Text(DurationFormatter.string(from: remainingDuration))
                            .monospacedDigit()
                    }
                }

                Section("Adjust minutes") {
                    quickActionButtons
                }

                Section("Impact") {
                    if let next = nextPendingStep {
                        LabeledContent("Next phase") {
                            Text(next.displayTitle)
                        }
                        LabeledContent("Starts") {
                            Text(endingAt, format: .dateTime.hour().minute())
                                .monospacedDigit()
                        }
                    }

                    LabeledContent("Bread ready") {
                        Text(projectedFinish, format: .dateTime.hour().minute())
                            .monospacedDigit()
                    }

                    if !openEvents.isEmpty {
                        DisclosureGroup("Open reminders") {
                            ForEach(openEvents) { event in
                                LabeledContent(event.title) {
                                    Text(event.date, format: .dateTime.hour().minute())
                                        .monospacedDigit()
                                }
                            }
                        }
                    }
                }

                if let coldWarning {
                    Section {
                        Label(coldWarning, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                    }
                }
            }
            .navigationTitle("Adjust timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Update plan") {
                        guard sessionStore.adjustActiveStep(session, endingAt: endingAt) else { return }
                        Haptics.impact(.medium)
                        dismiss()
                    }
                    .disabled(!isValidEndTime || session.status != .active)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var isValidEndTime: Bool {
        endingAt > Date()
    }

    private var remainingDuration: TimeInterval {
        max(0, endingAt.timeIntervalSince(Date()))
    }

    private var draftAdjustment: TimeInterval {
        guard let startedAt = step.startedAt else { return step.manualAdjustment }
        return TimerMath.manualAdjustment(
            endingAt: endingAt,
            startedAt: startedAt,
            plannedDuration: step.plannedDuration,
            accumulatedPause: step.accumulatedPause
        )
    }

    private var nextPendingStep: SessionStep? {
        guard let activeIndex = session.sortedSteps.firstIndex(where: { $0.id == step.id }) else { return nil }
        return session.sortedSteps.dropFirst(activeIndex + 1).first { $0.status == .pending }
    }

    private var projectedFinish: Date {
        guard let activeIndex = session.sortedSteps.firstIndex(where: { $0.id == step.id }) else { return endingAt }
        return session.sortedSteps
            .dropFirst(activeIndex + 1)
            .filter { $0.status == .pending }
            .reduce(endingAt) { $0.addingTimeInterval($1.plannedDuration) }
    }

    private var openEvents: [TimerAdjustmentPreviewEvent] {
        guard let startedAt = step.startedAt else { return [] }
        var previousDate: Date?
        var events: [TimerAdjustmentPreviewEvent] = []

        for reminder in step.sortedReminders {
            let date = TimerMath.reminderDate(
                stepStart: startedAt,
                stepDuration: step.plannedDuration,
                stepAdjustment: draftAdjustment,
                pauseDuration: step.accumulatedPause,
                offset: reminder.offset,
                mode: reminder.triggerMode,
                previousDate: previousDate
            )
            previousDate = date
            guard reminder.status != .completed, reminder.status != .skipped else { continue }
            events.append(.init(id: "reminder-\(reminder.id.uuidString)", title: reminder.displayTitle, date: date))
        }

        for round in step.sortedFoldReminders where round.status != .completed && round.status != .skipped {
            events.append(.init(id: "fold-\(round.id.uuidString)", title: "Fold \(round.number)", date: round.scheduledAt))
        }

        return events.sorted { $0.date < $1.date }
    }

    private var coldWarning: String? {
        guard step.isColdStep, let startedAt = step.startedAt else { return nil }
        let window = TimerMath.coldWindow(
            startedAt: startedAt,
            target: step.plannedDuration,
            minimum: step.minimumDuration,
            maximum: step.maximumDuration,
            manualAdjustment: draftAdjustment,
            accumulatedPause: step.accumulatedPause
        )
        guard endingAt < window.minimumEnd || endingAt > window.maximumEnd else { return nil }
        return "Outside the recommended fridge window. You can still use this end time."
    }

    private func quickActionLabel(_ minutes: Int) -> String {
        "\(minutes > 0 ? "+" : "−")\(abs(minutes))"
    }

    @ViewBuilder
    private var quickActionButtons: some View {
        let negativeMinutes = [-30, -15, -5, -1]
        let positiveMinutes = [1, 5, 15, 30]

        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: 12) {
                HStack(spacing: 12) {
                    quickActionColumn(negativeMinutes)
                    quickActionColumn(positiveMinutes)
                }
            }
        } else {
            HStack(spacing: 12) {
                quickActionColumn(negativeMinutes)
                quickActionColumn(positiveMinutes)
            }
        }
    }

    private func quickActionColumn(_ values: [Int]) -> some View {
        VStack(spacing: 12) {
            ForEach(values, id: \.self) { minutes in
                quickActionButton(minutes)
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func quickActionButton(_ minutes: Int) -> some View {
        let label = quickActionLabel(minutes)
        let accessibilityLabel = quickActionAccessibilityLabel(minutes)

        if #available(iOS 26.0, *) {
            Button(label) {
                applyQuickAction(minutes)
            }
            .font(.title3.weight(.semibold))
            .foregroundStyle(Color.sourdoughBrown)
            .frame(maxWidth: .infinity, minHeight: 52)
            .buttonStyle(.glass)
            .tint(Color.sourdoughBrown)
            .accessibilityLabel(accessibilityLabel)
        } else {
            Button(label) {
                applyQuickAction(minutes)
            }
            .font(.title3.weight(.semibold))
            .foregroundStyle(Color.sourdoughBrown)
            .frame(maxWidth: .infinity, minHeight: 52)
            .buttonStyle(.bordered)
            .tint(Color.sourdoughBrown)
            .accessibilityLabel(accessibilityLabel)
        }
    }

    private func applyQuickAction(_ minutes: Int) {
        endingAt = max(
            Date().addingTimeInterval(1),
            endingAt.addingTimeInterval(TimeInterval(minutes * 60))
        )
    }

    private func quickActionAccessibilityLabel(_ minutes: Int) -> String {
        let direction = minutes < 0
            ? String(localized: "earlier")
            : String(localized: "later")
        return String(localized: "Move end time \(direction) by \(abs(minutes)) minutes")
    }
}

private struct TimerAdjustmentPreviewEvent: Identifiable {
    let id: String
    let title: String
    let date: Date
}

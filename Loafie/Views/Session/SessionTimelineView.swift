import SwiftUI

struct SessionTimelineView: View {
    let session: BakeSession
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            BakingTimelineView(session: session)
            .navigationTitle("Timeline")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct BakingTimelineView: View {
    @Environment(SessionStore.self) private var sessionStore
    @Environment(NotificationService.self) private var notificationService
    let session: BakeSession
    @State private var focusedStepID: UUID?

    private var projections: [StepProjection] {
        TimelineCalculator.projections(for: session)
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if !quietHoursSuppressedAlarmEvents.isEmpty {
                    QuietHoursWarningView(events: quietHoursSuppressedAlarmEvents)
                }
                ForEach(session.sortedSteps) { step in
                    stepCard(for: step)
                }
            }
            .scrollTargetLayout()
            .padding(.horizontal, LoafieDesign.screenPadding)
            .padding(.vertical, 16)
        }
        .scrollPosition(id: $focusedStepID)
        .scrollTargetBehavior(.viewAligned)
        .scrollIndicators(.hidden)
        .background(Color.flourCream)
        .onChange(of: session.activeStepIndex, initial: true) { _, newIndex in
            guard let newIndex,
                  let step = session.sortedSteps[safe: newIndex] else { return }
            focusedStepID = step.id
        }
        .onChange(of: focusedStepID) { _, newID in
            guard let newID,
                  newID == session.activeStep?.id else { return }
            sessionStore.refreshFoldStates(session)
        }
    }

    private var quietHoursSuppressedAlarmEvents: [ReminderPlanEvent] {
        notificationService.quietHoursSuppressedAlarmEvents(for: session)
    }

    @ViewBuilder
    private func stepCard(for step: SessionStep) -> some View {
        if let projection = projections.first(where: { projection in
            projection.stepID == step.id
        }) {
            let isCurrent = step.id == session.activeStep?.id
            TimelineStepCard(
                step: step,
                projection: projection,
                isCurrent: isCurrent,
                session: session
            )
            .id(step.id)
        }
    }
}

private struct QuietHoursWarningView: View {
    let events: [ReminderPlanEvent]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Quiet hours are silencing alarms", systemImage: "moon.zzz.fill")
                .font(.headline)
                .foregroundStyle(.orange)
            ForEach(events) { event in
                HStack(spacing: 8) {
                    Image(systemName: "alarm.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                    Text(event.title)
                        .font(.subheadline)
                    Spacer()
                    Text(event.date, format: .dateTime.hour().minute())
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: LoafieDesign.cardRadius))
        .accessibilityElement(children: .combine)
    }
}

private struct TimelineStepCard: View {
    @Environment(SessionStore.self) private var sessionStore
    let step: SessionStep
    let projection: StepProjection
    let isCurrent: Bool
    let session: BakeSession

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                stepIcon(for: step.type)
                    .font(.title2)
                    .foregroundStyle(isCurrent ? Color.crustGold : .secondary)
                VStack(alignment: .leading, spacing: 3) {
                    Text(stepTitle)
                        .font(.title3.weight(.semibold))
                    Text(statusLabel)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(statusColor)
                }
                Spacer()
                StatusIndicator(status: step.status)
            }

            if isCurrent {
                TimerReadoutView(step: step, session: session)
                ManualStepGuidanceView(step: step)
                ColdStepStatusView(step: step, session: session)
                ReminderChecklistView(step: step)
                FoldChecklistView(step: step)
                currentActions
            } else {
                TimelineTimesView(step: step, projection: projection)
                TimelineEventsView(step: step, projection: projection)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isCurrent ? Color.crustGold.opacity(0.16) : Color.doughBeige)
        .overlay {
            RoundedRectangle(cornerRadius: LoafieDesign.cardRadius)
                .stroke(isCurrent ? Color.crustGold : .clear, lineWidth: isCurrent ? 2 : 0)
        }
        .clipShape(RoundedRectangle(cornerRadius: LoafieDesign.cardRadius))
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(isCurrent ? .isSelected : [])
    }

    @ViewBuilder
    private var currentActions: some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: 10) {
                actionButtons
            }
        } else {
            actionButtons
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 10) {
            Button {
                Haptics.impact(.light)
                if session.status == .active {
                    sessionStore.pause(session)
                } else {
                    sessionStore.resume(session)
                }
            } label: {
                Image(systemName: session.status == .active ? "pause.fill" : "play.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
            }
            .accessibilityLabel(session.status == .active ? "Pause" : "Resume")
            .help(session.status == .active ? "Pause" : "Resume")
            .disabled(step.plannedDuration <= 0)
            .modifier(TimerGlassButtonModifier(tint: .sourdoughBrown))
            .frame(maxWidth: .infinity)

            ExtendMenu(step: step) { seconds in
                Haptics.impact(.light)
                sessionStore.extend(session, by: seconds)
            }
            .disabled(step.plannedDuration <= 0)
            .frame(maxWidth: .infinity)
            .frame(height: 48)

            Button {
                Haptics.impact(.medium)
                sessionStore.completeActiveStep(session)
            } label: {
                Image(systemName: "checkmark")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
            }
            .accessibilityLabel("Done")
            .help("Done")
            .modifier(TimerGlassButtonModifier(tint: .green))
            .frame(maxWidth: .infinity)
        }
        .controlSize(.small)
    }

    private var statusColor: Color {
        switch step.status {
        case .completed: .green
        case .active, .paused: .accentColor
        case .skipped: .secondary
        case .pending: .primary
        }
    }

    private var statusLabel: String {
        switch step.status {
        case .pending: String(localized: "Pending")
        case .active: String(localized: "Running")
        case .paused: String(localized: "Paused")
        case .completed: String(localized: "Done")
        case .skipped: String(localized: "Not completed")
        }
    }

    private var activeTargetDate: Date {
        TimerMath.plannedEnd(
            startedAt: step.startedAt ?? Date(),
            plannedDuration: step.plannedDuration,
            manualAdjustment: step.manualAdjustment,
            accumulatedPause: step.accumulatedPause
        )
    }

    private var stepTitle: String {
        guard isCurrent, step.plannedDuration > 0 else {
            return step.displayTitle
        }
        return "\(step.displayTitle) bis \(activeTargetDate.formatted(date: .omitted, time: .shortened))"
    }

}

private struct ReminderChecklistView: View {
    @Environment(SessionStore.self) private var sessionStore
    let step: SessionStep

    var body: some View {
        guard !step.sortedReminders.isEmpty else { return AnyView(EmptyView()) }
        return AnyView(
            VStack(alignment: .leading, spacing: 4) {
                Text("Reminders in this step")
                    .font(.headline)
                ForEach(step.sortedReminders) { reminder in
                    HStack(spacing: 10) {
                        Button {
                            sessionStore.toggleReminder(reminder)
                        } label: {
                            HStack(spacing: 10) {
                            Image(systemName: reminder.status == .completed ? "checkmark.square.fill" : "square")
                                .foregroundStyle(reminder.status == .completed ? Color.green : Color.crustGold)
                                .font(.title3)
                            Text(reminder.displayTitle)
                                .multilineTextAlignment(.leading)
                            }
                            .frame(minHeight: 44, alignment: .leading)
                        }
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        .buttonStyle(.plain)
                        .accessibilityLabel(reminder.displayTitle)
                        .accessibilityValue(reminder.status == .completed ? "Erledigt" : "Offen")
                        Text(reminderTime(reminder))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(12)
            .background(Color.doughBeige.opacity(0.72))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        )
    }

    private func reminderTime(_ reminder: SessionReminder) -> String {
        guard let startedAt = step.startedAt else { return "" }
        var previousDate: Date?
        for timer in step.sortedReminders {
            let date = TimerMath.reminderDate(
                stepStart: startedAt,
                stepDuration: step.plannedDuration,
                stepAdjustment: step.manualAdjustment,
                pauseDuration: step.accumulatedPause,
                offset: timer.offset,
                mode: timer.triggerMode,
                previousDate: previousDate
            )
            previousDate = date
            if timer.id == reminder.id {
                return date.formatted(date: .omitted, time: .shortened)
            }
        }
        return ""
    }

}

private struct TimelineTimesView: View {
    let step: SessionStep
    let projection: StepProjection

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Label {
                Text("Planned: \(projection.plannedStart, format: .dateTime.hour().minute()) – \(projection.plannedEnd, format: .dateTime.hour().minute())")
            } icon: {
                Image(systemName: "calendar")
            }
            if let actualStart = projection.actualStart {
                Label {
                    if let actualEnd = projection.actualEnd {
                        Text("Actual: \(actualStart, format: .dateTime.hour().minute()) – \(actualEnd, format: .dateTime.hour().minute())")
                    } else {
                        Text("Actually started: \(actualStart, format: .dateTime.hour().minute())")
                    }
                } icon: {
                    Image(systemName: "checkmark.circle")
                }
            }
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .monospacedDigit()
    }
}

private struct TimelineEventsView: View {
    let step: SessionStep
    let projection: StepProjection

    var body: some View {
        if step.sortedReminders.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 5) {
                ForEach(step.sortedReminders) { timer in
                    Label("\(timer.displayTitle) · \(eventDate(for: timer), format: .dateTime.hour().minute())", systemImage: "timer")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func eventDate(for timer: SessionReminder) -> Date {
        var previousDate: Date?
        for candidate in step.sortedReminders {
            let date = TimerMath.reminderDate(
                stepStart: projection.plannedStart,
                stepDuration: step.plannedDuration,
                stepAdjustment: step.manualAdjustment,
                pauseDuration: step.accumulatedPause,
                offset: candidate.offset,
                mode: candidate.triggerMode,
                previousDate: previousDate
            )
            previousDate = date
            if candidate.id == timer.id { return date }
        }
        return projection.plannedStart
    }
}

struct TimelineRow: View {
    let step: SessionStep
    let projection: StepProjection

    var body: some View {
        HStack(spacing: 12) {
            StatusIndicator(status: step.status)
            stepIcon(for: step.type)
                .foregroundStyle(statusColor)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(step.displayTitle)
                    .font(.headline)
                if step.status == .completed || step.status == .skipped {
                    Text("\(projection.projectedStart, format: .dateTime.hour().minute())")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text("\(projection.projectedStart, format: .dateTime.hour().minute()) – \(projection.projectedEnd, format: .dateTime.hour().minute())")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                Text(statusLabel)
                    .font(.caption)
                    .foregroundStyle(statusColor)

                if !events.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(events) { event in
                            HStack(spacing: 8) {
                                Image(systemName: event.icon)
                                    .font(.caption)
                                    .foregroundStyle(event.color)
                                    .frame(width: 18)
                                Text(event.title)
                                    .font(.caption)
                                Spacer()
                                Text(event.date, format: .dateTime.hour().minute())
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.top, 2)
                }
            }
        }
        .padding(.vertical, 2)
    }

    private var events: [TimelineEvent] {
        var result: [TimelineEvent] = []

        var previousDate: Date?
        for timer in step.sortedReminders {
            let scheduledAt = TimerMath.reminderDate(
                stepStart: projection.projectedStart,
                stepDuration: step.plannedDuration,
                stepAdjustment: step.manualAdjustment,
                pauseDuration: step.accumulatedPause,
                offset: timer.offset,
                mode: timer.triggerMode,
                previousDate: previousDate
            )
            previousDate = scheduledAt
            result.append(
                TimelineEvent(
                    id: "subtimer-\(timer.id.uuidString)",
                    title: timer.displayTitle,
                    icon: reminderIcon(for: timer),
                    date: scheduledAt,
                    color: timer.status == .completed ? .green : timer.status == .skipped ? .secondary : .orange
                )
            )
        }

        if !step.sortedFoldReminders.isEmpty {
            for round in step.sortedFoldReminders {
                result.append(
                    TimelineEvent(
                        id: "fold-\(round.id.uuidString)",
                        title: "Fold \(round.number)",
                        icon: foldIcon(for: round),
                        date: round.scheduledAt,
                        color: round.status == .completed ? .green : round.status == .skipped ? .secondary : .purple
                    )
                )
            }
        } else if step.foldIsEnabled, step.foldRepetitions > 0 {
            let offsets = FoldReminderCalculator.roundOffsets(
                repetitions: step.foldRepetitions,
                interval: step.foldInterval,
                firstReminderOffset: step.foldFirstOffset
            )
            for (index, offset) in offsets.enumerated() {
                result.append(
                    TimelineEvent(
                        id: "planned-fold-\(step.id.uuidString)-\(index)",
                        title: "Fold \(index + 1)",
                        icon: "hands.clap.fill",
                        date: projection.projectedStart.addingTimeInterval(offset),
                        color: .purple
                    )
                )
            }
        }

        return result.sorted { $0.date < $1.date }
    }

    private func reminderIcon(for timer: SessionReminder) -> String {
        switch timer.status {
        case .completed: "checkmark.circle.fill"
        case .skipped: "minus.circle"
        default: "timer"
        }
    }

    private func foldIcon(for round: SessionFoldReminder) -> String {
        switch round.status {
        case .completed: "checkmark.circle.fill"
        case .skipped: "minus.circle"
        default: "hands.clap.fill"
        }
    }

    private var statusColor: Color {
        switch step.status {
        case .completed: .green
        case .active, .paused: .accentColor
        case .skipped: .secondary
        case .pending: .primary
        }
    }

    private var statusLabel: String {
        switch step.status {
        case .pending: String(localized: "Pending")
        case .active: String(localized: "Running")
        case .paused: String(localized: "Paused")
        case .completed: String(localized: "Done")
        case .skipped: String(localized: "Not completed")
        }
    }
}

private struct TimelineEvent: Identifiable {
    let id: String
    let title: String
    let icon: String
    let date: Date
    let color: Color
}

struct StatusIndicator: View {
    let status: BakeStepStatus

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 12, height: 12)
            .overlay {
                if status == .completed {
                    Image(systemName: "checkmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
    }

    private var color: Color {
        switch status {
        case .pending: Color.secondary.opacity(0.3)
        case .active, .paused: .accentColor
        case .completed: .green
        case .skipped: .secondary
        }
    }
}

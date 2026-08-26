import SwiftUI
import SwiftData

struct ActiveSessionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(SessionStore.self) private var sessionStore
    @Environment(NotificationService.self) private var notificationService
    @Query private var sessions: [BakeSession]
    @Query(sort: \BakePlan.updatedAt, order: .reverse) private var bakePlans: [BakePlan]

    @State private var showCancelConfirmation = false
    @State private var showSchedulePicker = false
    @State private var newBakePlan: BakePlan?
    @State private var showPlanAdjustment = false

    private var runningSession: BakeSession? {
        sessions.first {
            $0.status == .planned || $0.status.isRunning
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if let session = runningSession {
                    if session.status == .planned {
                        plannedBody(session: session)
                    } else {
                        activeBody(session: session)
                    }
                } else {
                    emptyState
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .navigationTitle("Timer")
            .background(Color.flourCream)
            .tint(.sourdoughBrown)
            .toolbarBackground(Color.flourCream, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(isPresented: $showSchedulePicker) {
                BakePlanPickerView(bakePlans: bakePlans) {
                    showSchedulePicker = false
                }
            }
            .sheet(item: $newBakePlan) { bakePlan in
                NavigationStack {
                    BakePlanEditView(
                        bakePlan: bakePlan,
                        onStarted: {
                            newBakePlan = nil
                        },
                        onCancelled: {
                            modelContext.delete(bakePlan)
                            newBakePlan = nil
                        }
                    )
                }
            }
        }
    }

    private func plannedBody(session: BakeSession) -> some View {
        VStack(spacing: 24) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 52))
                .foregroundStyle(Color.crustGold)
            Text("Ready to start")
                .font(.title2.weight(.semibold))
            if let plannedStartAt = session.plannedStartAt {
                Text(plannedStartAt, format: .dateTime.weekday(.wide).hour().minute())
                    .font(.headline)
                Text("Starts at \(plannedStartAt, format: .dateTime.hour().minute())")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .monospacedDigit()
            }
            if let earliest = session.planningEarliestStartAt,
               let latest = session.planningLatestStartAt {
                VStack(spacing: 4) {
            Text("Recommended start window")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("\(earliest, format: .dateTime.weekday(.wide).hour().minute()) – \(latest, format: .dateTime.hour().minute())")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                }
            }
            Text(session.bakePlanName)
                .foregroundStyle(.secondary)
        }
        .padding(LoafieDesign.screenPadding)
        .background(Color.flourCream)
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 16) {
                Button {
                    sessionStore.startPlannedSession(session)
                } label: {
                    Image(systemName: "play.fill")
                        .font(.system(size: 26, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                }
                .accessibilityLabel("Start First Step")
                .modifier(TimerGlassButtonModifier(tint: .sourdoughBrown, prominent: true))

                Button {
                    showCancelConfirmation = true
                } label: {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 22, weight: .bold))
                        .frame(width: 48, height: 48)
                }
                .accessibilityLabel("Cancel Bake")
                .modifier(TimerGlassButtonModifier(tint: .red))
            }
            .padding()
        }
        .alert("Cancel bake?", isPresented: $showCancelConfirmation) {
            Button("Cancel bake", role: .destructive) { sessionStore.cancel(session) }
            Button("Continue", role: .cancel) {}
        }
    }

    private var emptyState: some View {
        EmptyStateView(
            systemImage: "timer",
            title: "No bake in progress",
            message: "Choose a bake plan to begin.",
            actionTitle: "Start Timer"
        ) {
                if bakePlans.isEmpty {
                    createBakePlan()
                } else {
                    showSchedulePicker = true
                }
        }
    }

    private func createBakePlan() {
        let bakePlan = BakePlanTemplates.makeBakePlan(
            name: String(localized: "New Bake Plan"),
            timing: .sameDay
        )
        modelContext.insert(bakePlan)
        newBakePlan = bakePlan
    }

    private func activeBody(session: BakeSession) -> some View {
        VStack(spacing: 0) {
            if notificationService.authorizationDenied || notificationService.lastSchedulingError != nil {
                notificationDeniedBanner
                    .padding(.top, 8)
            }
            if session.activeStep == nil,
               let nextStep = session.sortedSteps.first(where: { $0.status == .pending }) {
                WaitingForNextStepCard(
                    completedStep: session.sortedSteps.last(where: { $0.status == .completed }),
                    nextStep: nextStep,
                    start: { sessionStore.startNextStep(session) }
                )
                .padding(.horizontal, LoafieDesign.screenPadding)
                .padding(.vertical, 12)
            }
            BakingTimelineView(session: session)
        }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel", role: .destructive) {
                        showCancelConfirmation = true
                    }
                .accessibilityLabel("Cancel Bake")
                .help("Cancel Bake")
                .tint(.red)
            }
        }
        .alert("Cancel bake?", isPresented: $showCancelConfirmation) {
            Button("Cancel bake", role: .destructive) {
                sessionStore.cancel(session)
            }
            Button("Continue", role: .cancel) {}
        } message: {
            Text("This will stop the current bake and clear all pending reminders.")
        }
        .alert("Adjust the bake plan?", isPresented: $showPlanAdjustment) {
            Button("Adjust plan") { sessionStore.resolvePlanAdjustment(for: session, adjust: true) }
            Button("Keep current plan", role: .cancel) { sessionStore.resolvePlanAdjustment(for: session, adjust: false) }
        } message: {
            Text("The remaining steps can be recalculated from when the current step actually finishes.")
        }
        .task(id: session.id) {
            while !Task.isCancelled {
                sessionStore.refreshFoldStates(session)
                try? await Task.sleep(for: .seconds(10))
            }
        }
        .onChange(of: session.pendingPlanAdjustmentStepID) { _, pending in
            showPlanAdjustment = pending != nil
        }
        .onAppear {
            showPlanAdjustment = session.pendingPlanAdjustmentStepID != nil
        }
    }

    private var notificationDeniedBanner: some View {
        Label(
            notificationService.lastSchedulingError ?? "Notifications disabled — reminders won't appear.",
            systemImage: notificationService.lastSchedulingError == nil ? "bell.slash.fill" : "exclamationmark.triangle.fill"
        )
            .font(.subheadline)
            .foregroundStyle(.orange)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.timerPaused.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
    }
}

private struct WaitingForNextStepCard: View {
    let completedStep: SessionStep?
    let nextStep: SessionStep
    let start: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let completedStep {
                Label(
                    "\(completedStep.displayTitle) · \(String(localized: "Step finished"))",
                    systemImage: "checkmark.circle.fill"
                )
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.timerCompleted)
            }

            Text(String(localized: "Next: \(nextStep.displayTitle)"))
                .font(.title3.weight(.semibold))

            if let notes = nextStep.notes, !notes.isEmpty {
                Text(notes)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            Text(nextStep.isManualStep
                 ? String(localized: "No timer for this step")
                 : DurationFormatter.string(from: nextStep.plannedDuration))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            Button {
                start()
            } label: {
                Label("Start \(nextStep.displayTitle)", systemImage: "play.fill")
            }
            .buttonStyle(LoafiePrimaryButtonStyle())
        }
        .loafieCard()
        .accessibilityElement(children: .contain)
    }
}

private struct BakePlanPickerView: View {
    @Environment(\.dismiss) private var dismiss

    let bakePlans: [BakePlan]
    let onStarted: () -> Void
    @State private var selectedBakePlan: BakePlan?

    var body: some View {
        NavigationStack {
            Group {
                if bakePlans.isEmpty {
                    ContentUnavailableView {
                        Label("No bake plans yet", systemImage: "list.bullet.rectangle")
                    } description: {
                        Text("Create a bake plan in the Bake Plans tab first.")
                    }
                } else {
                    List(bakePlans) { bakePlan in
                        Button {
                            selectedBakePlan = bakePlan
                        } label: {
                            BakePlanRowView(bakePlan: bakePlan)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Color.flourCream)
                    .safeAreaPadding(.horizontal, LoafieDesign.screenPadding - 4)
                    .safeAreaPadding(.vertical, 8)
                }
            }
            .navigationTitle("Choose bake plan")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color.flourCream)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .navigationDestination(item: $selectedBakePlan) { bakePlan in
                SessionStartView(bakePlan: bakePlan, onStarted: onStarted)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Subviews

struct StepHeaderView: View {
    let session: BakeSession

    var body: some View {
        VStack(spacing: 6) {
            if let step = session.activeStep {
                stepIcon(for: step.type)
                    .font(.system(size: 48))
                    .foregroundStyle(Color.crustGold)
                Text(step.displayTitle)
                    .font(.title2)
                    .fontWeight(.semibold)
                if let next = session.sortedSteps[safe: (session.activeStepIndex ?? -1) + 1] {
                    Text("Next: \(next.displayTitle)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("Step finished")
                    .font(.title2)
                if let next = session.sortedSteps.first(where: { $0.status == .pending }) {
                    Text("Next: \(next.displayTitle) · \(DurationFormatter.string(from: next.plannedDuration))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

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
                } else if step.isManualStep {
                    Text("No timer for this step")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
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
        guard step.isManualStep else { return AnyView(EmptyView()) }
        return AnyView(
            VStack(alignment: .leading, spacing: 6) {
                Text("No timer for this step")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.crustGold)
                if let notes = step.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(Color.crustGold.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: LoafieDesign.cardRadius))
        )
    }
}

struct NextStepReadyView: View {
    let next: SessionStep

    var body: some View {
        Label("Start the next step when you are ready: \(next.displayTitle)", systemImage: "arrow.right.circle")
            .font(.title3)
            .padding()
    }
}

struct ColdStepStatusView: View {
    let step: SessionStep
    let session: BakeSession

    var body: some View {
        guard step.isColdStep else { return AnyView(EmptyView()) }
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
            startedAt: step.startedAt ?? Date(), target: step.plannedDuration,
            minimum: step.minimumDuration, maximum: step.maximumDuration,
            manualAdjustment: step.manualAdjustment, accumulatedPause: step.accumulatedPause
        )

        return AnyView(
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
            .padding(.horizontal)
        )
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

struct ReminderSummaryView: View {
    let step: SessionStep
    let session: BakeSession

    var body: some View {
        guard !step.sortedReminders.isEmpty, let startedAt = step.startedAt else { return AnyView(EmptyView()) }
        return AnyView(
            VStack(spacing: 8) {
                ForEach(step.sortedReminders) { reminder in
                    HStack {
                        Image(systemName: reminderIcon(for: reminder))
                            .foregroundStyle(reminder.status == .pending ? Color.secondary : Color.crustGold)
                        Text(reminder.displayTitle)
                            .font(.subheadline)
                        Spacer()
                        Text(timeText(for: reminder, startedAt: startedAt))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.doughBeige)
            .clipShape(RoundedRectangle(cornerRadius: LoafieDesign.cardRadius))
            .padding(.horizontal)
        )
    }

    private func reminderIcon(for reminder: SessionReminder) -> String {
        switch reminder.status {
        case .completed: "checkmark.circle.fill"
        case .skipped: "xmark.circle"
        default: "timer"
        }
    }

    private func timeText(for reminder: SessionReminder, startedAt: Date) -> String {
        var previousDate: Date?
        var scheduledAt = startedAt
        for timer in step.sortedReminders {
            scheduledAt = TimerMath.reminderDate(
                stepStart: startedAt,
                stepDuration: step.plannedDuration,
                stepAdjustment: step.manualAdjustment,
                pauseDuration: step.accumulatedPause,
                offset: timer.offset,
                mode: timer.triggerMode,
                previousDate: previousDate
            )
            previousDate = scheduledAt
            if timer.id == reminder.id { break }
        }
        let remaining = scheduledAt.timeIntervalSince(Date())
        if reminder.status == .completed {
            return String(localized: "Done")
        }
        if reminder.status == .skipped {
            return String(localized: "Not completed")
        }
        if remaining < -60 {
            return String(localized: "\(DurationFormatter.string(from: abs(remaining))) ago")
        } else if remaining < 0 {
            return String(localized: "Due")
        }
        return String(localized: "in \(DurationFormatter.string(from: remaining))")
    }
}

struct ReminderBanner: View {
    @Environment(SessionStore.self) private var sessionStore
    let step: SessionStep

    var dueTimer: SessionReminder? {
        guard let startedAt = step.startedAt else { return nil }
        let now = Date()
        var previousDate: Date?
        for timer in step.sortedReminders {
            let scheduledAt = TimerMath.reminderDate(
                stepStart: startedAt,
                stepDuration: step.plannedDuration,
                stepAdjustment: step.manualAdjustment,
                pauseDuration: step.accumulatedPause,
                offset: timer.offset,
                mode: timer.triggerMode,
                previousDate: previousDate
            )
            previousDate = scheduledAt
            if (timer.status == .pending || timer.status == .triggered) && scheduledAt <= now {
                return timer
            }
        }
        return nil
    }

    var body: some View {
        if let timer = dueTimer {
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "timer")
                    Text(timer.displayTitle)
                        .font(.headline)
                }

                HStack(spacing: 12) {
                    Button {
                        Haptics.impact(.medium)
                        sessionStore.completeReminder(timer)
                    } label: {
                        Image(systemName: "checkmark")
                            .font(.system(size: 20, weight: .bold))
                            .frame(width: 52, height: 52)
                    }
                    .accessibilityLabel("Done")
                    .buttonStyle(LoafiePrimaryButtonStyle())

                }
                .controlSize(.small)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.crustGold.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: LoafieDesign.cardRadius))
        } else {
            EmptyView()
        }
    }
}

struct ExtendMenu: View {
    let step: SessionStep
    let action: (TimeInterval) -> Void

    var body: some View {
        Menu {
            Button("+5 min") { action(5 * 60) }
            Button("+15 min") { action(15 * 60) }
            Button("+30 min") { action(30 * 60) }
            Button("+1 h") { action(60 * 60) }
            if step.isColdStep {
                Button("+2 h") { action(2 * 3600) }
                Button("+4 h") { action(4 * 3600) }
            }
        } label: {
            Image(systemName: "plus.circle")
                .font(.system(size: 22, weight: .bold))
                .frame(maxWidth: .infinity)
                .frame(height: 48)
        }
        .accessibilityLabel("Extend time")
        .modifier(TimerGlassButtonModifier(tint: .crustGold))
    }
}

struct TimerGlassButtonModifier: ViewModifier {
    let tint: Color
    let prominent: Bool

    init(tint: Color, prominent: Bool = false) {
        self.tint = tint
        self.prominent = prominent
    }

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            if prominent {
                content
                    .buttonStyle(.glassProminent)
                    .buttonBorderShape(.capsule)
                    .tint(tint)
            } else {
                content
                    .buttonStyle(.glass)
                    .buttonBorderShape(.capsule)
                    .tint(tint)
            }
        } else {
            content
                .foregroundStyle(tint)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay {
                    Capsule()
                        .stroke(tint.opacity(0.22), lineWidth: 1)
                }
        }
    }
}

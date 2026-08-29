import SwiftUI
import SwiftData

/// Start flow for a bakePlan. The mode and backwards-planning target are
/// selected here so the reusable bakePlan stays independent of a calendar date.
struct SessionStartView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(SessionStore.self) private var sessionStore
    @Environment(NotificationService.self) private var notificationService
    @Environment(SettingsStore.self) private var settings

    let bakePlan: BakePlan
    var onStarted: (() -> Void)? = nil

    @State private var startMode: BakeStartMode
    @State private var targetDate: Date
    @State private var targetMode: BakeStartPlanner.TargetMode
    @State private var startedSession = false
    @State private var showRunningError = false
    @State private var showReplaceConfirmation = false
    @State private var showAlarmKitPrompt = false

    init(bakePlan: BakePlan, onStarted: (() -> Void)? = nil) {
        self.bakePlan = bakePlan
        self.onStarted = onStarted
        _startMode = State(initialValue: bakePlan.timing == .sameDay ? .startNow : .planBackwards)
        _targetMode = State(initialValue: .bakeStart)

        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.day = (components.day ?? 1) + 1
        components.hour = 8
        components.minute = 0
        _targetDate = State(initialValue: Calendar.current.date(from: components) ?? Date())
    }

    private var hasBakeStep: Bool {
        bakePlan.enabledSteps.contains { $0.type == .bake }
    }

    private var planning: BakeStartPlanner.Result {
        BakeStartPlanner.result(bakePlan: bakePlan, target: targetDate, mode: targetMode)
    }

    private var validationIssues: [BakePlanStartValidator.Issue] {
        BakePlanStartValidator.issues(for: bakePlan)
    }

    private var targetLabel: LocalizedStringKey {
        targetMode == .bakeStart ? "Bake starts" : "Cooled"
    }

    private var startActionLabel: LocalizedStringKey {
        startMode == .startNow ? "Start now" : "Plan start"
    }

    private var startErrorTitle: LocalizedStringKey {
        startMode == .startNow ? "Cannot start" : "Cannot plan"
    }

    var body: some View {
        List {
            Section("When should this bake begin?") {
                Picker("Mode", selection: $startMode) {
                    Text("Start now").tag(BakeStartMode.startNow)
                    Text("Plan backward").tag(BakeStartMode.planBackwards)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }
            .listRowBackground(Color.doughBeige)

            if !validationIssues.isEmpty {
                validationWarning
            }

            if startMode == .planBackwards {
                planningControls
            }

            timelineSection

            if sessionStore.currentSession() != nil {
                Section {
                    Label(
                        "Another bake is already running or planned. Finish or cancel it first.",
                        systemImage: "exclamationmark.triangle.fill"
                    )
                    .foregroundStyle(.orange)
                }
                .listRowBackground(Color.doughBeige)
            }
        }
        .navigationTitle(bakePlan.name)
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
        .background(Color.flourCream)
        .tint(.sourdoughBrown)
        .listStyle(.insetGrouped)
        .listRowBackground(Color.doughBeige)
        .safeAreaInset(edge: .bottom) {
            Button {
                start()
            } label: {
                Label(
                    startActionLabel,
                    systemImage: startMode == .startNow ? "play.fill" : "calendar.badge.clock"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(LoafiePrimaryButtonStyle())
            .controlSize(.large)
            .disabled(!canPlan)
            .padding()
            .background(Color.flourCream)
        }
        .onAppear {
            if !hasBakeStep && targetMode == .bakeStart {
                targetMode = .readyToSlice
            }
        }
        .alert(startErrorTitle, isPresented: $showRunningError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Another bake is already running or planned. Finish or cancel it before starting this bake.")
        }
        .alert("Replace current bake?", isPresented: $showReplaceConfirmation) {
            Button("Replace and start", role: .destructive) {
                replaceExistingSessionAndStart()
            }
            Button("Continue", role: .cancel) {}
        } message: {
            Text("Another bake is already running or planned. Replace it with this bake plan?")
        }
        .alert("Use system alarms?", isPresented: $showAlarmKitPrompt) {
            Button("Use alarms") {
                Task { @MainActor in
                    settings.alarmKitEnabled = await notificationService.requestAlarmKitAuthorization()
                    completeStart()
                }
            }
            Button("Not now", role: .cancel) {
                completeStart()
            }
        } message: {
            Text("System alarms can alert you at important baking times, even when the app is not open.")
        }
        .onChange(of: startedSession) { _, started in
            if started { dismiss() }
        }
    }

    @ViewBuilder
    private var validationWarning: some View {
        Section("Check this bake plan") {
            Label(
                "Fix these timing issues before starting the bake.",
                systemImage: "exclamationmark.triangle.fill"
            )
            .foregroundStyle(.red)

            ForEach(validationIssues) { issue in
                Text(issue.message)
                    .foregroundStyle(.red)
            }
        }
        .listRowBackground(Color.doughBeige)
    }

    @ViewBuilder
    private var planningControls: some View {
        Section("Target") {
            DatePicker(targetLabel, selection: $targetDate)
            Picker("Target Time", selection: $targetMode) {
                if hasBakeStep {
                    Text("Bake starts").tag(BakeStartPlanner.TargetMode.bakeStart)
                }
                Text("Cooled").tag(BakeStartPlanner.TargetMode.readyToSlice)
            }
        }
        .listRowBackground(Color.doughBeige)

        Section {
            LabeledContent("Recommended") {
                Text(planning.recommendedStart, format: .dateTime.weekday(.wide).hour().minute())
                    .font(.headline)
            }
            LabeledContent("Earliest") {
                Text(planning.earliestStart, format: .dateTime.weekday(.wide).hour().minute())
            }
            LabeledContent("Latest") {
                Text(planning.latestStart, format: .dateTime.weekday(.wide).hour().minute())
            }

            TimelineView(.periodic(from: Date(), by: 1)) { (context: TimelineViewDefaultContext) in
                planningStatus(at: context.date)
            }
        } header: {
            Text("Suggested start")
        } footer: {
            Text("This range accounts for the possible fridge times. Choose when to start the first step.")
        }
        .listRowBackground(Color.doughBeige)

    }

    @ViewBuilder
    private var timelineSection: some View {
        Section {
            ForEach(BakePlanTimelineCalculator.projections(for: bakePlan)) { entry in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top, spacing: 8) {
                        stepIcon(for: entry.step.type)
                            .frame(width: 28)
                            .foregroundStyle(Color.sourdoughBrown)

                        Text(entry.step.displayTitle)
                            .font(.headline)
                            .foregroundStyle(Color.sourdoughBrown)

                        Spacer(minLength: 8)

                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(entry.startDate(anchor: timelineAnchor), format: .dateTime.hour().minute())–\(entry.endDate(anchor: timelineAnchor), format: .dateTime.hour().minute())")
                                .font(.subheadline.monospacedDigit())
                                .foregroundStyle(.secondary)
                            Text(entry.step.effectiveDuration > 0
                                 ? DurationFormatter.string(from: entry.step.effectiveDuration)
                                 : "No timer for this step")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    ForEach(entry.reminders) { reminder in
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Image(systemName: "bell.fill")
                                .font(.caption)
                                .foregroundStyle(Color.sourdoughBrown)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                            Text(reminder.timer.displayTitle)
                                .foregroundStyle(Color.sourdoughBrown)
                            Text(reminder.timer.triggerMode.title)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(reminder.date(anchor: timelineAnchor), format: .dateTime.hour().minute())
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.orange)
                        }
                        .padding(.leading, 32)
                    }

                    ForEach(entry.folds) { fold in
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Image(systemName: "hands.clap.fill")
                                .font(.caption)
                                .foregroundStyle(Color.sourdoughBrown)
                                .frame(width: 24)
                            Text(String(localized: "Fold \(fold.number)"))
                                .foregroundStyle(Color.sourdoughBrown)
                            Spacer()
                            Text(fold.date(anchor: timelineAnchor), format: .dateTime.hour().minute())
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.purple)
                        }
                        .padding(.leading, 32)
                    }
                }
                .padding(.vertical, 4)
            }
        } header: {
            Text("Timeline")
        } footer: {
            Text("Total: \(DurationFormatter.string(from: bakePlan.typicalDuration))")
        }
        .listRowBackground(Color.doughBeige)
    }

    private var timelineAnchor: Date {
        startMode == .startNow ? Date() : planning.recommendedStart
    }

    @ViewBuilder
    private func planningStatus(at now: Date) -> some View {
        let recommendedRemaining = planning.recommendedStart.timeIntervalSince(now)
        if recommendedRemaining > 0 {
            Label(
                "Waiting \(DurationFormatter.countdown(from: recommendedRemaining))",
                systemImage: "hourglass"
            )
            .foregroundStyle(Color.secondary)
        } else if now > planning.latestStart {
            Label(
                "Too late to start and meet the requested time.",
                systemImage: "exclamationmark.triangle.fill"
            )
            .foregroundStyle(Color.red)
        } else {
            Label("Recommended start time passed", systemImage: "clock.badge.checkmark")
                .foregroundStyle(Color.orange)
        }
    }

    private var canPlan: Bool {
        validationIssues.isEmpty && (startMode == .startNow || targetDate > Date())
    }

    private func start() {
        if sessionStore.currentSession() != nil {
            showReplaceConfirmation = true
            return
        }

        performStart()
    }

    private func replaceExistingSessionAndStart() {
        if let existingSession = sessionStore.currentSession() {
            sessionStore.cancel(existingSession)
        }
        performStart()
    }

    private func performStart() {
        if #available(iOS 26.0, *), !settings.hasPromptedForAlarmKit {
            settings.hasPromptedForAlarmKit = true
            showAlarmKitPrompt = true
            return
        }
        completeStart()
    }

    private func completeStart() {
        Task {
            Haptics.impact(.medium)
            if settings.notificationsEnabled {
                _ = await notificationService.requestAuthorization()
            }
            do {
                saveBakePlan()
                if startMode == .startNow {
                    _ = try sessionStore.start(bakePlan: bakePlan)
                } else {
                    _ = try sessionStore.plan(
                        bakePlan: bakePlan,
                        target: targetDate,
                        mode: targetMode
                    )
                }
                onStarted?()
                startedSession = true
            } catch {
                showRunningError = true
            }
        }
    }

    private func saveBakePlan() {
        bakePlan.updatedAt = Date()
        try? modelContext.save()
    }
}

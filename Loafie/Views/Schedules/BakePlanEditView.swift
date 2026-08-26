import SwiftUI
import SwiftData

/// BakePlan editor: vertical timeline of step cards with automatic persistence.
struct BakePlanEditView: View {
    @Environment(\.modelContext) private var modelContext

    @Bindable var bakePlan: BakePlan
    var onStarted: (() -> Void)? = nil
    var onDone: (() -> Void)? = nil
    var onCancelled: (() -> Void)? = nil
    @State private var editingStep: BakeStepDefinition?
    @State private var isCancelling = false

    var body: some View {
        Form {
            Section("Name") {
                TextField("Bake plan name", text: $bakePlan.name)
            }
            .listRowBackground(Color.doughBeige)

            Section("Timing") {
                Picker("Timing", selection: Binding(
                    get: { bakePlan.timing },
                    set: selectBakePlanTiming
                )) {
                    Text("Same day").tag(BakePlanTiming.sameDay)
                    Text("Overnight — cold proof").tag(BakePlanTiming.coldFinalProof)
                    Text("Cold bulk fermentation — advanced").tag(BakePlanTiming.coldBulk)
                }
            }
            .listRowBackground(Color.doughBeige)

            Section {
                ForEach(bakePlan.sortedSteps) { step in
                    StepCardView(step: step)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            editingStep = step
                        }
                }
            } header: {
                Text("Steps")
            } footer: {
                Text("Choose a step to change its duration, reminders, or notes. Turn off steps you do not use.")
            }
            .listRowBackground(Color.doughBeige)

            Section {
                ForEach(calculatedTimeline) { entry in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            stepIcon(for: entry.step.type)
                                .frame(width: 24)
                                .foregroundStyle(Color.crustGold)
                            Text(entry.step.displayTitle)
                                .font(.headline)
                            Spacer()
                            Text("\(clock(entry.startOffset))–\(clock(entry.endOffset))")
                                .font(.subheadline.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }

                        ForEach(entry.reminders) { reminder in
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Image(systemName: "bell.fill")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                                    .frame(width: 24)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(reminder.timer.displayTitle)
                                    Text(reminder.timer.triggerMode.title)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(clock(reminder.offset))
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.orange)
                            }
                            .padding(.leading, 32)
                            .fixedSize(horizontal: false, vertical: true)
                        }

                        ForEach(entry.folds) { fold in
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Image(systemName: "hands.clap.fill")
                                    .font(.caption)
                                    .foregroundStyle(.purple)
                                    .frame(width: 24)
                                Text(String(localized: "Fold \(fold.number)"))
                                Spacer()
                                Text(clock(fold.offset))
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.purple)
                            }
                            .padding(.leading, 32)
                            .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.vertical, 4)
                    // Form can otherwise underestimate rows containing a
                    // nested ForEach when sub-timers are added during editing.
                    .fixedSize(horizontal: false, vertical: true)
                }
            } header: {
                Text("Bake timeline")
            } footer: {
                Text("This timeline shows when each step and reminder will happen based on the durations above.")
            }
            .listRowBackground(Color.doughBeige)
        }
        .navigationTitle(bakePlan.name)
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
        .background(Color.flourCream)
        .tint(.sourdoughBrown)
        .listStyle(.insetGrouped)
        .listRowBackground(Color.doughBeige)
        .toolbar {
            if onCancelled != nil {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) {
                        isCancelling = true
                        onCancelled?()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 17, weight: .bold))
                    }
                    .accessibilityLabel("Cancel")
                }
            }
            if onDone != nil {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        saveChanges()
                        onDone?()
                    } label: {
                        Image(systemName: "checkmark")
                            .font(.system(size: 17, weight: .bold))
                    }
                    .accessibilityLabel("Done")
                }
            }
            ToolbarItem(placement: .primaryAction) {
                startButton
            }
        }
        .sheet(item: $editingStep) { step in
            NavigationStack {
                StepEditView(step: step)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button {
                                editingStep = nil
                            } label: {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 17, weight: .bold))
                            }
                            .accessibilityLabel("Done")
                }
            }
        }
        }
        .onDisappear {
            if !isCancelling {
                saveChanges()
            }
        }
    }

    private var hasName: Bool {
        !bakePlan.name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var calculatedTimeline: [BakePlanTimelineEntry] {
        BakePlanTimelineCalculator.projections(for: bakePlan)
    }

    private func clock(_ interval: TimeInterval) -> String {
        // The bakePlan definition timeline is minute-based; do not expose
        // implementation-level seconds from calculated offsets here.
        DurationFormatter.string(from: interval)
    }

    private var startButton: some View {
        NavigationLink {
            SessionStartView(bakePlan: bakePlan, onStarted: onStarted)
        } label: {
            Image(systemName: "play.fill")
                .font(.system(size: 17, weight: .bold))
        }
        .accessibilityLabel("Start")
        .disabled(!hasName)
    }

    private func selectBakePlanTiming(_ timing: BakePlanTiming) {
        guard timing != bakePlan.timing else { return }
        applyBakePlanTiming(timing)
    }

    private func applyBakePlanTiming(_ timing: BakePlanTiming) {
        let oldSteps = bakePlan.steps
        let newSteps = BakePlanTemplates.makeSteps(for: timing)
        for step in newSteps {
            step.bakePlan = bakePlan
            step.foldReminderConfiguration?.step = step
            for reminder in step.reminders ?? [] {
                reminder.step = step
            }
        }
        bakePlan.timing = timing
        bakePlan.steps = newSteps
        for step in oldSteps {
            modelContext.delete(step)
        }
        saveChanges()
    }

    private func saveChanges() {
        bakePlan.updatedAt = Date()
        try? modelContext.save()
    }
}

struct StepCardView: View {
    @Bindable var step: BakeStepDefinition

    var body: some View {
        HStack(spacing: 12) {
            stepIcon(for: step.type)
                .frame(width: 28)
                .foregroundStyle(step.isEnabled ? Color.crustGold : Color.secondary)

            VStack(alignment: .leading, spacing: 2) {
                if step.type == .bake, let temperature = step.temperatureCelsius {
                    Text("\(step.displayTitle) · \(temperature) °C")
                        .font(.headline)
                        .strikethrough(!step.isEnabled)
                        .foregroundStyle(step.isEnabled ? .primary : .secondary)
                } else {
                    Text(step.displayTitle)
                        .font(.headline)
                        .strikethrough(!step.isEnabled)
                        .foregroundStyle(step.isEnabled ? .primary : .secondary)
                }

                HStack(spacing: 6) {
                    Text(DurationFormatter.string(from: step.effectiveDuration))
                    if step.type != .bake, let temperature = step.temperatureCelsius {
                        Text("· \(temperature) °C")
                    }
                    if let fold = step.foldReminderConfiguration, fold.isEnabled, fold.repetitions > 0 {
                        Text("· \(fold.repetitions)× \(String(localized: "folds"))")
                    }
                    if step.type.isColdStep, let min = step.minimumDuration, let max = step.maximumDuration {
                        Text("· \(DurationFormatter.string(from: min))–\(DurationFormatter.string(from: max))")
                    }
                    if !step.sortedReminders.isEmpty {
                        Text("· \(step.sortedReminders.count) \(String(localized: "reminders"))")
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Toggle("", isOn: $step.isEnabled)
                .labelsHidden()
        }
        .padding(.vertical, 4)
    }
}

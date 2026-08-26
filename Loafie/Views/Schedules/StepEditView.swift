import SwiftUI
import SwiftData

/// Detail editor for one step inside a bakePlan.
struct StepEditView: View {
    @Bindable var step: BakeStepDefinition
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Form {
            if step.type == .custom {
                Section("Title") {
                    TextField("Step Name", text: $step.title)
                }
                .listRowBackground(Color.doughBeige)
            }

            Section("Use this step") {
                Toggle("Use this step", isOn: $step.isEnabled)
            }
            .listRowBackground(Color.doughBeige)

            Section("Duration") {
                DurationPickerView(interval: targetDurationBinding)
                    .frame(maxWidth: .infinity)
            }
            .listRowBackground(Color.doughBeige)

            if step.type.isColdStep {
                Section {
                    LabeledContent("Minimum") {
                        DurationPickerView(interval: minimumBinding, maximumHours: 48)
                            .frame(width: 220)
                    }
                    LabeledContent("Maximum") {
                        DurationPickerView(interval: maximumBinding, maximumHours: 72)
                            .frame(width: 220)
                    }
                } header: {
                    Text("Fridge timing")
                } footer: {
                    Text("Usual is the time you normally want. Minimum and maximum show the recommended range for this fridge step.")
                }
                .listRowBackground(Color.doughBeige)
            }

            if step.type == .bake {
                Section("Oven temperature") {
                    Stepper(value: temperatureBinding, in: 100...300, step: 5) {
                        LabeledContent("Temperature", value: "\(step.temperatureCelsius ?? 0) °C")
                    }
                }
                .listRowBackground(Color.doughBeige)
            }

            if step.type.supportsFolding {
                foldConfigurationSection
            }

            if step.type.supportsReminders {
                ReminderEditor(step: step)
            }

            Section("Notes") {
                TextField(
                    "Optional Note",
                    text: Binding(
                        get: { step.notes ?? "" },
                        set: { step.notes = $0.isEmpty ? nil : $0 }
                    ),
                    axis: .vertical
                )
            }
            .listRowBackground(Color.doughBeige)
        }
        .navigationTitle(step.displayTitle)
        .scrollContentBackground(.hidden)
        .background(Color.flourCream)
        .tint(.sourdoughBrown)
        .listStyle(.insetGrouped)
        .listRowBackground(Color.doughBeige)
    }

    @ViewBuilder
    private var foldConfigurationSection: some View {
        if let fold = step.foldReminderConfiguration {
            FoldReminderEditor(fold: fold, bulkDuration: step.effectiveDuration)
        } else {
            Section {
                    Button("Set up fold reminders") {
                    let fold = FoldReminderConfiguration()
                    step.foldReminderConfiguration = fold
                    fold.step = step
                }
            }
        }
    }

    private var targetDurationBinding: Binding<TimeInterval> {
        Binding(
            get: { step.duration ?? 0 },
            set: { step.duration = $0 }
        )
    }

    private var minimumBinding: Binding<TimeInterval> {
        Binding(
            get: { step.minimumDuration ?? 0 },
            set: { step.minimumDuration = $0 }
        )
    }

    private var maximumBinding: Binding<TimeInterval> {
        Binding(
            get: { step.maximumDuration ?? 0 },
            set: { step.maximumDuration = $0 }
        )
    }

    private var temperatureBinding: Binding<Int> {
        Binding(
            get: { step.temperatureCelsius ?? 230 },
            set: { step.temperatureCelsius = $0 }
        )
    }
}

/// Editor for the sub-timers of a step (e.g. preheat or lid removal).
struct ReminderEditor: View {
    @Bindable var step: BakeStepDefinition
    @Environment(\.modelContext) private var modelContext

    private var timers: [ReminderDefinition] {
        step.sortedReminders
    }

    var body: some View {
        Section {
            ForEach(timers) { timer in
                ReminderRow(timer: timer, stepDuration: step.effectiveDuration)
            }
            .onDelete(perform: delete)
            .onMove(perform: move)

            Button("Add reminder") {
                addReminder()
            }
        } header: {
            Text("Reminders")
        } footer: {
            Text("Reminders during this step, such as preheating the oven or removing the lid.")
        }
        .listRowBackground(Color.doughBeige)
    }

    private func addReminder() {
        let newTimer = ReminderDefinition(
            title: String(localized: "New reminder"),
            offset: min(5 * 60, step.effectiveDuration),
            sortIndex: timers.count,
            triggerMode: timers.isEmpty ? .afterStepStart : .afterPreviousReminder
        )
        step.reminders = (step.reminders ?? []) + [newTimer]
        newTimer.step = step
    }

    private func delete(at offsets: IndexSet) {
        let sorted = timers
        for index in offsets {
            if index < sorted.count {
                modelContext.delete(sorted[index])
            }
        }
        reindex()
    }

    private func move(from source: IndexSet, to destination: Int) {
        var sorted = timers
        sorted.move(fromOffsets: source, toOffset: destination)
        for (index, timer) in sorted.enumerated() {
            timer.sortIndex = index
        }
    }

    private func reindex() {
        for (index, timer) in step.sortedReminders.enumerated() {
            timer.sortIndex = index
        }
    }
}

struct ReminderRow: View {
    @Bindable var timer: ReminderDefinition
    let stepDuration: TimeInterval

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker("Type", selection: $timer.type) {
                ForEach(ReminderType.allCases) { type in
                    Text(type.defaultTitle).tag(type)
                }
            }

            if timer.type == .custom {
                TextField("Name", text: $timer.title)
            }

            if timer.type == .lowerTemperature {
                Stepper(value: temperatureBinding, in: 100...300, step: 5) {
                    LabeledContent("Temperature", value: "\(timer.targetTemperatureCelsius ?? 220) °C")
                }
            }

            Picker("When", selection: $timer.triggerMode) {
                ForEach(ReminderTriggerMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }

            LabeledContent(timer.triggerMode == .beforeStepEnd ? "Before This Step Ends" : "After") {
                DurationPickerView(interval: $timer.offset, maximumHours: max(12, Int(stepDuration / 3600) + 1))
                    .frame(width: 220)
            }
        }
        .padding(.vertical, 4)
    }

    private var temperatureBinding: Binding<Int> {
        Binding(
            get: { timer.targetTemperatureCelsius ?? 220 },
            set: { timer.targetTemperatureCelsius = $0 }
        )
    }
}

extension BakeStepDefinition {
    var displayTitle: String {
        if !title.isEmpty { return title }
        return type.localizedTitle
    }
}

extension BakeStepType {
    var localizedTitle: String {
        switch self {
        case .autolyse: String(localized: "Autolyse")
        case .mix: String(localized: "Mix Ingredients")
        case .kneading: String(localized: "Kneading")
        case .bulkRoomTemperature: String(localized: "Bulk Fermentation")
        case .bulkCold: String(localized: "Cold Bulk (Fridge)")
        case .benchRest: String(localized: "Bench Rest")
        case .shaping: String(localized: "Shape Loaf")
        case .finalProofRoomTemperature: String(localized: "Final Proof")
        case .coldFinalProof: String(localized: "Cold Final Proof (Fridge)")
        case .bake: String(localized: "Bake")
        case .cooling: String(localized: "Cooling")
        case .custom: String(localized: "Custom Step")
        }
    }
}

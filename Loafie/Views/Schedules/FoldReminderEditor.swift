import SwiftUI

/// Editor for the "x times every n minutes" fold configuration of one bulk step.
struct FoldReminderEditor: View {
    @Bindable var fold: FoldReminderConfiguration
    let bulkDuration: TimeInterval

    private var isValid: Bool {
        FoldReminderCalculator.isValid(
            isEnabled: fold.isEnabled,
            repetitions: fold.repetitions,
            interval: fold.interval,
            firstReminderOffset: fold.firstReminderOffset,
            bulkDuration: bulkDuration
        )
    }

    var body: some View {
        Section {
            Toggle("Stretch-and-fold reminders", isOn: $fold.isEnabled)
        }
        .listRowBackground(Color.doughBeige)

        if fold.isEnabled {
            Section {
                Picker("Technique", selection: $fold.technique) {
                    Text("Stretch & fold").tag(FoldTechnique.stretchAndFold)
                    Text("Coil fold").tag(FoldTechnique.coilFold)
                    Text("Custom").tag(FoldTechnique.custom)
                }
                if fold.technique == .custom {
                    TextField(
                        "Technique Name",
                        text: Binding(
                            get: { fold.customTechniqueName ?? "" },
                            set: { fold.customTechniqueName = $0 }
                        )
                    )
                }

                Stepper(value: $fold.repetitions, in: 0...12) {
                    LabeledContent("Number of folds", value: "\(fold.repetitions)×")
                }

                Picker("Interval", selection: $fold.interval) {
                    ForEach(Array(stride(from: 5, through: 180, by: 5)), id: \.self) { minute in
                        Text("\(minute) min").tag(TimeInterval(minute * 60))
                    }
                }

                LabeledContent("First fold after") {
                    DurationPickerView(interval: $fold.firstReminderOffset, maximumHours: 12)
                        .frame(width: 220)
                }

                if fold.repetitions > 0 {
                    LabeledContent("Summary") {
                        Text(summary)
                            .foregroundStyle(.secondary)
                    }
                }
            } footer: {
                if !isValid {
                        Text("Move the last fold earlier so all folds happen during bulk fermentation.")
                        .foregroundStyle(.red)
                }
            }
            .listRowBackground(Color.doughBeige)
        }
    }

    private var summary: String {
        String(localized: "\(fold.repetitions)× every \(Int(fold.interval / 60)) min")
    }
}

import SwiftUI

/// Hours/minutes picker for durations. Minutes in 5-minute steps.
struct DurationPickerView: View {
    @Binding var interval: TimeInterval
    var maximumHours: Int = 48

    private var hours: Binding<Int> {
        Binding(
            get: { Int(interval) / 3600 },
            set: { interval = TimeInterval($0 * 3600 + minutes.wrappedValue * 60) }
        )
    }

    private var minutes: Binding<Int> {
        Binding(
            get: { (Int(interval) % 3600) / 60 },
            set: { interval = TimeInterval(hours.wrappedValue * 3600 + $0 * 60) }
        )
    }

    var body: some View {
        HStack(spacing: 0) {
            Picker("Hours", selection: hours) {
                ForEach(0...maximumHours, id: \.self) { hour in
                    Text("\(hour) h").tag(hour)
                }
            }
            .pickerStyle(.wheel)
            .frame(maxWidth: .infinity)
            .clipped()

            Picker("Minutes", selection: minutes) {
                ForEach(Array(stride(from: 0, through: 55, by: 5)), id: \.self) { minute in
                    Text("\(minute) min").tag(minute)
                }
            }
            .pickerStyle(.wheel)
            .frame(maxWidth: .infinity)
            .clipped()
        }
        .frame(height: 120)
    }
}

/// Minute-only duration picker for short steps such as kneading.
struct MinuteDurationPickerView: View {
    @Binding var interval: TimeInterval
    var range: ClosedRange<Int> = 1...180

    private var minutes: Binding<Int> {
        Binding(
            get: { max(range.lowerBound, min(range.upperBound, Int(interval / 60))) },
            set: { interval = TimeInterval($0 * 60) }
        )
    }

    var body: some View {
        Picker("Minutes", selection: minutes) {
            ForEach(range, id: \.self) { minute in
                Text("\(minute) min").tag(minute)
            }
        }
        .pickerStyle(.wheel)
        .frame(maxWidth: .infinity)
        .clipped()
        .frame(height: 120)
    }
}

#Preview {
    @Previewable @State var interval: TimeInterval = 90 * 60
    return DurationPickerView(interval: $interval)
}

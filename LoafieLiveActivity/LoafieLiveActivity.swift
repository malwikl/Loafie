import ActivityKit
import Foundation
import SwiftUI
import WidgetKit

private extension Color {
    static let crustGold = Color(red: 0.831, green: 0.647, blue: 0.455)
    static let doughBeige = Color(red: 0.176, green: 0.157, blue: 0.141)
    static let lightText = Color(red: 0.910, green: 0.910, blue: 0.910)
}

struct LoafieLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LoafieLiveActivityAttributes.self) { context in
            LoafieLiveActivityLockScreenView(context: context)
                .activityBackgroundTint(Color.doughBeige)
                .activitySystemActionForegroundColor(Color.crustGold)
                .widgetURL(sessionURL(for: context))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    expandedLeadingView(context)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    expandedTrailingView(context)
                }
            } compactLeading: {
                Image(systemName: compactSymbolName(for: context))
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color.crustGold)
                    .accessibilityLabel(compactAccessibilityLabel(for: context))
            } compactTrailing: {
                compactTrailingView(context)
            } minimal: {
                compactTrailingView(context)
            }
        }
    }

    private func sessionURL(
        for context: ActivityViewContext<LoafieLiveActivityAttributes>
    ) -> URL? {
        URL(string: "loafie://session/\(context.attributes.sessionID)")
    }

    @ViewBuilder
    private func expandedLeadingView(
        _ context: ActivityViewContext<LoafieLiveActivityAttributes>
    ) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            if context.state.presentation == .waitingForNextStep,
               let completedStepTitle = context.state.completedStepTitle {
                Text(String(localized: "Step finished"))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.crustGold)
                Text(completedStepTitle)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.lightText)
                    .lineLimit(1)
            } else {
                Text(context.state.stepTitle)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.lightText)
                    .lineLimit(1)
                Text(statusLabel(for: context))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.crustGold)
            }
        }
    }

    @ViewBuilder
    private func expandedTrailingView(
        _ context: ActivityViewContext<LoafieLiveActivityAttributes>
    ) -> some View {
        switch context.state.presentation {
        case .timed:
            endTimeView(context)
        case .manual:
            Image(systemName: "hand.raised.fill")
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.crustGold)
        case .waitingForNextStep:
            Image(systemName: "checkmark.circle.fill")
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.crustGold)
        }
    }

    @ViewBuilder
    private func compactTrailingView(
        _ context: ActivityViewContext<LoafieLiveActivityAttributes>
    ) -> some View {
        if context.state.presentation == .timed {
            compactEndTime(context)
        } else {
            Image(systemName: context.state.presentation == .manual ? "hand.raised.fill" : "checkmark")
                .font(.caption2.weight(.bold))
                .foregroundStyle(Color.crustGold)
        }
    }

    private func compactSymbolName(
        for context: ActivityViewContext<LoafieLiveActivityAttributes>
    ) -> String {
        if context.state.isPaused {
            return "pause.circle.fill"
        }
        if context.state.presentation == .waitingForNextStep {
            return "checkmark.circle.fill"
        }
        if context.state.presentation == .manual {
            return "hand.raised.fill"
        }
        return "bread.slices.fill"
    }

    private func compactAccessibilityLabel(
        for context: ActivityViewContext<LoafieLiveActivityAttributes>
    ) -> String {
        if context.state.isPaused {
            return String(localized: "Paused")
        }
        return context.state.stepTitle
    }

    private func statusLabel(
        for context: ActivityViewContext<LoafieLiveActivityAttributes>
    ) -> String {
        if context.state.isPaused {
            return String(localized: "Paused")
        }
        if context.state.presentation == .manual {
            return String(localized: "No timer for this step")
        }
        return ""
    }

    @ViewBuilder
    private func endTimeView(_ context: ActivityViewContext<LoafieLiveActivityAttributes>) -> some View {
        if let endDate = context.state.stepEndDate {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(endDate < Date() ? String(localized: "Overdue") : String(localized: "Until"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.lightText.opacity(0.72))
                Text(endDate, format: .dateTime.hour().minute())
                    .font(.title2.weight(.bold))
                    .monospacedDigit()
                    .foregroundStyle(Color.crustGold)
            }
        } else {
            Text("—")
                .font(.title2.weight(.bold))
                .foregroundStyle(Color.crustGold)
        }
    }

    @ViewBuilder
    private func compactEndTime(_ context: ActivityViewContext<LoafieLiveActivityAttributes>) -> some View {
        if let endDate = context.state.stepEndDate {
            Text(endDate, format: .dateTime.hour().minute())
                .font(.caption2.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(Color.crustGold)
        } else {
            Text("—")
                .font(.caption2.weight(.bold))
                .foregroundStyle(Color.crustGold)
        }
    }
}

struct LoafieLiveActivityLockScreenView: View {
    let context: ActivityViewContext<LoafieLiveActivityAttributes>

    var body: some View {
        Group {
            switch context.state.presentation {
            case .timed:
                timedStepView
            case .manual:
                manualStepView
            case .waitingForNextStep:
                waitingForNextStepView
            }
        }
        .padding()
    }

    private var timedStepView: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .firstTextBaseline, spacing: 16) {
                Text(context.state.stepTitle)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.lightText)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)

                Spacer(minLength: 12)

                endTimeView
            }

            if hasNextReminder {
                Divider()
                    .overlay(Color.lightText.opacity(0.18))

                nextReminderView
            }
        }
    }

    private var manualStepView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(context.state.stepTitle)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.lightText)
                .lineLimit(2)

            Text(String(localized: "No timer for this step"))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.crustGold)

            if let instructions = context.state.stepInstructions, !instructions.isEmpty {
                Text(instructions)
                    .font(.subheadline)
                    .foregroundStyle(Color.lightText.opacity(0.82))
                    .lineLimit(2)
            }

            Label("Open Loafie to continue", systemImage: "arrow.right.circle")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.lightText.opacity(0.72))
        }
    }

    private var waitingForNextStepView: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let completedStepTitle = context.state.completedStepTitle {
                Label("\(completedStepTitle) · \(String(localized: "Step finished"))", systemImage: "checkmark.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.crustGold)
                    .lineLimit(1)
            }

            Text(String(localized: "Next: \(context.state.stepTitle)"))
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.lightText)
                .lineLimit(2)

            if let instructions = context.state.stepInstructions, !instructions.isEmpty {
                Text(instructions)
                    .font(.subheadline)
                    .foregroundStyle(Color.lightText.opacity(0.82))
                    .lineLimit(2)
            }

            Label("Open Loafie to continue", systemImage: "arrow.right.circle")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.lightText.opacity(0.72))
        }
    }

    private var hasNextReminder: Bool {
        context.state.nextReminderDate != nil || context.state.nextReminderSeconds != nil
    }

    private var nextReminderView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(String(localized: "Next reminder"))
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.lightText.opacity(0.72))

            HStack(spacing: 8) {
                Image(systemName: context.state.nextReminderIsFold == true ? "hands.clap.fill" : "timer")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.crustGold)
                    .accessibilityHidden(true)

                nextReminderTitle
                    .font(.headline)
                    .foregroundStyle(Color.lightText)
                    .lineLimit(1)

                Spacer(minLength: 8)

                reminderCountdown
                    .font(.subheadline.weight(.bold))
                    .monospacedDigit()
                    .foregroundStyle(Color.crustGold)
            }
        }
    }

    @ViewBuilder
    private var nextReminderTitle: some View {
        if context.state.nextReminderIsFold == true, let number = context.state.nextFoldNumber {
            Text(String(localized: "Fold · round \(number)"))
        } else if let title = context.state.nextReminderTitle {
            Text(title)
        }
    }

    @ViewBuilder
    private var reminderCountdown: some View {
        if context.state.isPaused {
            Text(String(localized: "in \(countdownString(from: context.state.nextReminderSeconds ?? 0))"))
        } else if let date = context.state.nextReminderDate {
            TimelineView(.periodic(from: .now, by: 60)) { timeline in
                Text(String(localized: "in \(countdownString(from: date.timeIntervalSince(timeline.date)))"))
            }
        } else if let seconds = context.state.nextReminderSeconds {
            Text(String(localized: "in \(countdownString(from: seconds))"))
        }
    }

    @ViewBuilder
    private var endTimeView: some View {
        if let endDate = context.state.stepEndDate {
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text(endDate < Date() ? String(localized: "Overdue") : String(localized: "Until"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.lightText.opacity(0.72))
                Text(endDate, format: .dateTime.hour().minute())
                    .font(.largeTitle.weight(.bold))
                    .monospacedDigit()
                    .foregroundStyle(Color.crustGold)
            }
        } else {
            Text("—")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(Color.crustGold)
        }
    }

    private func countdownString(from seconds: Double) -> String {
        let totalMinutes = max(0, Int(seconds) / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return String(format: "%02dh %02dm", hours, minutes)
    }
}

import SwiftUI

private extension Color {
    static let crustGold = Color(red: 0.831, green: 0.647, blue: 0.455)
    static let sourdoughBrown = Color(red: 0.545, green: 0.369, blue: 0.235)
    static let doughBeige = Color(red: 0.910, green: 0.878, blue: 0.835)
}

struct WatchSessionView: View {
    let snapshot: WatchSessionSnapshot
    @ObservedObject var model: WatchSessionModel

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let step = snapshot.step {
                    Image(systemName: step.symbolName)
                        .font(.title2)
                        .foregroundStyle(Color.crustGold)
                    Text(step.title)
                        .font(.headline)
                    if let targetDate = step.targetDate {
                        VStack(spacing: 2) {
                            Text("Expected finish")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(targetDate, format: .dateTime.hour().minute())
                                .font(.system(.title2, design: .monospaced).weight(.light))
                                .foregroundStyle(Color.crustGold)
                        }
                    } else {
                        Text("No timer for this step")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let next = step.nextStepTitle {
                        Text("Next: \(next)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    ActionButtons(step: step, model: model)

                    if let fold = step.foldReminder {
                        FoldReminderWatchView(fold: fold, model: model, allowed: step.allowedActions)
                    }
                } else {
                    Text("Waiting for the next step")
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    private func remainingText(for step: WatchStepSnapshot) -> String {
        if step.status == "paused" {
            return "Paused"
        }
        if step.isColdStep, let coldState = step.coldState {
            switch coldState {
            case "running": return "Noch nicht bereit"
            case "earliestReady": return "Frühestens bereit"
            case "bakeReady": return "Empfohlen bereit"
            case "exceededMaximum": return "Zeitfenster überschritten"
            default: break
            }
        }
        let seconds = Int(max(0, step.remainingSeconds))
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%02d:%02d", m, s)
    }
}

struct ActionButtons: View {
    let step: WatchStepSnapshot
    @ObservedObject var model: WatchSessionModel

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                if step.allowedActions.contains(WatchAction.togglePause.rawValue) {
                    Button(step.status == "paused" ? "Resume" : "Pause") {
                        model.sendAction(.togglePause)
                    }
                }
                if step.allowedActions.contains(WatchAction.completeStep.rawValue) {
                    Button("Done") {
                        model.sendAction(.completeStep)
                    }
                    .tint(Color.sourdoughBrown)
                }
            }
            if step.allowedActions.contains(WatchAction.extendStep.rawValue) {
                Button("+5 min") {
                    model.sendAction(.extendStep, payload: ["seconds": 5 * 60])
                }
            }
        }
    }
}

struct FoldReminderWatchView: View {
    let fold: WatchFoldReminderSnapshot
    @ObservedObject var model: WatchSessionModel
    let allowed: [String]

    var body: some View {
        VStack(spacing: 12) {
            Text("Round \(fold.number) of \(fold.total)")
                .font(.caption)
                .foregroundStyle(Color.crustGold)
            HStack {
                Button("Done") {
                    model.sendAction(.completeFoldReminder, payload: ["foldReminderID": fold.id])
                }
                Button("+10") {
                    model.sendAction(.postponeFoldReminder, payload: ["foldReminderID": fold.id])
                }
            }
        }
        .padding(12)
        .background(Color.doughBeige.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

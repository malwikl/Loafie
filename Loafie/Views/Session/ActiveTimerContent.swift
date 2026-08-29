import SwiftUI

/// The running timer screen has one scroll container. This keeps the current
/// phase and its schedule in the same natural scroll flow.
struct ActiveTimerContent: View {
    let session: BakeSession
    let notificationWarning: TimerNotificationWarning?
    let adjustTimer: () -> Void

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if let notificationWarning {
                    TimerNotificationWarningView(warning: notificationWarning)
                        .padding(.top, 8)
                }

                CurrentPhaseCard(session: session, adjustTimer: adjustTimer)
                    .padding(.horizontal, LoafieDesign.screenPadding)
                    .padding(.vertical, 12)

                Divider()

                ScheduleTimeline(session: session)
            }
            .padding(.bottom, 16)
        }
        .scrollIndicators(.hidden)
        .background(Color.flourCream)
    }
}

struct TimerNotificationWarning {
    let message: String
    let systemImage: String
}

private struct TimerNotificationWarningView: View {
    let warning: TimerNotificationWarning

    var body: some View {
        Label(warning.message, systemImage: warning.systemImage)
            .font(.subheadline)
            .foregroundStyle(.orange)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.timerPaused.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
    }
}

private struct CurrentPhaseCard: View {
    @Environment(SessionStore.self) private var sessionStore

    let session: BakeSession
    let adjustTimer: () -> Void

    var body: some View {
        if let step = session.activeStep {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    stepIcon(for: step.type)
                        .font(.title2)
                        .foregroundStyle(Color.sourdoughBrown)
                        .frame(width: 30)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(step.displayTitle)
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(Color.sourdoughBrown)
                        if step.isManualStep {
                            Label("Manual step", systemImage: "hand.raised.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.sourdoughBrown)
                        } else if session.status == .paused {
                            Label("Paused", systemImage: "pause.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.timerPaused)
                        }
                    }
                    Spacer()
                    StepNotesButton(notes: step.notes, stepTitle: step.displayTitle)
                }

                if !step.isManualStep {
                    TimerReadoutView(step: step, session: session)
                    ColdStepStatusView(step: step, session: session)
                }

                ManualStepGuidanceView(step: step)
                ReminderChecklistView(step: step)
                FoldChecklistView(step: step)
                phaseActions(for: step)
            }
            .loafieCard()
            .accessibilityElement(children: .contain)
        } else if let next = session.sortedSteps.first(where: { $0.status == .pending }) {
            VStack(alignment: .leading, spacing: 12) {
                Label("Ready for the next phase", systemImage: "arrow.right.circle.fill")
                    .font(.headline)
                Text(next.displayTitle)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.sourdoughBrown)
                Button {
                    Haptics.impact(.medium)
                    sessionStore.startNextStep(session)
                } label: {
                    Label("Start step", systemImage: "play.fill")
                }
                .buttonStyle(LoafiePrimaryButtonStyle())
            }
            .loafieCard()
        }
    }

    @ViewBuilder
    private func phaseActions(for step: SessionStep) -> some View {
        Button {
            Haptics.impact(.medium)
            sessionStore.completeActiveStep(session)
        } label: {
            Label("Complete step", systemImage: "checkmark")
        }
        .buttonStyle(LoafiePrimaryButtonStyle())

        if !step.isManualStep {
            HStack(spacing: 10) {
                Button {
                    Haptics.impact(.light)
                    if session.status == .active {
                        sessionStore.pause(session)
                    } else {
                        sessionStore.resume(session)
                    }
                } label: {
                    Label(session.status == .active ? "Pause" : "Resume", systemImage: session.status == .active ? "pause.fill" : "play.fill")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(LoafieSecondaryButtonStyle())

                Button(action: adjustTimer) {
                    Label("Adjust timer", systemImage: "slider.horizontal.3")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(LoafieSecondaryButtonStyle())
                .disabled(session.status != .active)
                .accessibilityHint(session.status == .active ? "Choose a new end time" : "Resume the timer before changing its end time")
            }
        }
    }
}

private struct ScheduleTimeline: View {
    let session: BakeSession

    private var projections: [StepProjection] {
        TimelineCalculator.projections(for: session)
    }

    private var timelineSteps: [SessionStep] {
        session.sortedSteps.filter { $0.id != session.activeStep?.id }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Your schedule")
                    .font(.headline)
            }
            .padding(.horizontal, LoafieDesign.screenPadding)
            .padding(.vertical, 12)

            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(timelineSteps) { step in
                    if let projection = projections.first(where: { $0.stepID == step.id }) {
                        TimelineRow(step: step, projection: projection)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 10)
                            .padding(.horizontal, LoafieDesign.screenPadding)
                        Divider()
                            .padding(.leading, LoafieDesign.screenPadding + 40)
                    }
                }
            }
        }
    }
}

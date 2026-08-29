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
    @State private var showTimerAdjustment = false
    @State private var showColdWindowStartError = false

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
            .sheet(isPresented: $showTimerAdjustment) {
                if let session = runningSession, let step = session.activeStep {
                    TimerAdjustmentSheet(session: session, step: step)
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
                    if sessionStore.startPlannedSession(session) == .blockedByColdWindow {
                        showColdWindowStartError = true
                    }
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
        .alert("Cannot start at this time", isPresented: $showColdWindowStartError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("The planned target time cannot be kept with a fridge duration inside the recommended minimum and maximum.")
        }
        .modifier(TimerNavigationChrome())
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
        .modifier(TimerNavigationChrome())
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
        ActiveTimerContent(
            session: session,
            notificationWarning: notificationWarning,
            adjustTimer: { showTimerAdjustment = true }
        )
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
        .modifier(TimerNavigationChrome())
    }

    private var notificationWarning: TimerNotificationWarning? {
        guard notificationService.authorizationDenied || notificationService.lastSchedulingError != nil else {
            return nil
        }
        return TimerNotificationWarning(
            message: notificationService.lastSchedulingError ?? "Notifications disabled — reminders won't appear.",
            systemImage: notificationService.lastSchedulingError == nil ? "bell.slash.fill" : "exclamationmark.triangle.fill"
        )
    }
}

/// Applies navigation state directly to each concrete screen root. Applying it
/// to the conditional `Group` can leave the large title without a scroll host.
private struct TimerNavigationChrome: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .navigationTitle("Timer")
            .navigationBarTitleDisplayMode(.large)
            .background(Color.flourCream.ignoresSafeArea())
            .tint(.sourdoughBrown)
            .toolbarBackground(Color.flourCream, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
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

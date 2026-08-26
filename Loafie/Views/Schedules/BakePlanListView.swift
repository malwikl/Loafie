import SwiftUI
import SwiftData

struct BakePlanListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BakePlan.updatedAt, order: .reverse) private var bakePlans: [BakePlan]
    @Query private var sessions: [BakeSession]

    @State private var bakePlanToDelete: BakePlan?
    @State private var selectedBakePlan: BakePlan?
    @State private var newBakePlan: BakePlan?
    @State private var showingDeleteAlert = false

    private var hasRunningSession: Bool {
        sessions.contains { $0.status.isRunning }
    }

    var body: some View {
        NavigationStack {
            Group {
                if bakePlans.isEmpty {
                    emptyState
                } else {
                    bakePlanList
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .navigationTitle("Bake plans")
            .navigationBarTitleDisplayMode(.large)
            .scrollContentBackground(.hidden)
            .background(Color.flourCream)
            .tint(.sourdoughBrown)
            .toolbarBackground(Color.flourCream, for: .navigationBar)
            .navigationDestination(item: $selectedBakePlan) { bakePlan in
                BakePlanEditView(bakePlan: bakePlan)
            }
            .sheet(item: $newBakePlan) { bakePlan in
                NavigationStack {
                    BakePlanEditView(
                        bakePlan: bakePlan,
                        onStarted: {
                            newBakePlan = nil
                        },
                        onDone: {
                            newBakePlan = nil
                        },
                        onCancelled: {
                            modelContext.delete(bakePlan)
                            newBakePlan = nil
                        }
                    )
                }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        createBakePlan()
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 17, weight: .bold))
                    }
                    .accessibilityLabel("New Bake Plan")
                }
            }
            .alert(
                "Delete Bake Plan?",
                isPresented: $showingDeleteAlert,
            ) {
                Button("Delete", role: .destructive) {
                    if let bakePlanToDelete {
                        modelContext.delete(bakePlanToDelete)
                    }
                    bakePlanToDelete = nil
                }
                Button("Cancel", role: .cancel) {
                    bakePlanToDelete = nil
                }
            } message: {
                if bakePlanToDelete.map({ hasRunningSession(for: $0) }) == true {
                        Text("This bake plan has an active baking session. The session will be kept as a snapshot.")
                } else {
                    Text("This cannot be undone.")
                }
            }
        }
    }

    private var emptyState: some View {
        EmptyStateView(
            systemImage: "calendar.badge.plus",
            title: "No bake plans yet",
            message: "A bake plan is a reusable sequence of steps and reminders for one bake.",
            actionTitle: "Create bake plan"
        ) {
            createBakePlan()
        }
    }

    private var bakePlanList: some View {
        List {
            ForEach(bakePlans) { bakePlan in
                Button {
                    selectedBakePlan = bakePlan
                } label: {
                    BakePlanRowView(bakePlan: bakePlan)
                }
                .buttonStyle(.plain)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        bakePlanToDelete = bakePlan
                        showingDeleteAlert = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    Button {
                        duplicate(bakePlan)
                    } label: {
                        Label("Duplicate", systemImage: "plus.square.on.square")
                    }
                    .tint(.secondary)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.flourCream)
        .safeAreaPadding(.horizontal, LoafieDesign.screenPadding - 4)
        .safeAreaPadding(.vertical, 8)
    }

    private func hasRunningSession(for bakePlan: BakePlan) -> Bool {
        sessions.contains { $0.bakePlanID == bakePlan.id && $0.status.isRunning }
    }

    private func duplicate(_ bakePlan: BakePlan) {
        let copy = BakePlan(
            name: bakePlan.name + " (Copy)",
            timing: bakePlan.timing,
            autoAdvanceSteps: bakePlan.autoAdvanceSteps
        )
        for step in bakePlan.sortedSteps {
            let reminderCopies = step.sortedReminders.map {
                ReminderDefinition(
                    title: $0.title,
                    offset: $0.offset,
                    sortIndex: $0.sortIndex,
                    type: $0.type,
                    triggerMode: $0.triggerMode,
                    targetTemperatureCelsius: $0.targetTemperatureCelsius
                )
            }
            let stepCopy = BakeStepDefinition(
                type: step.type,
                title: step.title,
                duration: step.duration,
                minimumDuration: step.minimumDuration,
                maximumDuration: step.maximumDuration,
                temperatureCelsius: step.temperatureCelsius,
                isEnabled: step.isEnabled,
                notes: step.notes,
                sortIndex: step.sortIndex,
                foldReminderConfiguration: step.foldReminderConfiguration.map {
                    FoldReminderConfiguration(
                        isEnabled: $0.isEnabled,
                        technique: $0.technique,
                        customTechniqueName: $0.customTechniqueName,
                        repetitions: $0.repetitions,
                        interval: $0.interval,
                        firstReminderOffset: $0.firstReminderOffset
                    )
                },
                reminders: reminderCopies
            )
            stepCopy.bakePlan = copy
            stepCopy.foldReminderConfiguration?.step = stepCopy
            for reminder in reminderCopies {
                reminder.step = stepCopy
            }
            copy.steps.append(stepCopy)
        }
        modelContext.insert(copy)
    }

    private func createBakePlan() {
        let bakePlan = BakePlanTemplates.makeBakePlan(
            name: String(localized: "New bake plan"),
            timing: .sameDay
        )
        modelContext.insert(bakePlan)
        newBakePlan = bakePlan
    }
}

struct BakePlanRowView: View {
    let bakePlan: BakePlan

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(bakePlan.name)
                    .font(.headline)
                HStack(spacing: 8) {
                    Label(timingName, systemImage: timingSymbol)
                    Text("·")
                    Text(DurationFormatter.string(from: bakePlan.typicalDuration))
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.secondary.opacity(0.55))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .loafieCard()
    }

    private var timingName: String {
        switch bakePlan.timing {
        case .sameDay: String(localized: "Same day")
        case .coldFinalProof: String(localized: "Overnight — cold proof")
        case .coldBulk: String(localized: "Cold bulk fermentation — advanced")
        }
    }

    private var timingSymbol: String {
        switch bakePlan.timing {
        case .sameDay: "sun.max.fill"
        case .coldFinalProof: "moon.fill"
        case .coldBulk: "snowflake"
        }
    }
}

#Preview {
    BakePlanListView()
        .modelContainer(for: [
            BakePlan.self,
            BakeStepDefinition.self,
            FoldReminderConfiguration.self,
            ReminderDefinition.self,
            BakeSession.self,
            SessionStep.self,
            SessionFoldReminder.self,
            SessionReminder.self,
        ], inMemory: true)
}

import SwiftUI
import SwiftData

struct RootTabView: View {
    @Environment(SessionStore.self) private var sessionStore
    @Environment(AppNavigationState.self) private var navigationState
    @State private var selection = Tab.bakePlans

    var body: some View {
        TabView(selection: $selection) {
            BakePlanListView()
                .tabItem {
                    Label("Bake plans", systemImage: "list.bullet.rectangle")
                }
                .tag(Tab.bakePlans)
            ActiveSessionView()
                .tabItem {
                    Label("Timer", systemImage: "timer")
                }
                .tag(Tab.timer)
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(Tab.settings)
        }
        .tint(.sourdoughBrown)
        .background(Color.flourCream.ignoresSafeArea())
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .onAppear {
            if sessionStore.currentSession() != nil {
                selection = .timer
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .sessionDidChange)) { _ in
            if sessionStore.currentSession() != nil {
                selection = .timer
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .plannedSessionStartRequested)) { notification in
            guard let id = notification.object as? UUID,
                  let session = sessionStore.currentSession(), session.id == id else { return }
            sessionStore.startPlannedSession(session)
            selection = .timer
        }
        .onReceive(NotificationCenter.default.publisher(for: .sessionNotificationOpened)) { notification in
            guard let id = notification.object as? UUID,
                  let session = sessionStore.runningSession(), session.id == id else { return }
            selection = .timer
        }
        .onChange(of: navigationState.requestedTimerSessionID, initial: true) { _, sessionID in
            guard sessionID != nil else { return }
            selection = .timer
        }
    }

    private enum Tab: Hashable {
        case bakePlans
        case timer
        case settings
    }
}

#Preview {
    RootTabView()
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

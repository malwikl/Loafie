import SwiftUI
import SwiftData
import AppIntents

@main
struct LoafieApp: App {
    @Environment(\.scenePhase) private var scenePhase
    let sharedModelContainer: ModelContainer
    let settingsStore: SettingsStore
    let notificationService: NotificationService
    let sessionStore: SessionStore
    let liveActivityService: LiveActivityService
    let watchSessionManager: WatchSessionManager
    let navigationState: AppNavigationState

    init() {
        let schema = Schema([
            BakePlan.self,
            BakeStepDefinition.self,
            FoldReminderConfiguration.self,
            ReminderDefinition.self,
            BakeSession.self,
            SessionStep.self,
            SessionFoldReminder.self,
            SessionReminder.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        let modelContainer: ModelContainer
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }

        let createdSettingsStore = SettingsStore()
        let createdNotificationService = NotificationService(settings: createdSettingsStore)
        let createdSessionStore = SessionStore(
            modelContext: modelContainer.mainContext,
            notificationService: createdNotificationService,
            liveActivityService: nil,
            settings: createdSettingsStore
        )
        let createdLiveActivityService = LiveActivityService(runningSessionProvider: { [weak createdSessionStore] in
            createdSessionStore?.runningSession()
        })
        createdSessionStore.liveActivityService = createdLiveActivityService
        let createdWatchSessionManager = WatchSessionManager(sessionStore: createdSessionStore)
        let createdNavigationState = AppNavigationState()

        sharedModelContainer = modelContainer
        settingsStore = createdSettingsStore
        notificationService = createdNotificationService
        sessionStore = createdSessionStore
        liveActivityService = createdLiveActivityService
        watchSessionManager = createdWatchSessionManager
        navigationState = createdNavigationState

        createdWatchSessionManager.activate()
        AppDependencyManager.shared.add(dependency: createdSessionStore)
        AppDependencyManager.shared.add(dependency: createdNavigationState)

        // Restore a Live Activity if the app is relaunched while a bake is running.
        if let runningSession = createdSessionStore.runningSession() {
            createdLiveActivityService.startOrUpdate(for: runningSession)
        } else {
            createdLiveActivityService.endAll()
        }
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(sessionStore)
                .environment(settingsStore)
                .environment(notificationService)
                .environment(navigationState)
                .onOpenURL(perform: handleOpenURL)
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        sessionStore.reconcileAfterLifecycleChange()
                        notificationService.refreshAuthorizationState()
                        liveActivityService.refreshNow()
                    }
                }
        }
        .modelContainer(sharedModelContainer)
    }

    private func handleOpenURL(_ url: URL) {
        let path = url.pathComponents.filter { $0 != "/" }
        let sessionID: UUID?
        if url.scheme == "https", url.host == "loafie.kloeffer.de", path.first == "timer" {
            sessionID = path.dropFirst().first.flatMap(UUID.init(uuidString:))
        } else if url.scheme == "loafie", url.host == "session" {
            sessionID = path.first.flatMap(UUID.init(uuidString:))
        } else {
            sessionID = nil
        }
        guard let sessionID else { return }
        // Retain the request during a cold launch so the tab selection is not lost.
        navigationState.openTimer(for: sessionID)
    }
}

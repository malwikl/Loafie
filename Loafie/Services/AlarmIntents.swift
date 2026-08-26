import AppIntents
import Foundation

@available(iOS 26.0, *)
struct OpenLoafieTimerIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Open Timer"
    static var description = IntentDescription("Opens the current baking timer in Loafie.")
    static var supportedModes: IntentModes { .foreground(.immediate) }

    @Parameter(title: "Session ID")
    var sessionID: String

    @Dependency private var navigationState: AppNavigationState

    init() {
        sessionID = ""
    }

    init(sessionID: UUID) {
        self.sessionID = sessionID.uuidString
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        guard let sessionID = UUID(uuidString: sessionID) else { return .result() }
        navigationState.openTimer(for: sessionID)
        return .result()
    }
}

@available(iOS 26.0, *)
struct ExtendCurrentStepIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Add 10 min"
    static var description = IntentDescription("Adds ten minutes to the current baking step.")
    static var supportedModes: IntentModes { .foreground(.immediate) }

    @Parameter(title: "Session ID")
    var sessionID: String

    @Dependency private var sessionStore: SessionStore
    @Dependency private var navigationState: AppNavigationState

    init() {
        sessionID = ""
    }

    init(sessionID: UUID) {
        self.sessionID = sessionID.uuidString
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        guard let sessionID = UUID(uuidString: sessionID) else { return .result() }
        _ = sessionStore.extendCurrentStep(for: sessionID, by: 10 * 60)
        navigationState.openTimer(for: sessionID)
        return .result()
    }
}

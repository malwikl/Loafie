import Foundation
import WatchConnectivity

final class WatchSessionModel: NSObject, ObservableObject, WCSessionDelegate {
    @Published var snapshot: WatchSessionSnapshot?

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func requestSnapshot() {
        guard WCSession.default.isReachable else { return }
        WCSession.default.sendMessage(["action": WatchAction.requestSnapshot.rawValue], replyHandler: nil)
    }

    func sendAction(_ action: WatchAction, payload: [String: Any] = [:]) {
        guard WCSession.default.isReachable else { return }
        var message: [String: Any] = ["action": action.rawValue]
        payload.forEach { message[$0.key] = $0.value }
        WCSession.default.sendMessage(message, replyHandler: nil)
    }

    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {}

    nonisolated func session(
        _ session: WCSession,
        didReceiveApplicationContext applicationContext: [String: Any]
    ) {
        guard let data = applicationContext["snapshot"] as? Data,
              let snapshot = try? JSONDecoder().decode(WatchSessionSnapshot.self, from: data) else {
            return
        }
        Task { @MainActor in
            self.snapshot = snapshot
        }
    }
}

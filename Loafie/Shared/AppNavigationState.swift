import Foundation
import Observation

/// Retains navigation requested by external entry points, including AlarmKit.
/// Keeping the request at app scope means it survives view construction during
/// a cold launch, unlike a transient NotificationCenter event.
@MainActor
@Observable
final class AppNavigationState {
    private(set) var requestedTimerSessionID: UUID?

    func openTimer(for sessionID: UUID) {
        requestedTimerSessionID = sessionID
    }

    @discardableResult
    func openTimer(from url: URL) -> Bool {
        let path = url.pathComponents.filter { $0 != "/" }
        let sessionID: UUID?

        if url.scheme == "https", url.host == "loafie.kloeffer.de", path.first == "timer" {
            sessionID = path.dropFirst().first.flatMap(UUID.init(uuidString:))
        } else if url.scheme == "loafie", url.host == "session" {
            sessionID = path.first.flatMap(UUID.init(uuidString:))
        } else {
            sessionID = nil
        }

        guard let sessionID else { return false }
        openTimer(for: sessionID)
        return true
    }
}

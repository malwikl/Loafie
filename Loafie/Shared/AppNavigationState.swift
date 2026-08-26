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
}

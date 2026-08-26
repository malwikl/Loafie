import UIKit

/// Lightweight haptic feedback wrapper that respects the in-app haptics setting.
enum Haptics {

    private static var enabled: Bool {
        UserDefaults.standard.object(forKey: "hapticsEnabled") as? Bool ?? true
    }

    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }
}

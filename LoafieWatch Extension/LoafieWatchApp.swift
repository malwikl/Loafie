import SwiftUI
import WatchKit

@main
struct LoafieWatchApp: App {
    @WKApplicationDelegateAdaptor(LoafieWatchAppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class LoafieWatchAppDelegate: NSObject, WKApplicationDelegate {}

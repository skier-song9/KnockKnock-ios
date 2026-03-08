import SwiftUI
import WatchKit

@main
struct KnockKnockWatchApp: App {
    @WKApplicationDelegateAdaptor private var appDelegate: WatchAppDelegate

    var body: some Scene {
        WindowGroup {
            WatchContentView()
        }
    }
}

final class WatchAppDelegate: NSObject, WKApplicationDelegate {}

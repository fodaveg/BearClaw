import SwiftUI
import ServiceManagement

@main
struct BearHelperApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            ContentView()
                .environmentObject(appDelegate.settingsManager)
                .environmentObject(appDelegate.noteManager)
                .environmentObject(appDelegate.calendarSyncManager)
                .environmentObject(appDelegate.noteHandler)
                .environmentObject(appDelegate.noteManager.calendarManager)
        }
    }
}

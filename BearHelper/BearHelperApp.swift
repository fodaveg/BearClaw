import SwiftUI
import ServiceManagement
import BearClawCore  // Asegúrate de importar tu paquete core aquí

@main
struct BearHelperApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var calendarManagerContainer = CalendarManagerContainer()
    
    var body: some Scene {
        Settings {
            ContentView()
                .environmentObject(appDelegate.settingsManager)
                .environmentObject(appDelegate.noteManager)
                .environmentObject(appDelegate.calendarSyncManager)
                .environmentObject(appDelegate.noteHandler)
                .environmentObject(CalendarManager.shared)
        }
    }
}

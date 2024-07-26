import Cocoa
import SwiftUI
import ServiceManagement
import EventKit
import BearClawCore

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    static let shared = AppDelegate()
    @Published var statusItem: NSStatusItem!
    @Published var settingsWindowController: NSWindowController?
    @Published var popover: NSPopover?
    @Published var aboutPopover: NSPopover?
    private var aboutPopoverTransiencyMonitor: Any?
    
    let bearIntegrationManager = BearIntegrationManager.shared
    let settingsManager = SettingsManager.shared
    let calendarManager: CalendarManager
    
    // Usamos lazy para inicializar solo cuando sea necesario
    public lazy var calendarSyncManager: CalendarSyncManager = {
        CalendarSyncManager(calendarManager: self.calendarManager)
    }()
    
    let noteManager = NoteManager.shared
    let noteHandler = NoteHandler()
    
    override init() {
        self.calendarManager = CalendarManager.shared
        super.init()
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if !bearIntegrationManager.isBearInstalled() {
            bearIntegrationManager.showErrorMessage()
            NSApplication.shared.terminate(self)
        } else {
            print("Bear is installed")
        }
        
        Task {
            await requestCalendarAccess()
        }
        
        calendarManager.reloadCalendarConfiguration()
        StatusItemManager.shared.setupStatusItem()
        configureLaunchAtLogin()
        NotificationCenter.default.addObserver(self, selector: #selector(calendarSelectionDidChange), name: .calendarSelectionChanged, object: nil)
        
        
    }
    
    @objc func calendarSelectionDidChange() {
        calendarManager.reloadCalendarConfiguration()
    }
    
    func configureLaunchAtLogin() {
        resetLaunchAtLoginState()
        let launchAtLogin = settingsManager.launchAtLogin
        print("Configuring launch at login: \(launchAtLogin)")
        settingsManager.setLaunchAtLogin(enabled: launchAtLogin)
    }
    
    func requestCalendarAccess() async {
        let granted = await noteManager.calendarManager.requestCalendarAccess()
        if granted {
            print("Calendar access granted")
            noteManager.calendarManager.checkCalendarAuthorizationStatus()
            calendarSyncManager.scheduleCalendarUpdates()
        } else {
            print("Access to calendar not granted")
        }
    }
    
    func resetLaunchAtLoginState() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
                print("Launch at login has been reset to disabled")
            }
        } catch {
            print("Failed to reset launch at login status: \(error.localizedDescription)")
        }
    }
    
    @objc func openSettings() {
        print("Opening settings")
        if settingsWindowController == nil {
            createSettingsWindow()
        }
        settingsWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private func createSettingsWindow() {
        print("Creating settings window")
        let settingsView = SettingsView()
            .environmentObject(self)
            .environmentObject(CalendarManager.shared)
            .environmentObject(calendarSyncManager) // Propagamos el objeto como EnvironmentObject
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 500),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.contentView = NSHostingView(rootView: settingsView)
        window.title = "Settings"
        settingsWindowController = NSWindowController(window: window)
    }
    
    func application(_ app: NSApplication, open urls: [URL]) {
        for url in urls {
            if url.scheme == "fodabear" {
                bearIntegrationManager.handleCallback(url: url)
            }
        }
    }
}

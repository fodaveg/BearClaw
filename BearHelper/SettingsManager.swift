import Foundation
import SwiftUI
import ServiceManagement

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    @AppStorage("homeNoteID") var homeNoteID: String = ""
    @AppStorage("defaultAction") var defaultAction: String = "home"
    @AppStorage("templates") var templatesData: Data = Data()
    @AppStorage("launchAtLogin") var launchAtLogin: Bool = false
    @AppStorage("calendarSectionHeader") var calendarSectionHeader: String = "## Calendar Events"
    @AppStorage("dailySectionHeader") var dailySectionHeader: String = "## Daily"
    @AppStorage("dailyNoteTag") var dailyNoteTag: String = ""
    @AppStorage("dailyNoteTemplate") var dailyNoteTemplate: String = ""
    @AppStorage("selectedDateFormat") var selectedDateFormat: String = "yyyy-MM-dd"
    @AppStorage("customDateFormat") var customDateFormat: String = ""

    private init() {}

    func loadTemplates() -> [Template] {
        if let loadedTemplates = try? JSONDecoder().decode([Template].self, from: templatesData) {
            return loadedTemplates
        }
        return []
    }

    func saveTemplates(_ templates: [Template]) {
        if let encodedTemplates = try? JSONEncoder().encode(templates) {
            templatesData = encodedTemplates
        }
    }

    func setLaunchAtLogin(enabled: Bool) {
        do {
            if enabled {
                if SMAppService.mainApp.status == .notRegistered {
                    try SMAppService.mainApp.register()
                    print("Successfully set launch at login")
                } else {
                    print("Launch at login is already enabled")
                }
            } else {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                    print("Successfully unset launch at login")
                } else {
                    print("Launch at login is already disabled")
                }
            }
        } catch {
            print("Failed to update launch at login status: \(error.localizedDescription)")
        }
    }
}

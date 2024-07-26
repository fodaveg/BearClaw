import SwiftUI
import EventKit
import AppKit
import BearClawCore

struct SettingsView: View {
    @AppStorage("homeNoteID") private var homeNoteID: String = ""
    @AppStorage("defaultAction") private var defaultAction: String = "home"
    @AppStorage("templates") private var templatesData: Data = Data()
    @AppStorage("launchAtLogin") private var launchAtLogin: Bool = false
    @AppStorage("calendarSectionHeader") private var calendarSectionHeader: String = "## Calendar Events"
    @AppStorage("dailySectionHeader") private var dailySectionHeader: String = "## Daily"
    @AppStorage("selectedDateFormat") private var selectedDateFormat: String = "yyyy-MM-dd"
    
    @State private var templates: [Template] = []
    @State private var showModal = false
    @State private var editingTemplate: Template?
    @State private var selectedTemplates = Set<UUID>()
    @State private var selectedTab = 0
    @State private var customDateFormat: String = ""
    
    @EnvironmentObject var appDelegate: AppDelegate
    @EnvironmentObject var calendarManager: CalendarManager
    @EnvironmentObject var calendarSyncManager: CalendarSyncManager
    
    let dateFormats = ["yyyy-MM-dd", "dd/MM/yyyy", "MM-dd-yyyy", "EEEE, MMM d, yyyy", "MMMM d, yyyy", "MMM d, yyyy", "custom date format"]
    
    var body: some View {
        VStack {
            Picker("", selection: $selectedTab) {
                Text("General").tag(0)
                Text("Templates").tag(1)
                Text("Calendars").tag(2)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            if selectedTab == 0 {
                generalSettings
            } else if selectedTab == 1 {
                templatesSettings
            } else if selectedTab == 2 {
                calendarSettings
            }
        }
        .onAppear {
            loadTemplates()
            calendarManager.checkCalendarAuthorizationStatus()
        }
        .sheet(item: $editingTemplate) { template in
            TemplateEditorView(
                template: Binding(
                    get: { template },
                    set: { updatedTemplate in
                        if let index = templates.firstIndex(where: { $0.id == updatedTemplate.id }) {
                            templates[index] = updatedTemplate
                        } else {
                            templates.append(updatedTemplate)
                        }
                        saveTemplates()
                        showModal = false
                    }
                ),
                onSave: { updatedTemplate in
                    if let index = templates.firstIndex(where: { $0.id == updatedTemplate.id }) {
                        templates[index] = updatedTemplate
                    } else {
                        templates.append(updatedTemplate)
                    }
                    saveTemplates()
                    showModal = false
                }
            )
        }
        .frame(minWidth: 400, minHeight: 600)
    }
    
    private var generalSettings: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("General")
                .font(.title2)
                .padding(.horizontal)
            Group {
                Text("Home Note ID:")
                    .padding(.horizontal)
                
                TextField("Paste the note ID here", text: $homeNoteID)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
            }
            
            Group {
                Text("Left Click Action:")
                    .padding(.horizontal)
                
                Picker("", selection: $defaultAction) {
                    Text("Disabled").tag("disabled")
                    Text("Open Home Note").tag("home")
                    Text("Open Daily Note").tag("daily")
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
            }
            
            Group {
                Text("Calendar Section Header:")
                    .padding(.horizontal)
                
                TextField("Enter the header for calendar events", text: $calendarSectionHeader)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                Text("Daily Section Header:")
                    .padding(.horizontal)
                
                TextField("Enter the header for daily section", text: $dailySectionHeader)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
            }
            
            Group {
                Text("Date Format:")
                    .padding(.horizontal)
                
                HStack {
                    Picker("", selection: Binding(
                        get: { selectedDateFormat == customDateFormat ? "custom date format" : selectedDateFormat },
                        set: { newValue in
                            if newValue == "custom date format" {
                                selectedDateFormat = customDateFormat
                            } else {
                                selectedDateFormat = newValue
                            }
                        }
                    )) {
                        ForEach(dateFormats, id: \.self) { format in
                            Text(formattedDate(for: format)).tag(format)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding(.horizontal)
                    
                    Button(action: {
                        let url = URL(string: "https://www.datetimeformatter.com/how-to-format-date-time-in-swift/")!
                        NSWorkspace.shared.open(url)
                    }) {
                        Image(systemName: "questionmark.circle")
                    }
                    .padding(.horizontal)
                }
                
                if selectedDateFormat == customDateFormat {
                    TextField("Enter custom date format", text: $customDateFormat, onCommit: {
                        selectedDateFormat = customDateFormat
                    })
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                }
            }
            
            Spacer()
            
            HStack {
                Spacer()
                Toggle("Launch at Login", isOn: $launchAtLogin)
                    .padding()
                    .onChange(of: launchAtLogin) { _, _ in
                        appDelegate.settingsManager.setLaunchAtLogin(enabled: launchAtLogin)
                    }
            }
        }
    }
    
    
    
    private var templatesSettings: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Templates")
                .font(.title2)
                .padding(.horizontal)
            
            VStack {
                List(selection: $selectedTemplates) {
                    ForEach(templates) { template in
                        HStack {
                            Text(template.name)
                            Spacer()
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedTemplates = [template.id]
                        }
                    }
                    .onDelete(perform: deleteTemplate)
                }
                .cornerRadius(10)
            }
            .padding(.horizontal)
            
            HStack {
                Spacer()
                Button(action: {
                    let newTemplate = Template(name: "New Template", content: "", tag: "")
                    templates.append(newTemplate)
                    editingTemplate = newTemplate
                    showModal = true
                }) {
                    Image(systemName: "plus")
                }
                .padding()
                Button(action: {
                    if let editingTemplate = templates.first(where: { selectedTemplates.contains($0.id) }) {
                        self.editingTemplate = editingTemplate
                        showModal = true
                    }
                }) {
                    Image(systemName: "pencil")
                }
                .padding()
                .disabled(selectedTemplates.isEmpty)
                Button(action: {
                    deleteSelectedTemplates()
                }) {
                    Image(systemName: "minus")
                }
                .padding()
                .disabled(selectedTemplates.isEmpty)
            }
        }
    }
    
    private var calendarSettings: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Calendars")
                .font(.title2)
                .padding(.horizontal)
            
            if calendarManager.isAuthorized {
                List {
                    ForEach(calendarManager.getCalendars(), id: \.self) { (calendar: EKCalendar) in
                        HStack {
                            Text(calendar.title)
                            Spacer()
                            if calendarManager.selectedCalendarIDs.contains(calendar.calendarIdentifier) {
                                Image(systemName: "checkmark")
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            self.toggleCalendarSelection(for: calendar)
                        }
                    }
                }
                .cornerRadius(10)
                .padding(.horizontal)
                
                HStack {
                    Spacer()
                    Button("Sync Now") {
                        calendarSyncManager.syncNow()
                    }
                    .padding()
                }
            } else {
                VStack {
                    Text("Calendar access is not granted. Please enable access in system settings and restart the App")
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button("Open System Settings") {
                        openSystemSettings()
                    }
                    .padding()
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func openSystemSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") {
            NSWorkspace.shared.open(url)
            startCheckingAuthorization()
        }
    }
    
    private func startCheckingAuthorization() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            self.calendarManager.checkCalendarAuthorizationStatus()
            if self.calendarManager.isAuthorized {
                timer.invalidate()
            }
        }
    }
    
    private func toggleCalendarSelection(for calendar: EKCalendar) {
        if let index = calendarManager.selectedCalendarIDs.firstIndex(of: calendar.calendarIdentifier) {
            calendarManager.selectedCalendarIDs.remove(at: index)
        } else {
            calendarManager.selectedCalendarIDs.append(calendar.calendarIdentifier)
        }
    }
    
    private func loadTemplates() {
        templates = appDelegate.settingsManager.loadTemplates()
        if templates.isEmpty {
            let defaultTemplate = Template(name: "Daily", content: "Default daily template", tag: "daily")
            templates.append(defaultTemplate)
            saveTemplates()
        }
    }
    
    private func saveTemplates() {
        appDelegate.settingsManager.saveTemplates(templates)
    }
    
    private func deleteTemplate(at offsets: IndexSet) {
        templates.remove(atOffsets: offsets)
        saveTemplates()
    }
    
    private func deleteSelectedTemplates() {
        templates.removeAll { template in
            selectedTemplates.contains(template.id)
        }
        selectedTemplates.removeAll()
        saveTemplates()
    }
    
    private func formattedDate(for format: String) -> String {
        let dateFormatter = DateFormatter()
        if format == "custom date format" {
            return "Specify a custom format"
        } else {
            dateFormatter.dateFormat = format
        }
        return dateFormatter.string(from: Date())
    }
}

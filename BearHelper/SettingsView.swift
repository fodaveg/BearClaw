import AppKit
import BearClawCore
import EventKit
import SwiftUI

struct SettingsView: View {
    // Variables de almacenamiento para configuraciones
    @AppStorage("homeNoteID") private var homeNoteID: String = ""
    @AppStorage("defaultAction") private var defaultAction: String = "home"
    @AppStorage("templates") private var templatesData: Data = Data()
    @AppStorage("launchAtLogin") private var launchAtLogin: Bool = false
    @AppStorage("calendarSectionHeader") private var calendarSectionHeader:
        String = "## Calendar Events"
    @AppStorage("dailySectionHeader") private var dailySectionHeader: String =
        "## Daily"
    @AppStorage("selectedDateFormat") private var selectedDateFormat: String =
        "yyyy-MM-dd"
    @AppStorage("customDateFormat") private var customDateFormat: String = ""

    // Estado de la vista
    @State private var templates: [Template] = []
    @State private var showModal = false
    @State private var editingTemplate: Template?
    @State private var selectedTemplates = Set<UUID>()
    @State private var selectedTab = 0

    // Variables de entorno para los manejadores
    @EnvironmentObject var appDelegate: AppDelegate
    @EnvironmentObject var calendarManager: CalendarManager
    @EnvironmentObject var calendarSyncManager: CalendarSyncManager

    // Formatos de fecha disponibles
    let dateFormats = [
        "yyyy-MM-dd", "dd/MM/yyyy", "MM-dd-yyyy", "EEEE, MMM d, yyyy",
        "MMMM d, yyyy", "MMM d, yyyy", "custom date format",
    ]

    var body: some View {
        VStack {
            // Selector de pestañas
            Picker("", selection: $selectedTab) {
                Text("General").tag(0)
                Text("Templates").tag(1)
                Text("Calendars").tag(2)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            // Vista según la pestaña seleccionada
            if selectedTab == 0 {
                generalSettings
            } else if selectedTab == 1 {
                templatesSettings
            } else if selectedTab == 2 {
                calendarSettings
            }
        }
        .onAppear {
            // Cargar las plantillas y verificar la autorización del calendario al aparecer la vista
            loadTemplates()
            calendarManager.checkCalendarAuthorizationStatus()
        }
        .sheet(item: $editingTemplate) { template in
            // Editor de plantillas modal
            TemplateEditorView(
                template: Binding(
                    get: { template },
                    set: { updatedTemplate in
                        if let index = templates.firstIndex(where: {
                            $0.id == updatedTemplate.id
                        }) {
                            templates[index] = updatedTemplate
                        } else {
                            templates.append(updatedTemplate)
                        }
                        saveTemplates()
                        showModal = false
                    }
                ),
                onSave: { updatedTemplate in
                    if let index = templates.firstIndex(where: {
                        $0.id == updatedTemplate.id
                    }) {
                        templates[index] = updatedTemplate
                    } else {
                        templates.append(updatedTemplate)
                    }
                    saveTemplates()
                    showModal = false
                }
            )
        }
        .frame(minWidth: 400, minHeight: 600)  // Tamaño mínimo de la ventana
    }

    // Vista de configuraciones generales
    private var generalSettings: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("General")
                .font(.title2)
                .padding(.horizontal)

            Group {
                Text("Home Note ID:")
                    .padding(.horizontal)
                HStack {
                    TextField("Paste the note ID here", text: $homeNoteID)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    Button(action: {
                        deleteHomeNoteID()
                    }) {
                        Image(systemName: "trash")
                    }
                    .padding(.horizontal)

                }

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

                TextField(
                    "Enter the header for calendar events",
                    text: $calendarSectionHeader
                )
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

                Text("Daily Section Header:")
                    .padding(.horizontal)

                TextField(
                    "Enter the header for daily section",
                    text: $dailySectionHeader
                )
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            }

            Group {
                Text("Date Format:")
                    .padding(.horizontal)

                HStack {
                    Picker(
                        "",
                        selection: Binding(
                            get: {
                                selectedDateFormat == customDateFormat
                                    ? "custom date format" : selectedDateFormat
                            },
                            set: { newValue in
                                if newValue == "custom date format" {
                                    selectedDateFormat = customDateFormat
                                } else {
                                    selectedDateFormat = newValue
                                }
                            }
                        )
                    ) {
                        ForEach(dateFormats, id: \.self) { format in
                            Text(formattedDate(for: format)).tag(format)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding(.horizontal)

                    Button(action: {
                        let url = URL(
                            string:
                                "https://www.datetimeformatter.com/how-to-format-date-time-in-swift/"
                        )!
                        NSWorkspace.shared.open(url)
                    }) {
                        Image(systemName: "questionmark.circle")
                    }
                    .padding(.horizontal)
                }

                if selectedDateFormat == "custom date format" {
                    TextField(
                        "Enter custom date format", text: $customDateFormat,
                        onCommit: {
                            selectedDateFormat = customDateFormat
                        }
                    )
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
                        appDelegate.settingsManager.setLaunchAtLogin(
                            enabled: launchAtLogin)
                    }
            }
        }
    }

    // Vista de configuración de plantillas
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
                        .onTapGesture(count: 2) {
                            // Ejecutar la acción de edición en doble clic
                            editingTemplate = template
                            showModal = true
                        }
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
                    let newTemplate = Template(
                        name: "New Template", content: "", tag: "")
                    templates.append(newTemplate)
                    editingTemplate = newTemplate
                    showModal = true
                }) {
                    Image(systemName: "plus")
                }
                .padding()
                Button(action: {
                    if let editingTemplate = templates.first(where: {
                        selectedTemplates.contains($0.id)
                    }) {
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

    // Vista de configuración de calendarios
    private var calendarSettings: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Calendars")
                .font(.title2)
                .padding(.horizontal)

            if calendarManager.isAuthorized {
                List {
                    ForEach(calendarManager.getCalendars(), id: \.self) {
                        (calendar: EKCalendar) in
                        HStack {
                            Text(calendar.title)
                            Spacer()
                            if calendarManager.selectedCalendarIDs.contains(
                                calendar.calendarIdentifier)
                            {
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
                    Text(
                        "Calendar access is not granted. Please enable access in system settings and restart the App"
                    )
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

    // Abrir la configuración del sistema
    private func openSystemSettings() {
        if let url = URL(
            string:
                "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars"
        ) {
            NSWorkspace.shared.open(url)
            startCheckingAuthorization()
        }
    }
    // Comenzar a verificar el estado de autorización
    private func startCheckingAuthorization() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            self.calendarManager.checkCalendarAuthorizationStatus()
            if self.calendarManager.isAuthorized {
                timer.invalidate()
            }
        }
    }

    private func toggleCalendarSelection(for calendar: EKCalendar) {
        var newSelection = calendarManager.selectedCalendarIDs
        if let index = newSelection.firstIndex(of: calendar.calendarIdentifier)
        {
            newSelection.remove(at: index)
        } else {
            newSelection.append(calendar.calendarIdentifier)
        }

        if Set(calendarManager.selectedCalendarIDs) != Set(newSelection) {
            calendarManager.selectedCalendarIDs = newSelection
        }
    }

    // Cargar plantillas desde el gestor de configuraciones
    private func loadTemplates() {
        templates = appDelegate.settingsManager.loadTemplates()
        if templates.isEmpty {
            let defaultTemplate = Template(
                name: "Daily", content: "Default daily template", tag: "daily")
            templates.append(defaultTemplate)
            saveTemplates()
        }
    }

    // Guardar plantillas en el gestor de configuraciones
    private func saveTemplates() {
        appDelegate.settingsManager.saveTemplates(templates)
    }

    // Eliminar plantilla en una posición específica
    private func deleteTemplate(at offsets: IndexSet) {
        templates.remove(atOffsets: offsets)
        saveTemplates()
    }

    // Eliminar las plantillas seleccionadas
    private func deleteSelectedTemplates() {
        templates.removeAll { template in
            selectedTemplates.contains(template.id)
        }
        selectedTemplates.removeAll()
        saveTemplates()
    }

    // Eliminar plantilla en una posición específica
    private func deleteHomeNoteID() {
        UserDefaults.standard.removeObject(forKey: "homeNoteID")
        homeNoteID = ""
    }

    // Formatear una fecha según el formato especificado
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

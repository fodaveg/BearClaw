import Foundation
import AppKit
import EventKit

class NoteManager: ObservableObject {
    public static let shared = NoteManager()
    var calendarManager = CalendarManager()
    var templateManager = TemplateManager()
    var bearManager = BearManager()

    private init() {}  // Singleton Pattern

    var noteContent: String? // Variable para almacenar el contenido de la nota
    let semaphore = DispatchSemaphore(value: 0) // Semáforo para la sincronización

    func createDailyNoteForDate(selectedDate: Date) {
        let formatter = DateFormatter()
        formatter.dateFormat = SettingsManager.shared.selectedDateFormat
        let dateString = formatter.string(from: selectedDate)

        getDailyNoteID(for: dateString) { noteContent in
            if noteContent.isEmpty {
                self.templateManager.createDailyNoteWithTemplate(for: dateString)
            } else {
                // self.updateDailyNoteWithCalendarEvents(for: dateString)
            }
        }
    }

    func replaceDateOnHome(_ id: String) {
        // Reemplazar la fecha en la nota del home
    }

    func updateCalendarEventsOnNote(_ noteId: String) {
        // Actualizar los eventos del calendario en la nota especificada
    }

    func getDailyNoteID(for dateString: String, completion: @escaping (String) -> Void) {
        let searchText = dateString

        let tag = UserDefaults.standard.string(forKey: "dailyNoteTag")?.addingPercentEncodingForRFC3986() ?? ""

        //        let encodedSearchText = searchText.addingPercentEncodingForRFC3986() ?? ""
        let searchURLString = "bear://x-callback-url/search?term=\(searchText)&tag=\(tag)&x-success=fodabear://open-note-success&x-error=fodabear://open-note-error&token=XXXXX"
        if let searchURL = URL(string: searchURLString) {
            print("Searching daily note with URL: \(searchURL)")
            NSWorkspace.shared.open(searchURL)
            DispatchQueue.global().async {
                let result = self.semaphore.wait(timeout: .now() + 10)
                if result == .success {
                    print("Daily note search succeeded")
                    completion(self.noteContent ?? "")
                } else {
                    print("Daily note search timed out")
                    completion("")
                }
            }
        }
    }

    func updateDailyNoteWithCalendarEvents(for dateString: String, noteContent: String, noteId: String, open: Bool = true) {
        let events = calendarManager.fetchCalendarEvents(for: dateString)
        let cleanedEvents = events.replacingOccurrences(of: "Optional(\"", with: "").replacingOccurrences(of: "\")", with: "")

        print("update daily calendar: \(events)")
        let updatedContent = templateManager.replaceCalendarSection(in: noteContent, with: cleanedEvents)
        bearManager.updateNoteContent(newContent: updatedContent, noteID: noteId, open: open, show: open)
    }

    func updateHomeNoteWithCalendarEvents(for dateString: String, noteContent: String, homeNoteId: String) {
        let events = calendarManager.fetchCalendarEvents(for: dateString)
        let cleanedEvents = events.replacingOccurrences(of: "Optional(\"", with: "").replacingOccurrences(of: "\")", with: "")

        let updatedContent = templateManager.replaceDailySection(in: noteContent, with: dateString)
        let fullyUpdatedContent = templateManager.replaceCalendarSection(in: updatedContent, with: cleanedEvents)
        bearManager.updateNoteContent(newContent: fullyUpdatedContent, noteID: homeNoteId, open: false, show: false)
    }

    func getCurrentDateFormatted(date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = SettingsManager.shared.selectedDateFormat
        return formatter.string(from: date)
    }
}

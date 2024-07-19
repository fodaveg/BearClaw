import Cocoa
import BearClawCore

class NoteHandler: NSObject, ObservableObject {
    static let shared = NoteHandler()
    var bearManager = BearManager.shared
    var templateManager = TemplateManager.shared
    @Published var currentTodayDateString: String?
    @Published var currentHomeNoteID: String?
    @Published var currentDailyNoteID: String?

    @objc func openHomeNote() {
        print("Opening home note")
        let homeNoteID = SettingsManager.shared.homeNoteID
        updateHomeNoteIfNeeded()
        if let url = URL(string: "bear://x-callback-url/open-note?id=\(homeNoteID)") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc func syncCalendarForDate(_ date: String?) {
        let date = date ?? getCurrentDateFormatted()
        let fetchURLString = "bear://x-callback-url/open-note?title=\(date)&show_window=no&open_note=no&x-success=fodabear://update-daily-note-if-needed-success-for-sync"
        if let fetchURL = URL(string: fetchURLString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") {
            print("Fetching daily note with URL: \(fetchURL)")
            NSWorkspace.shared.open(fetchURL)
        }
    }

    @objc func syncNoteById(url: URL) {
        if let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems {
            let noteId = queryItems.first(where: { $0.name == "id" })?.value

            let fetchURLString = "bear://x-callback-url/open-note?id=\(noteId ?? "")&show_window=no&open_note=no&x-success=fodabear://update-daily-note-if-needed-success-for-sync"

            if let fetchURL = URL(string: fetchURLString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") {
                print("Fetching note with URL: \(fetchURL)")
                NSWorkspace.shared.open(fetchURL)
            }

        }
    }

    @objc func updateHomeNoteIfNeeded() {
        let homeNoteId = SettingsManager.shared.homeNoteID
        let fetchURLString = "bear://x-callback-url/open-note?id=\(homeNoteId)&show_window=no&open_note=no&x-success=fodabear://update-home-note-if-needed-success&x-error=fodabear://update-home-note-if-needed-error"
        if let fetchURL = URL(string: fetchURLString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") {
            print("Fetching home note with URL: \(fetchURL)")
            NSWorkspace.shared.open(fetchURL)
        }
    }

    @objc func updateDailyNoteIfNeeded(_ date: String?) {
        let currentDateFormatted = getCurrentDateFormatted()
        let fetchURLString = "bear://x-callback-url/open-note?title=\(date ?? currentDateFormatted)&show_window=no&open_note=no&x-success=fodabear://update-daily-note-if-needed-success"
        if let fetchURL = URL(string: fetchURLString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") {
            print("Fetching daily note with URL: \(fetchURL)")
            NSWorkspace.shared.open(fetchURL)
        }
    }

    @objc func updateDailyNoteIfNeededError(url: URL) {}

    @objc func updateDailyNoteIfNeededSuccess(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return
        }

        guard let title = queryItems.first(where: { $0.name == "title" })?.value else { return }
        guard let note = queryItems.first(where: { $0.name == "note" })?.value else { return }
        guard let id = queryItems.first(where: { $0.name == "identifier" })?.value else { return }

        NoteManager.shared.updateDailyNoteWithCalendarEvents(for: title, noteContent: note, noteId: id)
    }

    @objc func updateDailyNoteIfNeededSuccessForSync(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return
        }

        guard let title = queryItems.first(where: { $0.name == "title" })?.value else { return }
        guard let note = queryItems.first(where: { $0.name == "note" })?.value else { return }
        guard let id = queryItems.first(where: { $0.name == "identifier" })?.value else { return }
        NoteManager.shared.updateDailyNoteWithCalendarEvents(for: title, noteContent: note, noteId: id, open: false)
    }

    @objc func updateNoteAndOpen(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return
        }

        guard let title = queryItems.first(where: { $0.name == "title" })?.value else { return }
        guard let note = queryItems.first(where: { $0.name == "note" })?.value else { return }
        guard let id = queryItems.first(where: { $0.name == "identifier" })?.value else { return }
        NoteManager.shared.updateDailyNoteWithCalendarEvents(for: title, noteContent: note, noteId: id, open: true)
    }

    @objc func openNoteForNoteAndOpen(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return
        }
        guard let id = queryItems.first(where: { $0.name == "identifier" })?.value else { return }
        let fetchURLString = "bear://x-callback-url/open-note?id=\(id)&show_window=no&open_note=no&x-success=fodabear://replace-sync-placeholder-action"
        if let fetchURL = URL(string: fetchURLString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") {
            print("Fetching daily note with URL: \(fetchURL)")
            NSWorkspace.shared.open(fetchURL)
        }
    }

    @objc func updateHomeNoteIfNeededSuccess(url: URL) {
        let homeNoteId = SettingsManager.shared.homeNoteID
        let currentDateFormatted = getCurrentDateFormatted()
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return
        }

        guard let note = queryItems.first(where: { $0.name == "note" })?.value else { return }

        NoteManager.shared.updateHomeNoteWithCalendarEvents(for: currentDateFormatted, noteContent: note, homeNoteId: homeNoteId)
    }

    @objc func updateHomeNoteIfNeededError(url: URL) {
        print("updateHomeNoteIfNeededError: \(url)")
    }

    public func testOk(url: URL) {
        print("URL OK: \(url)")

    }

    public func testKo(url: URL) {
        print("URL KO: \(url)")

    }

    @objc func openDailyNoteForDate(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return
        }
        guard let date = queryItems.first(where: { $0.name == "date" })?.value else { return }

        self.openDailyNoteWithDate(date)

    }

    @objc func openDailyNote() {
        print("Opening daily note")
        let dateToday = getCurrentDateFormatted()
        let successParameter = "fodabear://open-daily-note-success"
        let errorParameter = "fodabear://open-daily-note-error"
        updateDailyNoteIfNeeded(dateToday)
        if let dailyUrl = URL(string: "bear://x-callback-url/open-note?title=\(dateToday)&open_note=no&show_window=no&exclude_trashed=yes&x-success=\(successParameter)&x-error=\(errorParameter)") {
            NSWorkspace.shared.open(dailyUrl)
        }
    }

    @objc func openDailyNoteSuccess(url: URL) {
        if let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems {
            let dailyId = queryItems.first(where: { $0.name == "id" })?.value
            if let dailyUrl = URL(string: "bear://x-callback-url/open-note?id=\(String(describing: dailyId))") {
                NSWorkspace.shared.open(dailyUrl)
            }
        }
    }

    @objc func openDailyNoteError(url: URL) {
        createDailyNoteWithDate(getCurrentDateFormatted())
    }

    @objc func openDailyNoteWithDate(_ date: String?) {
        print("Opening daily note")
        let date = date ?? getCurrentDateFormatted()
        let successParameter = "fodabear://open-daily-note-with-date-success"
        let errorParameter = "fodabear://create-daily-note-for-date?date=\(date)"
        updateDailyNoteIfNeeded(date)
        if let dailyUrl = URL(string: "bear://x-callback-url/open-note?title=\(date)&open_note=no&show_window=no&exclude_trashed=yes&x-success=\(successParameter.addingPercentEncodingForRFC3986() ?? "")&x-error=\(errorParameter.addingPercentEncodingForRFC3986() ?? "")") {

            print("openDailyNoteWithDate: \(dailyUrl)")

            NSWorkspace.shared.open(dailyUrl)
        }
    }

    @objc func openDailyNoteWithDateSuccess(url: URL) {
        if let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems {
            let dailyId = queryItems.first(where: { $0.name == "id" })?.value
            if let dailyUrl = URL(string: "bear://x-callback-url/open-note?id=\(String(describing: dailyId))") {
                NSWorkspace.shared.open(dailyUrl)
            }
        }
    }

    @objc func openDailyNoteWithDateError(url: URL) {
        if let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems {
            let dailyDate = queryItems.first(where: { $0.name == "date" })?.value
            createDailyNoteWithDate(dailyDate)
        }
    }

    @objc func createDailyNoteWithDate(url: URL) {

        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return
        }
        guard let date = queryItems.first(where: { $0.name == "date" })?.value else { return }

        self.createDailyNoteWithDate(date)
    }

    @objc func createDailyNoteWithDate(_ date: String?) {
        let date = date ?? getCurrentDateFormatted()
        guard let template = SettingsManager.shared.loadTemplates().first(where: { $0.name == "Daily" }) else { return }
        let processedContent = templateManager.processTemplateVariables(template.content, for: date)
        let tags = [template.tag]
        let success = "fodabear://replace-sync-placeholder"

        let createURLString = "bear://x-callback-url/create?text=\(processedContent.addingPercentEncodingForRFC3986() ?? "")&tags=\(tags.joined(separator: ",").addingPercentEncodingForRFC3986() ?? "")&open_note=no&show_window=no&x-success=\(success.addingPercentEncodingForRFC3986() ?? "")"

        if let fetchURL = URL(string: createURLString) {
            NSWorkspace.shared.open(fetchURL)
        }
    }

    @objc func getCurrentDateFormatted(date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = SettingsManager.shared.selectedDateFormat
        return formatter.string(from: date)
    }

    @objc func openTemplateNote(_ sender: NSMenuItem) {
        let templateTitle = sender.title
        let templateNameComponents = templateTitle.components(separatedBy: " ")

        guard templateNameComponents.count > 2 else { return }

        let templateName = templateNameComponents.dropFirst().dropLast().joined(separator: " ")

        guard let template = SettingsManager.shared.loadTemplates().first(where: { $0.name == templateName }) else { return }

        bearManager.openTemplate(template)
    }
}

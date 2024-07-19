import Cocoa

class BearIntegrationManager {
    static let shared = BearIntegrationManager()

    func isBearInstalled() -> Bool {
        if let url = URL(string: "bear://") {
            return NSWorkspace.shared.urlForApplication(toOpen: url) != nil
        }
        return false
    }

    func showErrorMessage() {
        let alert = NSAlert()
        alert.messageText = "Bear is not installed"
        alert.informativeText = "This companion application requires Bear to be installed in order to function. Please install Bear and try again."
        alert.alertStyle = .critical
        alert.addButton(withTitle: "Close")
        alert.runModal()
    }

    func handleCallback(url: URL) {
        if let host = url.host {
            switch host {
            case "update-home-note-if-needed-success":
                NoteHandler.shared.updateHomeNoteIfNeededSuccess(url: url)
            case "update-home-note-if-needed-error":
                NoteHandler.shared.updateHomeNoteIfNeededError(url: url)
            case "update-daily-note-if-needed-success":
                NoteHandler.shared.updateDailyNoteIfNeededSuccess(url: url)
            case "update-daily-note-if-needed-success-for-sync":
                NoteHandler.shared.updateDailyNoteIfNeededSuccessForSync(url: url)
            case "update-daily-note-if-needed-error":
                NoteHandler.shared.updateDailyNoteIfNeededError(url: url)
            case "open-daily-note-success":
                NoteHandler.shared.openDailyNoteSuccess(url: url)
            case "open-daily-note-error":
                NoteHandler.shared.openDailyNoteError(url: url)
            case "sync-note":
                NoteHandler.shared.syncNoteById(url: url)
            case "replace-sync-placeholder":
                NoteHandler.shared.openNoteForNoteAndOpen(url: url)
            case "replace-sync-placeholder-action":
                NoteHandler.shared.updateNoteAndOpen(url: url)
            case "open-daily-note-for-date":
                NoteHandler.shared.openDailyNoteForDate(url: url)
            case "create-daily-note-for-date":
                NoteHandler.shared.createDailyNoteWithDate(url: url)
            default:
                break
            }
        }
    }
}

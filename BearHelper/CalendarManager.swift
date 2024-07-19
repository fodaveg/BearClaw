import Foundation
import EventKit
import SwiftUI

class CalendarManager: ObservableObject {
    let eventStore = EKEventStore()
    @Published var selectedCalendarIDs: [String] {
        didSet {
            UserDefaults.standard.set(selectedCalendarIDs, forKey: "selectedCalendarIDs")
        }
    }

    init() {
        if let storedCalendarIDs = UserDefaults.standard.array(forKey: "selectedCalendarIDs") as? [String] {
            selectedCalendarIDs = storedCalendarIDs
        } else {
            selectedCalendarIDs = []
        }
    }

    func requestAccess(completion: @escaping (Bool) -> Void) {
        eventStore.requestFullAccessToEvents { granted, _ in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }

    func addEvent(title: String, startDate: Date, endDate: Date, notes: String? = nil, completion: @escaping (Bool, Error?) -> Void) {
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = startDate
        event.endDate = endDate
        event.notes = notes
        event.calendar = eventStore.defaultCalendarForNewEvents

        do {
            try eventStore.save(event, span: .thisEvent)
            completion(true, nil)
        } catch let error {
            completion(false, error)
        }
    }

    func fetchEvents(startDate: Date, endDate: Date) -> [EKEvent]? {
        let selectedCalendars = self.selectedCalendars()
        guard !selectedCalendars.isEmpty else {
            print("No calendars selected.")
            return []
        }
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: selectedCalendars)
        return eventStore.events(matching: predicate)
    }

    func getCalendars() -> [EKCalendar] {
        return eventStore.calendars(for: .event)
    }

    func selectedCalendars() -> [EKCalendar] {
        let calendars = eventStore.calendars(for: .event)
        return calendars.filter { selectedCalendarIDs.contains($0.calendarIdentifier) }
    }

    func fetchCalendarEvents(for dateString: String) -> String {
        print("Fetching calendar events for date: \(dateString)")

        let selectedCalendars = self.selectedCalendars()
        guard !selectedCalendars.isEmpty else {
            print("Warning: No calendars selected")
            return ""
        }

        let startDate = getDate(from: dateString)
        let endDate = Calendar.current.date(byAdding: .day, value: 1, to: startDate)!

        print("Start date: \(startDate), End date: \(endDate)")

        do {
            let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: selectedCalendars)
            let events = eventStore.events(matching: predicate)

            print("Number of events found: \(events.count)")

            if events.isEmpty {
                print("No events found for the specified date")
                return "No events scheduled for this day."
            }

            let now = Date()
            let formattedEvents = events.map { event in
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm"
                let startTimeString = formatter.string(from: event.startDate)
                let endTimeString = formatter.string(from: event.endDate)

                // Marcar como completada si la fecha de finalización es superior a la hora actual
                let status = event.endDate < now ? "x" : " "

                return "- [\(status)] \(startTimeString) - \(endTimeString): \(event.title ?? "")"
            }.joined(separator: "\n")

            print("Formatted events:\n\(formattedEvents)")

            return formattedEvents
        }
    }

    private func getDate(from dateString: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = SettingsManager.shared.selectedDateFormat
        return formatter.date(from: dateString)!
    }
}

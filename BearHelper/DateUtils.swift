import Foundation

class DateUtils {
    static func getCurrentDateFormatted(date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = SettingsManager.shared.selectedDateFormat
        return formatter.string(from: date)
    }

    static func getDateString(forDaysAfter daysAfter: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = SettingsManager.shared.selectedDateFormat
        let date = Calendar.current.date(byAdding: .day, value: daysAfter, to: Date())!
        return formatter.string(from: date)
    }

    static func getDateString(forDaysBefore daysBefore: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = SettingsManager.shared.selectedDateFormat
        let date = Calendar.current.date(byAdding: .day, value: -daysBefore, to: Date())!
        return formatter.string(from: date)
    }

    static func getDate(from dateString: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = SettingsManager.shared.selectedDateFormat
        return formatter.date(from: dateString)!
    }
}

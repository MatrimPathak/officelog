import WidgetKit
import SwiftUI

// MARK: - Unified Timeline Entry
struct OfficeLogEntry: TimelineEntry {
    let date: Date
    let hasData: Bool
    let month: String
    let monthName: String
    let year: Int
    let attendancePercent: Double
    let daysPresent: Int
    let businessDays: Int
    let holidays: [String]
    let attendedDays: [String]
    let today: String
    let nextHoliday: String?
    let nextHolidayDate: String?
    let calendarData: [CalendarDay]
    let isDarkMode: Bool
    let themeColors: WidgetThemeColors
}

// MARK: - Theme Colors
struct WidgetThemeColors {
    let primary: String
    let background: String
    let surface: String
    let onSurface: String
    let accent: String
    let success: String
    let error: String
    
    static let defaultLight = WidgetThemeColors(
        primary: "#1565C0",
        background: "#F6F7FB",
        surface: "#FFFFFF",
        onSurface: "#0B1A2B",
        accent: "#FFC107",
        success: "#2E7D32",
        error: "#D32F2F"
    )
    
    static let defaultDark = WidgetThemeColors(
        primary: "#4F8FEF",
        background: "#121212",
        surface: "#1E1E1E",
        onSurface: "#E6EEF9",
        accent: "#FFD54F",
        success: "#66BB6A",
        error: "#EF5350"
    )
}

// MARK: - Unified Timeline Provider
struct OfficeLogProvider: TimelineProvider {
    func placeholder(in context: Context) -> OfficeLogEntry {
        OfficeLogEntry(
            date: Date(),
            hasData: false,
            month: "September 2025",
            monthName: "September",
            year: 2025,
            attendancePercent: 0.0,
            daysPresent: 0,
            businessDays: 0,
            holidays: [],
            attendedDays: [],
            today: "2025-09-07",
            nextHoliday: "Log your day in OfficeLog",
            nextHolidayDate: nil,
            calendarData: [],
            isDarkMode: false,
            themeColors: WidgetThemeColors.defaultLight
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (OfficeLogEntry) -> ()) {
        // Sample calendar data for preview
        let sampleCalendarData = (1...30).map { day in
            CalendarDay(
                day: day,
                isAttended: day % 3 == 0,
                isHoliday: day == 15,
                isToday: day == 7,
                holidayName: day == 15 ? "Holiday" : "",
                isWorkingDay: day % 7 != 0 && day % 7 != 6
            )
        }

        let entry = OfficeLogEntry(
            date: Date(),
            hasData: true,
            month: "September 2025",
            monthName: "September",
            year: 2025,
            attendancePercent: 67.0,
            daysPresent: 12,
            businessDays: 18,
            holidays: ["2025-09-15"],
            attendedDays: ["2025-09-01", "2025-09-03", "2025-09-06"],
            today: "2025-09-07",
            nextHoliday: "Diwali",
            nextHolidayDate: "2025-11-01",
            calendarData: sampleCalendarData,
            isDarkMode: false,
            themeColors: WidgetThemeColors.defaultLight
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        // Read data from UserDefaults (shared with Flutter app)
        let userDefaults = UserDefaults(suiteName: "group.com.matrimpathak.attendence_flutter")
        
        // Read common data
        let hasData = userDefaults?.bool(forKey: "small_has_data") ?? false
        let isDarkMode = userDefaults?.bool(forKey: "small_dark_mode") ?? false
        
        // Read theme colors
        let primaryColor = userDefaults?.string(forKey: "small_primary_color") ?? (isDarkMode ? "#4F8FEF" : "#1565C0")
        let backgroundColor = userDefaults?.string(forKey: "small_background_color") ?? (isDarkMode ? "#121212" : "#F6F7FB")
        let surfaceColor = userDefaults?.string(forKey: "small_surface_color") ?? (isDarkMode ? "#1E1E1E" : "#FFFFFF")
        let textColor = userDefaults?.string(forKey: "small_on_surface_color") ?? (isDarkMode ? "#E6EEF9" : "#0B1A2B")
        let accentColor = userDefaults?.string(forKey: "small_accent_color") ?? (isDarkMode ? "#FFD54F" : "#FFC107")
        let successColor = userDefaults?.string(forKey: "medium_success_color") ?? (isDarkMode ? "#66BB6A" : "#2E7D32")
        let errorColor = userDefaults?.string(forKey: "large_error_color") ?? (isDarkMode ? "#EF5350" : "#D32F2F")
        
        let themeColors = WidgetThemeColors(
            primary: primaryColor,
            background: backgroundColor,
            surface: surfaceColor,
            onSurface: textColor,
            accent: accentColor,
            success: successColor,
            error: errorColor
        )
        
        // Read dynamic widget data
        let month = userDefaults?.string(forKey: "small_title") ?? "September 2025"
        let monthName = userDefaults?.string(forKey: "xs_month") ?? "September"
        let year = userDefaults?.integer(forKey: "year") ?? 2025
        let attendancePercent = userDefaults?.double(forKey: "attendance_percent") ?? 0.0
        let daysPresent = userDefaults?.integer(forKey: "days_present") ?? 0
        let businessDays = userDefaults?.integer(forKey: "business_days") ?? 0
        let holidays = userDefaults?.stringArray(forKey: "holidays") ?? []
        let attendedDays = userDefaults?.stringArray(forKey: "attended_days") ?? []
        let today = userDefaults?.string(forKey: "today") ?? "2025-09-07"
        let nextHoliday = userDefaults?.string(forKey: "medium_holiday")
        let nextHolidayDate = userDefaults?.string(forKey: "next_holiday_date")
        let calendarDataString = userDefaults?.string(forKey: "large_calendar_data") ?? ""

        var calendarData: [CalendarDay] = []
        if !calendarDataString.isEmpty {
            // Parse calendar data from JSON
            if let data = calendarDataString.data(using: .utf8) {
                do {
                    if let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                        calendarData = jsonArray.compactMap { dict in
                            guard let day = dict["day"] as? Int else { return nil }
                            return CalendarDay(
                                day: day,
                                isAttended: dict["is_attended"] as? Bool ?? false,
                                isHoliday: dict["is_holiday"] as? Bool ?? false,
                                isToday: dict["is_today"] as? Bool ?? false,
                                holidayName: dict["holiday_name"] as? String ?? "",
                                isWorkingDay: dict["is_current_month"] as? Bool ?? true
                            )
                        }
                    }
                } catch {
                    print("Failed to parse calendar data: \(error)")
                }
            }
        }

        let entry = OfficeLogEntry(
            date: Date(),
            hasData: hasData,
            month: month,
            monthName: monthName,
            year: year,
            attendancePercent: attendancePercent,
            daysPresent: daysPresent,
            businessDays: businessDays,
            holidays: holidays,
            attendedDays: attendedDays,
            today: today,
            nextHoliday: nextHoliday,
            nextHolidayDate: nextHolidayDate,
            calendarData: calendarData,
            isDarkMode: isDarkMode,
            themeColors: themeColors
        )

        // Update every 30 minutes for better responsiveness
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

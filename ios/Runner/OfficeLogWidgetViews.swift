import WidgetKit
import SwiftUI

// MARK: - Color Extensions
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Responsive Widget View
struct OfficeLogResponsiveWidgetView: View {
    var entry: OfficeLogEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                OfficeLogSmallWidgetView(entry: entry)
            case .systemMedium:
                OfficeLogMediumWidgetView(entry: entry)
            case .systemLarge, .systemExtraLarge:
                OfficeLogLargeWidgetView(entry: entry)
            case .accessoryCircular, .accessoryRectangular:
                if #available(iOS 16.0, *) {
                    OfficeLogXSWidgetView(entry: entry)
                } else {
                    OfficeLogSmallWidgetView(entry: entry)
                }
            @unknown default:
                OfficeLogSmallWidgetView(entry: entry)
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
        .widgetURL(URL(string: "officelog://open_home?source=responsive_widget"))
    }
}

// MARK: - Extra Small Widget View (iOS 16+)
@available(iOS 16.0, *)
struct OfficeLogXSWidgetView: View {
    var entry: OfficeLogEntry

    var body: some View {
        ZStack {
            Circle()
                .fill(Color(hex: entry.themeColors.primary).opacity(0.2))
                .overlay(
                    Circle()
                        .stroke(Color(hex: entry.themeColors.primary), lineWidth: 2)
                )

            VStack(spacing: 2) {
                if entry.hasData {
                    Text("\(Int(entry.attendancePercent))%")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: entry.themeColors.primary))
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                    
                    Text(entry.monthName.prefix(3))
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(Color(hex: entry.themeColors.onSurface))
                        .opacity(0.8)
                } else {
                    Image(systemName: "calendar")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: entry.themeColors.primary))
                    
                    Text("OfficeLog")
                        .font(.system(size: 6, weight: .medium))
                        .foregroundColor(Color(hex: entry.themeColors.onSurface))
                        .opacity(0.8)
                }
            }
        }
        .padding(4)
        .widgetURL(URL(string: "officelog://mark_attendance?source=xs_widget"))
    }
}

// MARK: - Small Widget View
struct OfficeLogSmallWidgetView: View {
    var entry: OfficeLogEntry

    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: entry.themeColors.background))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(hex: entry.themeColors.surface))
                        .padding(4)
                )

            VStack(alignment: .leading, spacing: 8) {
                // Header
                HStack {
                    Text(entry.hasData ? entry.month : "OfficeLog")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: entry.themeColors.onSurface))
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if entry.hasData {
                        Text("\(Int(entry.attendancePercent))%")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: entry.themeColors.primary))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(hex: entry.themeColors.primary).opacity(0.1))
                            .cornerRadius(12)
                    }
                }

                Spacer()

                if entry.hasData {
                    // Attendance info
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(entry.daysPresent) / \(entry.businessDays) days")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(hex: entry.themeColors.onSurface).opacity(0.7))
                            .lineLimit(1)

                        // Progress bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(hex: entry.themeColors.onSurface).opacity(0.1))
                                    .frame(height: 6)
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(hex: entry.themeColors.primary))
                                    .frame(width: geometry.size.width * CGFloat(entry.attendancePercent) / 100, height: 6)
                                    .animation(.easeInOut(duration: 1.0), value: entry.attendancePercent)
                            }
                        }
                        .frame(height: 6)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Log your day")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(hex: entry.themeColors.onSurface).opacity(0.7))
                        
                        Text("in OfficeLog")
                            .font(.system(size: 10, weight: .regular))
                            .foregroundColor(Color(hex: entry.themeColors.onSurface).opacity(0.5))
                    }
                }
            }
            .padding(16)
        }
    }
}

// MARK: - Medium Widget View
struct OfficeLogMediumWidgetView: View {
    var entry: OfficeLogEntry

    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: entry.themeColors.background))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(hex: entry.themeColors.surface))
                        .padding(4)
                )

            VStack(alignment: .leading, spacing: 12) {
                // Header with progress
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.hasData ? entry.title : "OfficeLog")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(hex: entry.themeColors.onSurface))
                            .lineLimit(1)
                        
                        if entry.hasData {
                            Text(entry.subtitle)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color(hex: entry.themeColors.onSurface).opacity(0.7))
                        }
                    }
                    
                    Spacer()
                    
                    if entry.hasData {
                        VStack(spacing: 4) {
                            Text(entry.percentage)
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(Color(hex: entry.themeColors.primary))
                            
                            Text("attendance")
                                .font(.system(size: 8, weight: .medium))
                                .foregroundColor(Color(hex: entry.themeColors.onSurface).opacity(0.6))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(hex: entry.themeColors.primary).opacity(0.1))
                        .cornerRadius(16)
                    }
                }

                if entry.hasData {
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(hex: entry.themeColors.onSurface).opacity(0.1))
                                .frame(height: 8)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(hex: entry.themeColors.primary))
                                .frame(width: geometry.size.width * CGFloat(entry.progress) / 100, height: 8)
                                .animation(.easeInOut(duration: 1.0), value: entry.progress)
                        }
                    }
                    .frame(height: 8)

                    // Holiday info
                    if !entry.holidayText.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "party.popper")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color(hex: entry.themeColors.accent))
                            
                            Text(entry.holidayText)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Color(hex: entry.themeColors.onSurface).opacity(0.8))
                                .lineLimit(2)
                        }
                        .padding(8)
                        .background(Color(hex: entry.themeColors.accent).opacity(0.1))
                        .cornerRadius(8)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Log your day in OfficeLog")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(hex: entry.themeColors.onSurface).opacity(0.7))
                        
                        HStack(spacing: 12) {
                            Image(systemName: "calendar.badge.checkmark")
                                .font(.system(size: 20))
                                .foregroundColor(Color(hex: entry.themeColors.primary))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Track attendance")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(Color(hex: entry.themeColors.onSurface).opacity(0.8))
                                
                                Text("View monthly stats")
                                    .font(.system(size: 10, weight: .regular))
                                    .foregroundColor(Color(hex: entry.themeColors.onSurface).opacity(0.6))
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
        .widgetURL(URL(string: "officelog://view_summary?source=small_widget"))
    }
}

// MARK: - Large Widget View
struct OfficeLogLargeWidgetView: View {
    var entry: OfficeLogEntry
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)
    private let weekdays = ["S", "M", "T", "W", "T", "F", "S"]

    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: entry.themeColors.background))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(hex: entry.themeColors.surface))
                        .padding(4)
                )

            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Text(entry.hasData ? entry.title : "OfficeLog")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color(hex: entry.themeColors.onSurface))
                    
                    Spacer()
                    
                    if entry.hasData {
                        HStack(spacing: 8) {
                            Text(entry.percentage)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(Color(hex: entry.themeColors.primary))
                            
                            Text("attendance")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color(hex: entry.themeColors.onSurface).opacity(0.7))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(hex: entry.themeColors.primary).opacity(0.1))
                        .cornerRadius(12)
                    }
                }

                if entry.hasData && !entry.calendarData.isEmpty {
                    // Calendar view
                    VStack(spacing: 4) {
                        // Weekday headers
                        HStack {
                            ForEach(weekdays, id: \.self) { weekday in
                                Text(weekday)
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(Color(hex: entry.themeColors.onSurface).opacity(0.6))
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        
                        // Calendar grid
                        let weeks = entry.calendarData.chunked(into: 7)
                        ForEach(0..<weeks.count, id: \.self) { weekIndex in
                            HStack(spacing: 2) {
                                ForEach(weeks[weekIndex], id: \.day) { day in
                                    CalendarDayView(day: day, themeColors: entry.themeColors)
                                        .frame(maxWidth: .infinity)
                                }
                                
                                // Fill remaining slots if needed
                                if weeks[weekIndex].count < 7 {
                                    ForEach(0..<(7 - weeks[weekIndex].count), id: \.self) { _ in
                                        Color.clear
                                            .frame(maxWidth: .infinity)
                                    }
                                }
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Footer stats
                    HStack {
                        Text(entry.subtitle)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(hex: entry.themeColors.onSurface))
                        
                        Spacer()
                        
                        HStack(spacing: 16) {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color(hex: entry.themeColors.success))
                                    .frame(width: 8, height: 8)
                                Text("Present")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(Color(hex: entry.themeColors.onSurface).opacity(0.7))
                            }
                            
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color(hex: entry.themeColors.accent))
                                    .frame(width: 8, height: 8)
                                Text("Holiday")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(Color(hex: entry.themeColors.onSurface).opacity(0.7))
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Color(hex: entry.themeColors.primary).opacity(0.05))
                    .cornerRadius(8)
                } else {
                    // Placeholder content
                    VStack(spacing: 16) {
                        Spacer()
                        
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 40, weight: .light))
                            .foregroundColor(Color(hex: entry.themeColors.primary))
                        
                        VStack(spacing: 4) {
                            Text("Log your day in OfficeLog")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color(hex: entry.themeColors.onSurface))
                            
                            Text("Track your attendance and view monthly calendar")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(Color(hex: entry.themeColors.onSurface).opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                        
                        Spacer()
                    }
                }
            }
            .padding(16)
        }
        .widgetURL(URL(string: "officelog://view_calendar?source=large_widget"))
    }
}

// MARK: - Calendar Day View
struct CalendarDayView: View {
    let day: CalendarDay
    let themeColors: WidgetThemeColors

    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 4)
                .fill(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(day.isToday ? Color(hex: themeColors.primary) : Color.clear, lineWidth: 2)
                )

            // Day number
            Text("\(day.day)")
                .font(.system(size: 10, weight: day.isToday ? .bold : .medium))
                .foregroundColor(textColor)

            // Status indicator
            if day.isAttended || day.isHoliday {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Circle()
                            .fill(indicatorColor)
                            .frame(width: 4, height: 4)
                            .offset(x: -2, y: -2)
                    }
                }
            }
        }
        .frame(height: 24)
    }
    
    private var backgroundColor: Color {
        if day.isToday {
            return Color(hex: themeColors.primary)
        } else if day.isHoliday {
            return Color(hex: themeColors.accent).opacity(0.2)
        } else if day.isAttended {
            return Color(hex: themeColors.success).opacity(0.2)
        } else if !day.isWorkingDay {
            return Color(hex: themeColors.onSurface).opacity(0.05)
        } else {
            return Color.clear
        }
    }
    
    private var textColor: Color {
        if day.isToday {
            return Color(hex: themeColors.background)
        } else if !day.isWorkingDay {
            return Color(hex: themeColors.onSurface).opacity(0.4)
        } else {
            return Color(hex: themeColors.onSurface)
        }
    }
    
    private var indicatorColor: Color {
        if day.isHoliday {
            return Color(hex: themeColors.accent)
        } else if day.isAttended {
            return Color(hex: themeColors.success)
        } else {
            return Color.clear
        }
    }
}

// MARK: - Array Extension for Chunking
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
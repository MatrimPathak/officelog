import WidgetKit
import SwiftUI

// MARK: - Responsive Widget with Automatic Size Detection
struct OfficeLogResponsiveWidget: Widget {
    let kind: String = "OfficeLogResponsiveWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: OfficeLogProvider()) { entry in
            OfficeLogResponsiveWidgetView(entry: entry)
        }
        .configurationDisplayName("OfficeLog")
        .description("Responsive attendance widget that adapts to size")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge])
    }
}

// MARK: - Extra Small Widget (iOS 14+ accessoryCircular)
@available(iOS 16.0, *)
struct OfficeLogXSWidget: Widget {
    let kind: String = "OfficeLogXSWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: OfficeLogProvider()) { entry in
            OfficeLogXSWidgetView(entry: entry)
        }
        .configurationDisplayName("OfficeLog XS")
        .description("Minimal attendance percentage")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular])
    }
}

// MARK: - Small Widget
struct OfficeLogSmallWidget: Widget {
    let kind: String = "OfficeLogSmallWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: OfficeLogProvider()) { entry in
            OfficeLogSmallWidgetView(entry: entry)
        }
        .configurationDisplayName("OfficeLog Small")
        .description("Monthly attendance summary with progress")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - Medium Widget
struct OfficeLogMediumWidget: Widget {
    let kind: String = "OfficeLogMediumWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: OfficeLogProvider()) { entry in
            OfficeLogMediumWidgetView(entry: entry)
        }
        .configurationDisplayName("OfficeLog Medium")
        .description("Attendance summary with next holiday")
        .supportedFamilies([.systemMedium])
    }
}

// MARK: - Large Widget
struct OfficeLogLargeWidget: Widget {
    let kind: String = "OfficeLogLargeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: OfficeLogProvider()) { entry in
            OfficeLogLargeWidgetView(entry: entry)
        }
        .configurationDisplayName("OfficeLog Large")
        .description("Full calendar view with attendance")
        .supportedFamilies([.systemLarge, .systemExtraLarge])
    }
}

@main
struct OfficeLogWidgetBundle: WidgetBundle {
    var body: some Widget {
        OfficeLogResponsiveWidget()
        OfficeLogSmallWidget()
        OfficeLogMediumWidget()
        OfficeLogLargeWidget()
        
        // iOS 16+ widgets
        if #available(iOS 16.0, *) {
            OfficeLogXSWidget()
        }
    }
}

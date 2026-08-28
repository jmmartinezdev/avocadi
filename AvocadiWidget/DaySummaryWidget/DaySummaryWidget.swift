//
//  DaySummaryWidget.swift
//  AvocadiWidget
//
//  Created by Chema Martinez on 23/08/2026.
//

import WidgetKit
import SwiftUI

struct DaySummaryWidget: Widget {
    let kind: String = "DaySummaryWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            DaySummaryWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Today's menu")
        .description("Shows today's dish categories.")
        .supportedFamilies([.systemMedium])
    }
}

#Preview(as: .systemMedium) {
    DaySummaryWidget()
} timeline: {
    DayEntry(
        date: .now,
        days: (try? MenuLoader.load()).map { WeekViewModel(menu: $0).days } ?? []
    )
}

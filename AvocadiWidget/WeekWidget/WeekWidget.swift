//
//  WeekWidget.swift
//  AvocadiWidget
//
//  Created by Chema Martinez on 27/08/2026.
//

import WidgetKit
import SwiftUI

/// The multi-day counterpart to `DaySummaryWidget`: same `Provider`, same
/// entries, but showing the days after today as well. It's a separate widget
/// rather than extra families on `DaySummaryWidget` so both can sit on the home
/// screen at once.
struct WeekWidget: Widget {
    let kind: String = "WeekWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            WeekWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Menú de la semana")
        .description("Muestra las categorías de plato de los próximos días.")
        .supportedFamilies([.systemLarge])
    }
}

#Preview(as: .systemLarge) {
    WeekWidget()
} timeline: {
    DayEntry(
        date: .now,
        days: (try? MenuLoader.load()).map { WeekViewModel(menu: $0).days } ?? []
    )
}

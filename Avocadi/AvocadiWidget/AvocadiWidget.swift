//
//  AvocadiWidget.swift
//  AvocadiWidget
//
//  Created by Chema Martinez on 23/08/2026.
//

import WidgetKit
import SwiftUI

struct AvocadiWidget: Widget {
    let kind: String = "AvocadiWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            AvocadiWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Menú del día")
        .description("Muestra las categorías de plato de hoy.")
        .supportedFamilies([.systemMedium])
    }
}

#Preview(as: .systemMedium) {
    AvocadiWidget()
} timeline: {
    DayEntry(
        date: .now,
        days: (try? MenuLoader.load()).map { Array(WeekViewModel(menu: $0).days.prefix(4)) } ?? []
    )
}

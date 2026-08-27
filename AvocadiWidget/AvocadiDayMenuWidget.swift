//
//  AvocadiDayMenuWidget.swift
//  AvocadiWidget
//
//  Created by Chema Martinez on 27/08/2026.
//

import WidgetKit
import SwiftUI

/// The full-detail counterpart to `AvocadiWidget` and `AvocadiWeekWidget`:
/// same `Provider` and same entries, but the extra-large portrait tile is the
/// first one tall enough to list today's dishes rather than stopping at the
/// category names.
///
/// `systemExtraLargePortrait` only exists from iOS 27 on, while the rest of
/// the extension still targets 26.5, so `AvocadiWidgetBundle` registers this
/// widget behind an availability check.
@available(iOS 27.0, *)
struct AvocadiDayMenuWidget: Widget {
    let kind: String = "AvocadiDayMenuWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            AvocadiDayMenuWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Menú completo de hoy")
        .description("Muestra todos los platos de hoy, del almuerzo y de la cena.")
        .supportedFamilies([.systemExtraLargePortrait])
    }
}

@available(iOS 27.0, *)
#Preview(as: .systemExtraLargePortrait) {
    AvocadiDayMenuWidget()
} timeline: {
    DayEntry(
        date: .now,
        days: (try? MenuLoader.load()).map { WeekViewModel(menu: $0).days } ?? []
    )
}

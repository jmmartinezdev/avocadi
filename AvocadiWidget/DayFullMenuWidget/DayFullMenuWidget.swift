//
//  DayFullMenuWidget.swift
//  AvocadiWidget
//
//  Created by Chema Martinez on 27/08/2026.
//

import WidgetKit
import SwiftUI

/// The full-detail counterpart to `DaySummaryWidget` and `WeekWidget`: same
/// `Provider` and same entries, but the extra-large portrait tile is the first
/// one tall enough to list today's dishes rather than stopping at the category
/// names.
///
/// `systemExtraLargePortrait` only exists from iOS 27 on, while the rest of
/// the extension still targets 26.5, so `AvocadiWidgetBundle` registers this
/// widget behind an availability check.
@available(iOS 27.0, *)
struct DayFullMenuWidget: Widget {
    let kind: String = "DayFullMenuWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            DayFullMenuWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Menú completo de hoy")
        .description("Muestra todos los platos de hoy, del almuerzo y de la cena.")
        .supportedFamilies([.systemExtraLargePortrait])
    }
}

@available(iOS 27.0, *)
#Preview(as: .systemExtraLargePortrait) {
    DayFullMenuWidget()
} timeline: {
    DayEntry(
        date: .now,
        days: (try? MenuLoader.load()).map { WeekViewModel(menu: $0).days } ?? []
    )
}

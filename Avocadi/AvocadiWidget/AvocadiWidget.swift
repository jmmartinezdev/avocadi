//
//  AvocadiWidget.swift
//  AvocadiWidget
//
//  Created by Chema Martinez on 23/08/2026.
//

import WidgetKit
import SwiftUI

/// A timeline entry carrying a short rotated window of days starting at `date`.
///
/// Storing a window (rather than just "today") costs nothing for the medium
/// widget, which only reads `days.first`, but lets a future larger size show
/// several upcoming days from the very same entries with no provider changes.
/// An empty `days` array means the menu failed to load.
struct DayEntry: TimelineEntry {
    let date: Date
    let days: [DayViewModel]
}

struct Provider: TimelineProvider {
    /// How many upcoming days each entry carries.
    private static let windowSize = 4
    /// How many days ahead to pre-compute entries for before requesting a reload.
    private static let daysAhead = 8

    private static func loadMenu() -> Menu? {
        try? MenuLoader.load()
    }

    private static func days(for date: Date, menu: Menu, calendar: Calendar) -> [DayViewModel] {
        Array(WeekViewModel(menu: menu, referenceDate: date, calendar: calendar).days.prefix(windowSize))
    }

    func placeholder(in context: Context) -> DayEntry {
        let calendar = Calendar.current
        guard let menu = Self.loadMenu() else {
            return DayEntry(date: .now, days: [])
        }
        return DayEntry(date: .now, days: Self.days(for: .now, menu: menu, calendar: calendar))
    }

    func getSnapshot(in context: Context, completion: @escaping (DayEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DayEntry>) -> Void) {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: .now)
        // Ask WidgetKit to re-run this provider every day, not just once the
        // pre-computed window runs out. Each entry's own `date` is what makes
        // "today" display correctly in between reloads; this is just a safety
        // net so a skipped/delayed reload never leaves the window more than a
        // day stale, and so a transient menu-load failure gets retried.
        let nextReload = calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? startOfToday

        guard let menu = Self.loadMenu() else {
            completion(Timeline(entries: [DayEntry(date: .now, days: [])], policy: .after(nextReload)))
            return
        }

        let entries: [DayEntry] = (0..<Self.daysAhead).map { offset in
            let entryDate = calendar.date(byAdding: .day, value: offset, to: startOfToday) ?? startOfToday
            return DayEntry(date: entryDate, days: Self.days(for: entryDate, menu: menu, calendar: calendar))
        }

        completion(Timeline(entries: entries, policy: .after(nextReload)))
    }
}

/// Today's day name plus, per meal, the meal name and its dish category name.
/// Full dish lists don't fit at this size — see `DishCategoryView` for those.
struct CompactDayView: View {
    let day: DayViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(day.dayName)
                .font(.headline)

            ForEach(day.mealPlans) { plan in
                VStack(alignment: .leading, spacing: 1) {
                    Text(plan.mealName)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(plan.dishCategory.name)
                        .font(.subheadline)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                }
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct EmptyMenuView: View {
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "fork.knife")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("No hay menú disponible")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct AvocadiWidgetEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        Group {
            if let today = entry.days.first {
                CompactDayView(day: today)
            } else {
                EmptyMenuView()
            }
        }
        // Tapping anywhere on the widget opens the app and scrolls WeekView
        // back to today, even if it was left scrolled further down.
        .widgetURL(URL(string: "avocadi://today"))
    }
}

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

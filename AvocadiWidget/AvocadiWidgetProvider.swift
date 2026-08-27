//
//  AvocadiWidgetProvider.swift
//  AvocadiWidget
//
//  Created by Chema Martinez on 23/08/2026.
//

import WidgetKit

/// A timeline entry carrying the whole week, rotated so the day matching
/// `date` comes first.
///
/// Carrying every day (rather than just "today") costs nothing — the rotated
/// week is what `WeekViewModel` produces anyway — and lets each widget size
/// take the prefix it needs from the very same entries: `DaySummaryWidget`
/// reads `days.first`, `WeekWidget` reads the first five.
/// An empty `days` array means the menu failed to load.
struct DayEntry: TimelineEntry {
    let date: Date
    let days: [DayViewModel]
}

struct Provider: TimelineProvider {
    /// How many days ahead to pre-compute entries for before requesting a reload.
    private static let daysAhead = 8

    private static func loadMenu() -> Menu? {
        try? MenuLoader.load()
    }

    private static func days(for date: Date, menu: Menu, calendar: Calendar) -> [DayViewModel] {
        WeekViewModel(menu: menu, referenceDate: date, calendar: calendar).days
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

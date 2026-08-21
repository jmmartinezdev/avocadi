//
//  WeekViewModel.swift
//  Avocadi
//
//  Created by Chema Martinez on 21/8/26.
//

import Foundation

/// The whole week's menu, resolved into `[DayViewModel]` and ready to hand
/// straight to `WeekView`.
struct WeekViewModel {
    let days: [DayViewModel]

    init(days: [DayViewModel]) {
        self.days = days
    }

    /// Resolves every day in `menu` via `DayViewModel.makeAll(from:)`, then
    /// reorders them so today's day comes first (see `Day`: 1 = Monday ... 7 = Sunday).
    /// `referenceDate`/`calendar` default to "now", but can be overridden for
    /// previews/tests.
    init(menu: Menu, referenceDate: Date = Date(), calendar: Calendar = .current) {
        let orderedDays = DayViewModel.makeAll(from: menu).sorted { $0.dayNumber < $1.dayNumber }
        self.init(days: Self.rotated(orderedDays, toStartAt: referenceDate, calendar: calendar))
    }

    /// Loads `Menu.json` from the app bundle and resolves it.
    ///
    /// The JSON is build-time-fixed content shipped with the app, so a
    /// failure here means the bundled data itself is broken — fail loudly
    /// rather than silently show an empty week.
    static func loadFromBundle() -> WeekViewModel {
        let menu = try! MenuLoader.load()
        return WeekViewModel(menu: menu)
    }

    /// Rotates `days` (sorted by `dayNumber`, 1...7) so the day matching
    /// `date`'s weekday comes first, wrapping the earlier days to the end.
    /// Returns `days` unchanged if no day matches (shouldn't happen with a
    /// full 7-day week).
    private static func rotated(_ days: [DayViewModel], toStartAt date: Date, calendar: Calendar) -> [DayViewModel] {
        let today = mondayBasedDayNumber(for: date, calendar: calendar)
        guard let startIndex = days.firstIndex(where: { $0.dayNumber == today }) else {
            return days
        }
        return Array(days[startIndex...] + days[..<startIndex])
    }

    /// Converts `Calendar`'s weekday (1 = Sunday ... 7 = Saturday) into a
    /// Monday-based day number (1 = Monday ... 7 = Sunday), matching `Day.day`.
    private static func mondayBasedDayNumber(for date: Date, calendar: Calendar) -> Int {
        let sundayBasedWeekday = calendar.component(.weekday, from: date)
        return ((sundayBasedWeekday + 5) % 7) + 1
    }
}

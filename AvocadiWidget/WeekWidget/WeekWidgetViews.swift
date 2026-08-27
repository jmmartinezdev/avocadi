//
//  WeekWidgetViews.swift
//  AvocadiWidget
//
//  Created by Chema Martinez on 27/08/2026.
//

import SwiftUI
import WidgetKit

/// Several days at a glance: each day's name followed by one row per meal,
/// pairing the meal name with its dish category name.
///
/// Like `DaySummaryView` this stops at category names — the dishes themselves
/// don't fit even at this size, and are what opening the app is for.
struct WeekAheadView: View {
    let days: [DayViewModel]

    /// Width reserved for the meal name so every category name in the widget
    /// starts on the same vertical line, rather than each day's rows being
    /// indented differently by "Almuerzos" vs "Cenas".
    private let mealNameWidth: CGFloat = 62

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(days.enumerated()), id: \.element.id) { index, day in
                VStack(alignment: .leading, spacing: 2) {
                    // Today leads the list, so give it a little more weight
                    // than the days that merely follow it.
                    Text(day.dayName)
                        .font(index == 0 ? .headline : .subheadline.weight(.semibold))

                    ForEach(day.mealPlans) { plan in
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text(plan.mealName)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .frame(width: mealNameWidth, alignment: .leading)
                            // One line per category keeps every day the same
                            // height, which is what lets five of them fit;
                            // the longest names shrink instead of wrapping.
                            Text(plan.dishCategory.name)
                                .font(.caption)
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct WeekWidgetEntryView: View {
    var entry: Provider.Entry

    /// How many of the entry's days the tile has room for.
    private static let visibleDays = 5

    var body: some View {
        Group {
            if entry.days.isEmpty {
                EmptyMenuView()
            } else {
                WeekAheadView(days: Array(entry.days.prefix(Self.visibleDays)))
            }
        }
        // Tapping anywhere on the widget opens the app and scrolls WeekView
        // back to today, even if it was left scrolled further down.
        .widgetURL(URL(string: "avocadi://today"))
    }
}

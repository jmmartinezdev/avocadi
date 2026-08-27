//
//  DaySummaryWidgetViews.swift
//  AvocadiWidget
//
//  Created by Chema Martinez on 23/08/2026.
//

import SwiftUI
import WidgetKit

/// Today's day name plus, per meal, the meal name and its dish category name.
/// Full dish lists don't fit at this size — see `DishCategoryView` for those.
struct DaySummaryView: View {
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

struct DaySummaryWidgetEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        Group {
            if let today = entry.days.first {
                DaySummaryView(day: today)
            } else {
                EmptyMenuView()
            }
        }
        // Tapping anywhere on the widget opens the app and scrolls WeekView
        // back to today, even if it was left scrolled further down.
        .widgetURL(URL(string: "avocadi://today"))
    }
}

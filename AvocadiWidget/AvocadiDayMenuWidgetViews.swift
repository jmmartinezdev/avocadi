//
//  AvocadiDayMenuWidgetViews.swift
//  AvocadiWidget
//
//  Created by Chema Martinez on 27/08/2026.
//

import SwiftUI
import WidgetKit

/// One of the typographic steps `DayMenuView` tries, roomiest first.
///
/// A single day is 10 to 16 dishes whose names average 65 characters (131 at
/// the longest), so how large the text can be depends on both the day and the
/// device: the busiest day fits at 13pt on a big iPhone or a 13" iPad, needs
/// 12pt on an 11" iPad and 11pt on a small iPhone. Rather than pick one size
/// and hope, `DayMenuView` walks these in order and keeps the first that fits.
///
/// The sizes are text styles rather than fixed point sizes so they keep
/// following Dynamic Type; at the default size their dish text measures
/// 15/13/12/11pt, which is what each step was sized against.
enum DayMenuScale {
    case comfortable, compact, dense, minimal

    var dayName: Font {
        switch self {
        case .comfortable: .title2.bold()
        case .compact: .title3.bold()
        case .dense: .headline
        case .minimal: .callout.bold()
        }
    }

    var mealName: Font {
        switch self {
        case .comfortable: .footnote.weight(.semibold)
        case .compact: .caption.weight(.semibold)
        case .dense, .minimal: .caption2.weight(.semibold)
        }
    }

    var categoryName: Font {
        switch self {
        case .comfortable: .headline
        case .compact: .subheadline.weight(.semibold)
        case .dense: .footnote.weight(.semibold)
        case .minimal: .caption.weight(.semibold)
        }
    }

    var dish: Font {
        switch self {
        case .comfortable: .subheadline
        case .compact: .footnote
        case .dense: .caption
        case .minimal: .caption2
        }
    }

    /// Width reserved for the "1.", "2." … column, so a dish name that wraps
    /// lines up under its own first line instead of under its number.
    var numberWidth: CGFloat {
        switch self {
        case .comfortable: 18
        case .compact: 16
        case .dense: 15
        case .minimal: 14
        }
    }
}

/// A day's full menu at one given scale: the day name, then each meal's name,
/// the category assigned to it and every dish in that category.
///
/// Unlike `CompactDayView` and `WeekAheadView`, which stop at the category
/// name, this lists the dishes themselves — that's the whole point of the
/// extra-large portrait tile. Nothing is line-limited: the long names are
/// meant to wrap to their two or three lines.
struct DayMenuLayout: View {
    let day: DayViewModel
    let scale: DayMenuScale

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(day.dayName)
                .font(scale.dayName)

            ForEach(day.mealPlans) { plan in
                VStack(alignment: .leading, spacing: 3) {
                    Text(plan.mealName)
                        .font(scale.mealName)
                        .foregroundStyle(.secondary)

                    Text(plan.dishCategory.name)
                        .font(scale.categoryName)

                    // Numbered the same way as DishCategoryView in the app, so
                    // the widget and the day screen read as the same list.
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(plan.dishCategory.dishes.enumerated()), id: \.element.id) { index, dish in
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text("\(index + 1).")
                                    .foregroundStyle(.secondary)
                                    .frame(width: scale.numberWidth, alignment: .trailing)
                                Text(dish.name)
                            }
                        }
                    }
                    .font(scale.dish)
                    .padding(.top, 1)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

/// Picks the largest `DayMenuScale` the tile has room for.
struct DayMenuView: View {
    let day: DayViewModel

    var body: some View {
        ViewThatFits(in: .vertical) {
            DayMenuLayout(day: day, scale: .comfortable)
            DayMenuLayout(day: day, scale: .compact)
            DayMenuLayout(day: day, scale: .dense)
            // Last resort, so it has to fit rather than merely try to: the
            // steps above follow Dynamic Type and drop out one by one as it
            // grows, and past a point no readable size fits 16 dish names.
            // Capping Dynamic Type here pins this step to the geometry it was
            // measured against instead of letting the list run off the tile,
            // which a widget can't scroll to recover from.
            DayMenuLayout(day: day, scale: .minimal)
                .dynamicTypeSize(...DynamicTypeSize.large)
                .minimumScaleFactor(0.8)
        }
    }
}

struct AvocadiDayMenuWidgetEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        Group {
            if let today = entry.days.first {
                DayMenuView(day: today)
            } else {
                EmptyMenuView()
            }
        }
        // Tapping anywhere on the widget opens the app and scrolls WeekView
        // back to today, even if it was left scrolled further down.
        .widgetURL(URL(string: "avocadi://today"))
    }
}

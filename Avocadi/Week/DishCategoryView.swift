//
//  DishCategoryView.swift
//  Avocadi
//
//  Created by Chema Martinez on 21/8/26.
//

import SwiftUI

/// Shows a dish category's name as a title and its dishes as a numbered list.
///
/// This is a plain content view (no scrolling or outer padding of its own)
/// so it composes cleanly inside a container that already scrolls, such as
/// `DayView`.
struct DishCategoryView: View {
    let dishCategory: DishCategory

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(dishCategory.name)
                .font(.title2.bold())

            if let comment = dishCategory.comment {
                Text(comment)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(dishCategory.dishes.enumerated()), id: \.element.id) { index, dish in
                    NavigationLink(value: dish) {
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text(verbatim: "\(index + 1).")
                                .foregroundStyle(.secondary)
                            Text(dish.name)
                        }
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.primary)
                }
            }
        }
    }
}

#Preview {
    ScrollView {
        DishCategoryView(
            dishCategory: DishCategory(
                id: "20-0",
                name: "Verduras + huevo",
                comment: nil,
                dishes: [
                    Dish(id: "20-0-0", name: "Tortilla francesa + queso fresco de cabra"),
                    Dish(id: "20-0-1", name: "Tortilla rellena de espinacas frescas, jamón cocido y queso mozzarella"),
                    Dish(id: "20-0-2", name: "Fajita integral con huevo plancha, tomate en rodajas y aguacate")
                ]
            )
        )
        .padding()
    }
}

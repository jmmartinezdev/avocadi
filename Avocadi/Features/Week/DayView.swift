//
//  DayView.swift
//  Avocadi
//
//  Created by Chema Martinez on 21/8/26.
//

import SwiftUI

/// Shows a day's plan: a large title with the day of the week, then each
/// meal's name followed by the `DishCategoryView` for the category assigned
/// to it.
///
/// This is a plain content view (no scrolling of its own) so it composes
/// cleanly inside a container that already scrolls, such as `WeekView`.
struct DayView: View {
    let dayViewModel: DayViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(dayViewModel.dayName)
                .font(.largeTitle.bold())

            ForEach(dayViewModel.mealPlans) { mealPlan in
                VStack(alignment: .leading, spacing: 12) {
                    Text(mealPlan.mealName)
                        .font(.title3.bold())

                    DishCategoryView(dishCategory: mealPlan.dishCategory)
                }
            }
        }
        .padding()
    }
}

#Preview {
    ScrollView {
        DayView(
            dayViewModel: DayViewModel(
                id: "1-1",
                dayNumber: 1,
                dayName: "Lunes",
                mealPlans: [
                    DayViewModel.MealPlan(
                        id: "10",
                        mealName: "Almuerzos",
                        dishCategory: DishCategory(
                            id: "10-0",
                            name: "Legumbre + verduras",
                            comment: nil,
                            dishes: [
                                Dish(id: "10-0-0", name: "Lentejas/ Puchero / Habichuelas / guisadas con verduras"),
                                Dish(id: "10-0-1", name: "Hélices de lentejas/ guisantes / garbanzos con boloñesa casera")
                            ]
                        )
                    ),
                    DayViewModel.MealPlan(
                        id: "20",
                        mealName: "Cenas",
                        dishCategory: DishCategory(
                            id: "20-0",
                            name: "Verduras + huevo",
                            comment: nil,
                            dishes: [
                                Dish(id: "20-0-0", name: "Tortilla francesa + queso fresco de cabra"),
                                Dish(id: "20-0-1", name: "Tortilla rellena de espinacas frescas, jamón cocido y queso mozzarella")
                            ]
                        )
                    )
                ]
            )
        )
    }
    .environment(FavoritesStore.preview)
}

//
//  DayViewModel.swift
//  Avocadi
//
//  Created by Chema Martinez on 21/8/26.
//

import Foundation

/// A single day's menu, resolved into ready-to-display data: the day number
/// paired with each meal's name and the full `DishCategory` assigned to it,
/// in the same order as `Menu.meals`.
///
/// `Day` only stores id references (`DayMeal.mealId` / `dishCategoryId`);
/// `DayViewModel` resolves those against a `Menu` once, so views never have
/// to look ids up themselves.
struct DayViewModel: Identifiable {
    let id: String
    let dayNumber: Int
    let dayName: String
    let mealPlans: [MealPlan]

    /// One meal slot for the day, e.g. "Almuerzos" paired with the
    /// "Verduras + huevo" category assigned to it.
    struct MealPlan: Identifiable {
        let id: String
        let mealName: String
        let dishCategory: DishCategory
    }
}

extension DayViewModel {
    /// Resolves `day`'s meal/dish category id references against `menu`.
    ///
    /// Returns `nil` if `day` references a meal or dish category id that
    /// isn't present in `menu` — that signals inconsistent JSON rather than
    /// something to silently degrade from.
    static func make(from day: Day, in menu: Menu) -> DayViewModel? {
        let mealPlans: [MealPlan] = day.meals.compactMap { dayMeal in
            guard let meal = menu.meals.first(where: { $0.id == dayMeal.mealId }),
                  let dishCategory = meal.dishCategories.first(where: { $0.id == dayMeal.dishCategoryId }) else {
                return nil
            }
            return MealPlan(id: meal.id, mealName: meal.name, dishCategory: dishCategory)
        }

        guard mealPlans.count == day.meals.count else { return nil }

        return DayViewModel(id: day.id, dayNumber: day.day, dayName: day.name, mealPlans: mealPlans)
    }

    /// Resolves every day in `menu`, skipping any day whose ids fail to resolve.
    static func makeAll(from menu: Menu) -> [DayViewModel] {
        menu.days.compactMap { make(from: $0, in: menu) }
    }
}

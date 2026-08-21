//
//  Day.swift
//  Avocadi
//
//  Created by Chema Martinez on 20/8/26.
//

import Foundation

/// A single day of the menu plan, assigning a dish category to each meal.
struct Day: Codable, Identifiable {
    let id: String
    let day: Int
    let name: String
    let meals: [DayMeal]
}

/// Links a meal (by id) to the dish category assigned to it for a given day.
struct DayMeal: Codable {
    let mealId: String
    let dishCategoryId: String
}

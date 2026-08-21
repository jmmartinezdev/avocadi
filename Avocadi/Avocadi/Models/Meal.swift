//
//  Meal.swift
//  Avocadi
//
//  Created by Chema Martinez on 20/8/26.
//

import Foundation

/// A meal of the day, e.g. "Almuerzos" or "Cenas".
struct Meal: Codable, Identifiable {
    let id: String
    let name: String
    let dishCategories: [DishCategory]
}

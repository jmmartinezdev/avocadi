//
//  DishCategory.swift
//  Avocadi
//
//  Created by Chema Martinez on 20/8/26.
//

import Foundation

/// A category of dishes within a meal, e.g. "Legumbre + verduras".
struct DishCategory: Codable, Identifiable {
    let id: String
    let name: String
    /// Optional note about the category, e.g. a serving suggestion.
    let comment: String?
    let dishes: [Dish]
}

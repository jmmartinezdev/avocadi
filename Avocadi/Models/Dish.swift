//
//  Dish.swift
//  Avocadi
//
//  Created by Chema Martinez on 20/8/26.
//

import Foundation

/// A single dish suggestion within a dish category.
struct Dish: Codable, Identifiable, Hashable {
    let id: String
    let name: String
}

//
//  Menu.swift
//  Avocadi
//
//  Created by Chema Martinez on 20/8/26.
//

import Foundation

/// Root object decoded from `Menu.json`.
struct Menu: Codable {
    let meals: [Meal]
    let days: [Day]
}

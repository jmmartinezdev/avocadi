//
//  AvocadiApp.swift
//  Avocadi
//
//  Created by Chema Martinez on 20/8/26.
//

import SwiftData
import SwiftUI

@main
struct AvocadiApp: App {
    // `@State` so the store is built once for the process and survives scene
    // updates: every screen has to read and write the same instance for a
    // heart tapped on the detail screen to show up on the week list behind it.
    @State private var favorites = FavoritesStore()

    var body: some Scene {
        WindowGroup {
            WeekView(weekViewModel: .loadFromBundle())
                .environment(favorites)
        }
        .modelContainer(for: DishAIContent.self)
    }
}

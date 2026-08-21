//
//  AvocadiApp.swift
//  Avocadi
//
//  Created by Chema Martinez on 20/8/26.
//

import SwiftUI

@main
struct AvocadiApp: App {
    var body: some Scene {
        WindowGroup {
            WeekView(weekViewModel: .loadFromBundle())
        }
    }
}

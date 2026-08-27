//
//  AvocadiWidgetBundle.swift
//  AvocadiWidget
//
//  Created by Chema Martinez on 23/08/2026.
//

import WidgetKit
import SwiftUI

@main
struct AvocadiWidgetBundle: WidgetBundle {
    var body: some Widget {
        DaySummaryWidget()
        WeekWidget()
        if #available(iOS 27.0, *) {
            DayFullMenuWidget()
        }
    }
}

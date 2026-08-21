//
//  WeekView.swift
//  Avocadi
//
//  Created by Chema Martinez on 21/8/26.
//

import SwiftUI

/// The app's root screen: every day of the week's `DayView`, stacked in a
/// single scroll.
struct WeekView: View {
    let weekViewModel: WeekViewModel

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                ForEach(weekViewModel.days) { day in
                    DayView(dayViewModel: day)

                    Divider()
                }
            }
        }
    }
}

#Preview {
    WeekView(weekViewModel: .loadFromBundle())
}

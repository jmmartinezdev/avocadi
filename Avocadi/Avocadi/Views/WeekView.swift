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

    @State private var isScrolledDown = false
    @State private var scrollPosition = ScrollPosition(edge: .top)

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                ForEach(weekViewModel.days) { day in
                    DayView(dayViewModel: day)

                    Divider()
                }
            }
        }
        .scrollPosition($scrollPosition)
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.contentOffset.y
        } action: { _, newOffset in
            isScrolledDown = newOffset > 40
        }
        .overlay(alignment: .bottomTrailing) {
            if isScrolledDown {
                Button {
                    withAnimation {
                        scrollPosition.scrollTo(edge: .top)
                    }
                } label: {
                    Image(systemName: "arrow.up")
                        .font(.title3.weight(.semibold))
                        .frame(width: 44, height: 44)
                }
                .glassEffect(.regular.interactive(), in: .circle)
                .padding()
                .transition(.opacity.combined(with: .scale))
                .accessibilityLabel("Scroll to top")
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isScrolledDown)
        .onOpenURL { url in
            // Lets tapping the AvocadiWidget home-screen widget land back on
            // today even if this view was left scrolled further down.
            guard url.host == "today" else { return }
            withAnimation {
                scrollPosition.scrollTo(edge: .top)
            }
        }
    }
}

#Preview {
    WeekView(weekViewModel: .loadFromBundle())
}

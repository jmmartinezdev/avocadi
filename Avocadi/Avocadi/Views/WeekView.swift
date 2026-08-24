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
    @State private var weekViewModel: WeekViewModel
    @Environment(\.scenePhase) private var scenePhase

    @State private var isScrolledDown = false
    @State private var scrollPosition = ScrollPosition(edge: .top)

    init(weekViewModel: WeekViewModel) {
        _weekViewModel = State(initialValue: weekViewModel)
    }

    var body: some View {
        NavigationStack {
            weekScrollView
                .navigationDestination(for: Dish.self) { dish in
                    DishDetailView(dish: dish)
                }
        }
    }

    private var weekScrollView: some View {
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
                    scrollToTop()
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
            scrollToTop()
        }
        .onChange(of: scenePhase) { _, newPhase in
            // Recomputes the day rotation when the app returns to the
            // foreground, since it's otherwise only computed once at launch
            // and would stay pinned to whatever day was "today" back then.
            // Only scroll back to top if that actually changed something.
            guard newPhase == .active else { return }
            if weekViewModel.refreshIfNeeded() {
                scrollToTop()
            }
        }
    }

    private func scrollToTop() {
        withAnimation {
            scrollPosition.scrollTo(edge: .top)
        }
    }
}

#Preview {
    WeekView(weekViewModel: .loadFromBundle())
}

//
//  AvocadiTests.swift
//  AvocadiTests
//
//  Created by Chema Martinez on 20/8/26.
//

import Testing
import Foundation
@testable import Avocadi

/// Builds a 1-meal, 7-day menu where each day maps to a distinct dish
/// category (dc1...dc7), so rotation order can be verified by `dayNumber`.
private func makeMenu() -> Menu {
    let dishCategories = (1...7).map { DishCategory(id: "dc\($0)", name: "Category \($0)", comment: nil, dishes: []) }
    let meal = Meal(id: "m1", name: "Almuerzos", dishCategories: dishCategories)
    let days = (1...7).map { n in
        Day(id: "d\(n)", day: n, name: "Day \(n)", meals: [DayMeal(mealId: "m1", dishCategoryId: "dc\(n)")])
    }
    return Menu(meals: [meal], days: days)
}

/// Fixed UTC calendar so date-based tests don't depend on the machine's
/// timezone/locale.
private var utcCalendar: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar
}

private func date(year: Int, month: Int, day: Int) -> Date {
    utcCalendar.date(from: DateComponents(year: year, month: month, day: day))!
}

struct WeekViewModelTests {

    @Test func mondayReferenceStartsWeekAtDayOne() {
        // 2026-08-17 is a Monday.
        let week = WeekViewModel(menu: makeMenu(), referenceDate: date(year: 2026, month: 8, day: 17), calendar: utcCalendar)
        #expect(week.days.map(\.dayNumber) == [1, 2, 3, 4, 5, 6, 7])
    }

    @Test func sundayReferenceWrapsWeekToStartAtDaySeven() {
        // 2026-08-23 is a Sunday.
        let week = WeekViewModel(menu: makeMenu(), referenceDate: date(year: 2026, month: 8, day: 23), calendar: utcCalendar)
        #expect(week.days.map(\.dayNumber) == [7, 1, 2, 3, 4, 5, 6])
    }

    @Test func wednesdayReferenceStartsWeekAtDayThree() {
        // 2026-08-19 is a Wednesday.
        let week = WeekViewModel(menu: makeMenu(), referenceDate: date(year: 2026, month: 8, day: 19), calendar: utcCalendar)
        #expect(week.days.map(\.dayNumber) == [3, 4, 5, 6, 7, 1, 2])
    }

    @Test func noDaysAreDropped() {
        let week = WeekViewModel(menu: makeMenu(), referenceDate: date(year: 2026, month: 8, day: 17), calendar: utcCalendar)
        #expect(week.days.count == 7)
    }
}

struct DayViewModelTests {

    private let dishCategory = DishCategory(id: "dc1", name: "Legumbre + verduras", comment: "Con aceite", dishes: [Dish(id: "dish1", name: "Lentejas")])
    private lazy var meal = Meal(id: "m1", name: "Almuerzos", dishCategories: [dishCategory])
    private lazy var menu = Menu(meals: [meal], days: [])

    @Test mutating func resolvesValidDayIntoMatchingMealAndDishCategory() {
        let day = Day(id: "d1", day: 1, name: "Lunes", meals: [DayMeal(mealId: "m1", dishCategoryId: "dc1")])

        let result = DayViewModel.make(from: day, in: menu)

        #expect(result != nil)
        #expect(result?.dayNumber == 1)
        #expect(result?.dayName == "Lunes")
        #expect(result?.mealPlans.first?.mealName == "Almuerzos")
        #expect(result?.mealPlans.first?.dishCategory.id == "dc1")
    }

    @Test mutating func returnsNilWhenMealIdDoesNotResolve() {
        let day = Day(id: "d1", day: 1, name: "Lunes", meals: [DayMeal(mealId: "missing-meal", dishCategoryId: "dc1")])

        #expect(DayViewModel.make(from: day, in: menu) == nil)
    }

    @Test mutating func returnsNilWhenDishCategoryIdDoesNotResolve() {
        let day = Day(id: "d1", day: 1, name: "Lunes", meals: [DayMeal(mealId: "m1", dishCategoryId: "missing-category")])

        #expect(DayViewModel.make(from: day, in: menu) == nil)
    }

    @Test mutating func makeAllSkipsInvalidDaysButKeepsValidOnes() {
        let validDay = Day(id: "d1", day: 1, name: "Lunes", meals: [DayMeal(mealId: "m1", dishCategoryId: "dc1")])
        let invalidDay = Day(id: "d2", day: 2, name: "Martes", meals: [DayMeal(mealId: "missing-meal", dishCategoryId: "dc1")])
        let anotherValidDay = Day(id: "d3", day: 3, name: "Miercoles", meals: [DayMeal(mealId: "m1", dishCategoryId: "dc1")])
        let menuWithMixedDays = Menu(meals: [meal], days: [validDay, invalidDay, anotherValidDay])

        let result = DayViewModel.makeAll(from: menuWithMixedDays)

        #expect(result.map(\.id) == ["d1", "d3"])
    }
}

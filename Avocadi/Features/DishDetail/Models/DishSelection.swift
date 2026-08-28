//
//  DishSelection.swift
//  Avocadi
//
//  Created by Chema Martinez on 28/8/26.
//

/// What `DishDetailView` is pushed with: the dish, plus the name of the
/// category it was tapped under.
///
/// `Dish` alone would be the obvious navigation value, but it carries no
/// reference to its category — the relation only runs the other way, from
/// `DishCategory.dishes`. Pairing the two here lets the detail screen name
/// the category without the model layer having to grow a back-pointer that
/// `Menu.json` doesn't have.
struct DishSelection: Hashable {
    let dish: Dish
    let categoryName: String
}

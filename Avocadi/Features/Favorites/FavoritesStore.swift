//
//  FavoritesStore.swift
//  Avocadi
//
//  Created by Chema Martinez on 29/8/26.
//

import Foundation
import Observation

/// The dishes marked as favorites, kept on this device.
///
/// Deliberately not SwiftData, unlike `DishAIContent` next door. Two reasons,
/// and neither is about size: `@Query` is a view property, so reading it per
/// dish would mean fetching the whole table inside `DishCategoryView` — a leaf
/// content view built fourteen times over a week — and a favorite living in
/// the same container as generated content puts it one careless line away from
/// being wiped by Settings' "Delete generated content". Hearts are the user's
/// own input; that button's scope is what the machine wrote.
///
/// Held as a single `Set` rather than a value per dish because `@Observable`
/// tracks whole stored properties: one toggle invalidates every view that read
/// the set, which is precisely what makes the heart appear on the week list
/// behind the detail screen without any refresh plumbing.
@MainActor
@Observable
final class FavoritesStore {
    static let defaultsKey = "favoriteDishIDs"

    private(set) var favoriteDishIDs: Set<String>

    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        // `stringArray(forKey:)` is nil for a missing value *and* for one of
        // the wrong type, so anything unreadable under the key degrades to
        // "nothing is favorited" instead of trapping.
        favoriteDishIDs = Set(defaults.stringArray(forKey: Self.defaultsKey) ?? [])
    }

    func contains(_ dishID: String) -> Bool {
        favoriteDishIDs.contains(dishID)
    }

    func toggle(_ dishID: String) {
        if favoriteDishIDs.contains(dishID) {
            favoriteDishIDs.remove(dishID)
        } else {
            favoriteDishIDs.insert(dishID)
        }
        persist()
    }

    func clear() {
        favoriteDishIDs = []
        persist()
    }

    /// Written as a plain `[String]`, which needs no encoding to be a valid
    /// plist value, and sorted so the stored form doesn't churn on every
    /// toggle just because a `Set` reordered itself.
    private func persist() {
        defaults.set(favoriteDishIDs.sorted(), forKey: Self.defaultsKey)
    }
}

extension FavoritesStore {
    /// A store for Xcode previews, kept in its own defaults suite so a heart
    /// tapped in the canvas doesn't land in the simulator's real favorites.
    ///
    /// Previews need one because `@Environment(FavoritesStore.self)` is
    /// non-optional and traps when nothing injected it — including in the
    /// canvas. Declaring the property as optional instead would keep previews
    /// working untouched, at the price of a missed injection in the real app
    /// showing up as a heart that silently does nothing.
    static var preview: FavoritesStore {
        FavoritesStore(defaults: UserDefaults(suiteName: "preview") ?? .standard)
    }
}

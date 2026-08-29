//
//  FavoritesStoreTests.swift
//  AvocadiTests
//
//  Created by Chema Martinez on 29/8/26.
//

import Foundation
import Testing
@testable import Avocadi

/// Covers `FavoritesStore` against real `UserDefaults`, in a throwaway suite
/// per test rather than the standard domain, which is shared with whatever
/// else the test host has written.
///
/// The point of most of these is the storage rather than the set arithmetic:
/// a favorite that doesn't survive relaunch is the whole feature failing, and
/// nothing else in the app would notice.
@MainActor
struct FavoritesStoreTests {

    /// A suite named per test and torn down afterwards, so tests can't see
    /// each other's favorites. `struct` suites have no `deinit` to clean up
    /// in, hence the closure.
    private func withTemporaryDefaults(_ body: (UserDefaults) throws -> Void) rethrows {
        let name = "FavoritesStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        try body(defaults)
    }

    @Test func newStoreStartsWithNothingFavorited() {
        withTemporaryDefaults { defaults in
            let store = FavoritesStore(defaults: defaults)

            #expect(store.favoriteDishIDs.isEmpty)
            #expect(store.contains("10-0-0") == false)
        }
    }

    @Test func togglingMarksADishAndTogglingAgainClearsIt() {
        withTemporaryDefaults { defaults in
            let store = FavoritesStore(defaults: defaults)

            store.toggle("10-0-0")
            #expect(store.contains("10-0-0"))

            store.toggle("10-0-0")
            #expect(store.contains("10-0-0") == false)
        }
    }

    @Test func togglingOneDishLeavesTheOthersAlone() {
        withTemporaryDefaults { defaults in
            let store = FavoritesStore(defaults: defaults)

            store.toggle("10-0-0")
            store.toggle("20-3-0")
            store.toggle("10-0-0")

            #expect(store.favoriteDishIDs == ["20-3-0"])
        }
    }

    /// The actual requirement: a heart tapped today is still there next launch.
    /// The second store stands in for the next launch — same defaults, fresh
    /// object, nothing carried over in memory.
    @Test func favoritesSurviveAFreshStoreOverTheSameDefaults() {
        withTemporaryDefaults { defaults in
            let store = FavoritesStore(defaults: defaults)
            store.toggle("10-0-0")
            store.toggle("20-3-0")

            let relaunched = FavoritesStore(defaults: defaults)

            #expect(relaunched.favoriteDishIDs == ["10-0-0", "20-3-0"])
        }
    }

    /// Pins the stored shape, not just the behaviour. Switching to an encoded
    /// blob later would strand every favorite already on someone's phone, so
    /// it should have to be a deliberate change to this test rather than a
    /// silent one.
    @Test func favoritesAreStoredAsASortedStringArray() {
        withTemporaryDefaults { defaults in
            let store = FavoritesStore(defaults: defaults)
            store.toggle("20-3-0")
            store.toggle("10-0-0")

            #expect(defaults.stringArray(forKey: FavoritesStore.defaultsKey) == ["10-0-0", "20-3-0"])
        }
    }

    @Test func aCorruptStoredValueReadsAsNoFavorites() {
        withTemporaryDefaults { defaults in
            defaults.set("not an array", forKey: FavoritesStore.defaultsKey)

            let store = FavoritesStore(defaults: defaults)

            #expect(store.favoriteDishIDs.isEmpty)
        }
    }

    @Test func clearRemovesEveryFavoriteAndPersists() {
        withTemporaryDefaults { defaults in
            let store = FavoritesStore(defaults: defaults)
            store.toggle("10-0-0")
            store.toggle("20-3-0")

            store.clear()

            #expect(store.favoriteDishIDs.isEmpty)
            #expect(FavoritesStore(defaults: defaults).favoriteDishIDs.isEmpty)
        }
    }
}

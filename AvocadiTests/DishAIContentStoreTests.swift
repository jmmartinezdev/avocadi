//
//  DishAIContentStoreTests.swift
//  AvocadiTests
//
//  Created by Chema Martinez on 28/8/26.
//

import Foundation
import SwiftData
import Testing
@testable import Avocadi

/// Covers `SwiftDataDishAIContentStore` against a real (in-memory) SwiftData
/// stack, rather than the fake `DishDetailViewModelTests` uses.
///
/// `deleteAll` is the reason this file exists: it's the only destructive path
/// in the app, it's wired to a button that can't be undone, and unlike
/// `fetch`/`save` it isn't exercised indirectly by any other test.
@MainActor
struct DishAIContentStoreTests {

    private func makeStore() throws -> SwiftDataDishAIContentStore {
        let container = try ModelContainer(
            for: DishAIContent.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return SwiftDataDishAIContentStore(modelContext: ModelContext(container))
    }

    private func record(_ text: String) -> DishAIContentRecord {
        DishAIContentRecord(
            descriptionText: text,
            imageData: Data([0x01]),
            descriptionPromptVersion: 2,
            descriptionLanguage: "es"
        )
    }

    @Test func savedRecordComesBackFromFetch() throws {
        let store = try makeStore()

        store.save(dishID: "dish-1", record("Descripción"))

        #expect(store.fetch(dishID: "dish-1")?.descriptionText == "Descripción")
        #expect(store.fetch(dishID: "dish-2") == nil)
    }

    @Test func savingTwiceUpdatesInPlaceRatherThanInserting() throws {
        let store = try makeStore()

        store.save(dishID: "dish-1", record("Primera"))
        store.save(dishID: "dish-1", record("Segunda"))

        #expect(store.fetch(dishID: "dish-1")?.descriptionText == "Segunda")
    }

    @Test func deleteAllRemovesEveryDishNotJustOne() throws {
        let store = try makeStore()
        store.save(dishID: "dish-1", record("Una"))
        store.save(dishID: "dish-2", record("Otra"))

        store.deleteAll()

        #expect(store.fetch(dishID: "dish-1") == nil)
        #expect(store.fetch(dishID: "dish-2") == nil)
    }

    @Test func deleteAllOnAnEmptyStoreIsHarmless() throws {
        let store = try makeStore()

        store.deleteAll()

        #expect(store.fetch(dishID: "dish-1") == nil)
    }
}

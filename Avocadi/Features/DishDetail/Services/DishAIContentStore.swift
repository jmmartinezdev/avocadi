//
//  DishAIContentStore.swift
//  Avocadi
//
//  Created by Chema Martinez on 24/8/26.
//

import Foundation
import SwiftData

/// Persists/retrieves a dish's cached AI content, keyed by `Dish.id`.
///
/// Speaks in the plain-value `DishAIContentRecord` rather than the SwiftData
/// `@Model` directly, so `DishDetailViewModel` (and its tests) don't need a
/// real `ModelContainer` to depend on this.
protocol DishAIContentStoring {
    func fetch(dishID: String) -> DishAIContentRecord?
    /// Upserts: updates the existing row for `dishID` if one exists,
    /// otherwise inserts a new one. Callers are expected to have already
    /// merged old + new fields into `record` (e.g. keeping a cached image
    /// while only the description changed) before calling this.
    func save(dishID: String, _ record: DishAIContentRecord)
    /// Throws away every cached record, for the settings screen's "delete
    /// generated content". Deliberately all-or-nothing: the cache is keyed by
    /// dish and there is no per-dish delete anywhere in the UI.
    func deleteAll()
}

/// SwiftData-backed `DishAIContentStoring`, wrapping `DishAIContent`.
final class SwiftDataDishAIContentStore: DishAIContentStoring {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetch(dishID: String) -> DishAIContentRecord? {
        guard let entity = fetchEntity(dishID: dishID) else { return nil }
        return DishAIContentRecord(
            descriptionText: entity.descriptionText,
            imageData: entity.imageData,
            descriptionPromptVersion: entity.descriptionPromptVersion,
            descriptionLanguage: entity.descriptionLanguage
        )
    }

    func save(dishID: String, _ record: DishAIContentRecord) {
        if let entity = fetchEntity(dishID: dishID) {
            entity.descriptionText = record.descriptionText
            entity.imageData = record.imageData
            entity.descriptionPromptVersion = record.descriptionPromptVersion
            entity.descriptionLanguage = record.descriptionLanguage
            entity.generatedAt = .now
        } else {
            modelContext.insert(
                DishAIContent(
                    dishID: dishID,
                    descriptionText: record.descriptionText,
                    imageData: record.imageData,
                    descriptionPromptVersion: record.descriptionPromptVersion,
                    descriptionLanguage: record.descriptionLanguage
                )
            )
        }
    }

    func deleteAll() {
        // Deliberately not `modelContext.delete(model:)`: that's a batch
        // delete straight against the persistent store, so it skips anything
        // still pending in the context — and since `save(dishID:)` leaves
        // persisting to autosave, a dish generated moments ago is exactly
        // that. Fetching first picks up pending inserts along with saved rows.
        let entities = (try? modelContext.fetch(FetchDescriptor<DishAIContent>())) ?? []
        for entity in entities {
            modelContext.delete(entity)
        }
        // Saved here rather than left to autosave too: "delete my data" should
        // be on disk by the time the user leaves the screen, not whenever the
        // next autosave happens to fire.
        try? modelContext.save()
    }

    private func fetchEntity(dishID: String) -> DishAIContent? {
        let descriptor = FetchDescriptor<DishAIContent>(
            predicate: #Predicate { $0.dishID == dishID }
        )
        return try? modelContext.fetch(descriptor).first
    }
}

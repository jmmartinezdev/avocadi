//
//  DishDetailViewModelTests.swift
//  AvocadiTests
//
//  Created by Chema Martinez on 24/8/26.
//

import Testing
import Foundation
@testable import Avocadi

/// In-memory `DishAIContentStoring` fake — no `ModelContainer` needed.
private final class FakeDishAIContentStore: DishAIContentStoring {
    private(set) var records: [String: DishAIContentRecord] = [:]

    init(seed: [String: DishAIContentRecord] = [:]) {
        records = seed
    }

    func fetch(dishID: String) -> DishAIContentRecord? {
        records[dishID]
    }

    func save(dishID: String, _ record: DishAIContentRecord) {
        records[dishID] = record
    }
}

private struct FakeDishDescriptionGenerator: DishDescriptionGenerating {
    enum Failure: Error { case generationFailed }

    var isAvailable = true
    var promptVersion = 2
    var language = "es"
    var appLanguage = "es"
    var result: Result<String, Error> = .success("Descripción generada")

    func generateDescription(for dish: Dish) async throws -> String {
        try result.get()
    }
}

private struct FakeDishImageGenerator: DishImageGenerating {
    enum Failure: Error { case generationFailed }

    var result: Result<Data, Error> = .success(Data([0x01, 0x02]))

    func generateImage(for dish: Dish) async throws -> Data {
        try result.get()
    }
}

private let testDish = Dish(id: "dish-1", name: "Tortilla francesa")

/// `DishDetailViewModel` is `@MainActor`-isolated (like every type in this
/// app, by default), so these tests need to run on the main actor too in
/// order to read its state synchronously after `await load()`.
@MainActor
struct DishDetailViewModelTests {

    @Test func freshDishGeneratesAndPersistsBothDescriptionAndImage() async {
        let store = FakeDishAIContentStore()
        let viewModel = DishDetailViewModel(
            dish: testDish,
            store: store,
            descriptionGenerator: FakeDishDescriptionGenerator(),
            imageGenerator: FakeDishImageGenerator()
        )

        await viewModel.load()

        #expect(viewModel.descriptionText == "Descripción generada")
        if case .loaded(let data) = viewModel.imageState {
            #expect(data == Data([0x01, 0x02]))
        } else {
            Issue.record("Expected imageState to be .loaded")
        }
        #expect(store.records["dish-1"]?.descriptionText == "Descripción generada")
        #expect(store.records["dish-1"]?.descriptionPromptVersion == 2)
        #expect(store.records["dish-1"]?.descriptionLanguage == "es")
    }

    @Test func cachedEntryWithCurrentPromptVersionIsUsedAsIs() async {
        let store = FakeDishAIContentStore(seed: [
            "dish-1": DishAIContentRecord(
                descriptionText: "Ya en caché",
                imageData: Data([0xAA]),
                descriptionPromptVersion: 2,
                descriptionLanguage: "es"
            )
        ])
        let viewModel = DishDetailViewModel(
            dish: testDish,
            store: store,
            descriptionGenerator: FakeDishDescriptionGenerator(result: .failure(FakeDishDescriptionGenerator.Failure.generationFailed)),
            imageGenerator: FakeDishImageGenerator(result: .failure(FakeDishImageGenerator.Failure.generationFailed))
        )

        await viewModel.load()

        #expect(viewModel.descriptionText == "Ya en caché")
        if case .loaded(let data) = viewModel.imageState {
            #expect(data == Data([0xAA]))
        } else {
            Issue.record("Expected imageState to be .loaded from cache")
        }
    }

    @Test func staleCachedPromptVersionOnlyRegeneratesDescriptionKeepingCachedImage() async {
        let store = FakeDishAIContentStore(seed: [
            "dish-1": DishAIContentRecord(
                descriptionText: "Descripción antigua",
                imageData: Data([0xBB]),
                descriptionPromptVersion: 1,
                descriptionLanguage: "es"
            )
        ])
        let viewModel = DishDetailViewModel(
            dish: testDish,
            store: store,
            descriptionGenerator: FakeDishDescriptionGenerator(promptVersion: 2, result: .success("Descripción nueva")),
            imageGenerator: FakeDishImageGenerator(result: .failure(FakeDishImageGenerator.Failure.generationFailed))
        )

        await viewModel.load()

        #expect(viewModel.descriptionText == "Descripción nueva")
        if case .loaded(let data) = viewModel.imageState {
            #expect(data == Data([0xBB]))
        } else {
            Issue.record("Expected the cached image to be kept, not regenerated")
        }
        #expect(store.records["dish-1"]?.descriptionText == "Descripción nueva")
        #expect(store.records["dish-1"]?.descriptionPromptVersion == 2)
        #expect(store.records["dish-1"]?.descriptionLanguage == "es")
        #expect(store.records["dish-1"]?.imageData == Data([0xBB]))
    }

    @Test func failedRegenerationFallsBackToStaleDescriptionWithoutAdvancingVersion() async {
        let store = FakeDishAIContentStore(seed: [
            "dish-1": DishAIContentRecord(
                descriptionText: "Descripción antigua",
                imageData: nil,
                descriptionPromptVersion: 1,
                descriptionLanguage: "es"
            )
        ])
        let viewModel = DishDetailViewModel(
            dish: testDish,
            store: store,
            descriptionGenerator: FakeDishDescriptionGenerator(promptVersion: 2, result: .failure(FakeDishDescriptionGenerator.Failure.generationFailed)),
            imageGenerator: FakeDishImageGenerator(result: .failure(FakeDishImageGenerator.Failure.generationFailed))
        )

        await viewModel.load()

        #expect(viewModel.descriptionText == "Descripción antigua")
        #expect(store.records["dish-1"]?.descriptionPromptVersion == 1)
    }

    @Test func cachedDescriptionInAnotherLanguageIsRegeneratedKeepingCachedImage() async {
        let store = FakeDishAIContentStore(seed: [
            "dish-1": DishAIContentRecord(
                descriptionText: "Descripción en español",
                imageData: Data([0xCC]),
                descriptionPromptVersion: 2,
                descriptionLanguage: "es"
            )
        ])
        let viewModel = DishDetailViewModel(
            dish: testDish,
            store: store,
            descriptionGenerator: FakeDishDescriptionGenerator(language: "en", result: .success("A description in English")),
            imageGenerator: FakeDishImageGenerator(result: .failure(FakeDishImageGenerator.Failure.generationFailed))
        )

        await viewModel.load()

        #expect(viewModel.descriptionText == "A description in English")
        if case .loaded(let data) = viewModel.imageState {
            #expect(data == Data([0xCC]))
        } else {
            Issue.record("Expected the cached image to be kept — illustrations aren't language-specific")
        }
        #expect(store.records["dish-1"]?.descriptionLanguage == "en")
        #expect(store.records["dish-1"]?.imageData == Data([0xCC]))
    }

    /// Records written before descriptions followed the app's language have no
    /// language stamped on them, which has to read as stale so each dish
    /// regenerates exactly once rather than keeping a description in whatever
    /// language it happened to be generated in.
    @Test func legacyCachedDescriptionWithNoRecordedLanguageIsRegenerated() async {
        let store = FakeDishAIContentStore(seed: [
            "dish-1": DishAIContentRecord(
                descriptionText: "Descripción heredada",
                imageData: Data([0xDD]),
                descriptionPromptVersion: 2,
                descriptionLanguage: nil
            )
        ])
        let viewModel = DishDetailViewModel(
            dish: testDish,
            store: store,
            descriptionGenerator: FakeDishDescriptionGenerator(result: .success("Descripción regenerada")),
            imageGenerator: FakeDishImageGenerator(result: .failure(FakeDishImageGenerator.Failure.generationFailed))
        )

        await viewModel.load()

        #expect(viewModel.descriptionText == "Descripción regenerada")
        #expect(store.records["dish-1"]?.descriptionLanguage == "es")
        #expect(store.records["dish-1"]?.imageData == Data([0xDD]))
    }

    @Test func failedRegenerationFallsBackToStaleDescriptionWithoutAdvancingLanguage() async {
        let store = FakeDishAIContentStore(seed: [
            "dish-1": DishAIContentRecord(
                descriptionText: "Descripción en español",
                imageData: nil,
                descriptionPromptVersion: 2,
                descriptionLanguage: "es"
            )
        ])
        let viewModel = DishDetailViewModel(
            dish: testDish,
            store: store,
            descriptionGenerator: FakeDishDescriptionGenerator(language: "en", result: .failure(FakeDishDescriptionGenerator.Failure.generationFailed)),
            imageGenerator: FakeDishImageGenerator(result: .failure(FakeDishImageGenerator.Failure.generationFailed))
        )

        await viewModel.load()

        #expect(viewModel.descriptionText == "Descripción en español")
        #expect(store.records["dish-1"]?.descriptionLanguage == "es")
    }

    @Test func cachedRowWithNoImageIsUnavailableAndNeverRetried() async {
        let store = FakeDishAIContentStore(seed: [
            "dish-1": DishAIContentRecord(
                descriptionText: "Descripción",
                imageData: nil,
                descriptionPromptVersion: 2,
                descriptionLanguage: "es"
            )
        ])
        let viewModel = DishDetailViewModel(
            dish: testDish,
            store: store,
            descriptionGenerator: FakeDishDescriptionGenerator(),
            imageGenerator: FakeDishImageGenerator(result: .success(Data([0x99])))
        )

        await viewModel.load()

        if case .unavailable = viewModel.imageState {
            // expected
        } else {
            Issue.record("Expected imageState to stay .unavailable, not retry generation")
        }
        #expect(store.records["dish-1"]?.imageData == nil)
    }

    @Test func descriptionInTheAppsOwnLanguageShowsNoFallbackNote() async {
        let store = FakeDishAIContentStore()
        let viewModel = DishDetailViewModel(
            dish: testDish,
            store: store,
            descriptionGenerator: FakeDishDescriptionGenerator(language: "es", appLanguage: "es"),
            imageGenerator: FakeDishImageGenerator()
        )

        await viewModel.load()

        #expect(viewModel.descriptionText != nil)
        #expect(viewModel.fallbackLanguage == nil)
    }

    /// The Catalan case: the model can't write the app's language, so the
    /// generator hands back Spanish and the view has to say so.
    @Test func descriptionGeneratedInAFallbackLanguageReportsIt() async {
        let store = FakeDishAIContentStore()
        let viewModel = DishDetailViewModel(
            dish: testDish,
            store: store,
            descriptionGenerator: FakeDishDescriptionGenerator(
                language: "es",
                appLanguage: "ca",
                result: .success("Un guiso tradicional")
            ),
            imageGenerator: FakeDishImageGenerator()
        )

        await viewModel.load()

        #expect(viewModel.descriptionText == "Un guiso tradicional")
        #expect(viewModel.fallbackLanguage == "es")
        #expect(store.records["dish-1"]?.descriptionLanguage == "es")
    }

    /// The note is driven by the description on screen, not by generation
    /// happening this launch — a cached fallback still has to be explained.
    @Test func cachedFallbackDescriptionStillReportsItsLanguage() async {
        let store = FakeDishAIContentStore(seed: [
            "dish-1": DishAIContentRecord(
                descriptionText: "Un guiso tradicional",
                imageData: Data([0xEE]),
                descriptionPromptVersion: 2,
                descriptionLanguage: "es"
            )
        ])
        let viewModel = DishDetailViewModel(
            dish: testDish,
            store: store,
            descriptionGenerator: FakeDishDescriptionGenerator(
                language: "es",
                appLanguage: "ca",
                result: .failure(FakeDishDescriptionGenerator.Failure.generationFailed)
            ),
            imageGenerator: FakeDishImageGenerator(result: .failure(FakeDishImageGenerator.Failure.generationFailed))
        )

        await viewModel.load()

        #expect(viewModel.descriptionText == "Un guiso tradicional")
        #expect(viewModel.fallbackLanguage == "es")
    }

    @Test func descriptionUnavailableLeavesTextNilWithoutCrashing() async {
        let store = FakeDishAIContentStore()
        let viewModel = DishDetailViewModel(
            dish: testDish,
            store: store,
            descriptionGenerator: FakeDishDescriptionGenerator(isAvailable: false),
            imageGenerator: FakeDishImageGenerator(result: .failure(FakeDishImageGenerator.Failure.generationFailed))
        )

        await viewModel.load()

        #expect(viewModel.descriptionText == nil)
        #expect(viewModel.isGeneratingDescription == false)
    }
}

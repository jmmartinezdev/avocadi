//
//  DishDetailViewModel.swift
//  Avocadi
//
//  Created by Chema Martinez on 24/8/26.
//

import Foundation
import Observation

/// Owns `DishDetailView`'s content: loads cached AI content for `dish` if
/// it exists, otherwise generates the description and illustration
/// concurrently via the injected generators, updating state as soon as
/// each piece finishes rather than waiting for both, then persists
/// whatever was generated via the injected store.
///
/// Injecting `DishAIContentStoring`/`DishDescriptionGenerating`/
/// `DishImageGenerating` (rather than talking to SwiftData or the Apple
/// Intelligence frameworks directly) is what makes this orchestration
/// logic — genuinely the trickiest part of this feature — unit-testable
/// with fakes, the same way `WeekViewModel`/`DayViewModel` are tested in
/// `AvocadiTests`.
@MainActor
@Observable
final class DishDetailViewModel {
    /// The image's state: loading (shimmering placeholder), successfully
    /// loaded, or unavailable (generation wasn't possible, or failed, or an
    /// already-cached dish has no image on record). `DishDetailView` renders
    /// all three inside the same fixed-size square container so switching
    /// between them never changes the layout.
    enum ImageLoadState {
        case loading
        case loaded(Data)
        case unavailable
    }

    private(set) var descriptionText: String?
    private(set) var isGeneratingDescription = false
    private(set) var imageState: ImageLoadState = .loading

    private let dish: Dish
    private let store: DishAIContentStoring
    private let descriptionGenerator: DishDescriptionGenerating
    private let imageGenerator: DishImageGenerating

    init(
        dish: Dish,
        store: DishAIContentStoring,
        descriptionGenerator: DishDescriptionGenerating,
        imageGenerator: DishImageGenerating
    ) {
        self.dish = dish
        self.store = store
        self.descriptionGenerator = descriptionGenerator
        self.imageGenerator = imageGenerator
    }

    /// Loads cached content for `dish` if it exists; otherwise generates
    /// the description and illustration concurrently, updating each
    /// section's state as soon as its piece finishes rather than waiting
    /// for both, then persists whatever was generated.
    ///
    /// Image generation is only ever attempted once, when a record for
    /// this dish is first created — an existing record with no image on it
    /// is treated as a settled "unavailable", not retried. The description
    /// is different: if the cached record no longer matches how a
    /// description would be generated now — either an older
    /// `descriptionGenerator.promptVersion` (a wording fix shipped since) or a
    /// different `descriptionGenerator.language` (the app is being read in
    /// another language now) — only the description is regenerated, keeping
    /// the cached image untouched. Illustrations aren't language-specific, so
    /// switching language costs only the cheap half of generation.
    func load() async {
        let existing = store.fetch(dishID: dish.id)
        let currentPromptVersion = descriptionGenerator.promptVersion
        let currentLanguage = descriptionGenerator.language

        if let existing {
            imageState = existing.imageData.map(ImageLoadState.loaded) ?? .unavailable
        } // else: leave `imageState` at `.loading` until generation resolves below.

        if let existing,
           existing.descriptionPromptVersion == currentPromptVersion,
           existing.descriptionLanguage == currentLanguage {
            descriptionText = existing.descriptionText
            return
        }

        async let descriptionResult = generateDescriptionIfAvailable()
        // Only generate an illustration if none is cached yet; a prompt
        // version bump or a language change only affects the description, so
        // neither should trigger regenerating the image.
        async let imageResult: Data? = existing == nil ? generateImageIfAvailable() : nil

        isGeneratingDescription = descriptionGenerator.isAvailable

        // Falls back to the stale cached description on a failed
        // regeneration attempt rather than blanking out text that was
        // previously showing fine, just generated under an older prompt
        // version.
        let description = await descriptionResult
        descriptionText = description ?? existing?.descriptionText
        isGeneratingDescription = false

        let image = await imageResult
        if existing == nil {
            imageState = image.map(ImageLoadState.loaded) ?? .unavailable
        }
        // If `existing` isn't nil, `imageState` was already resolved from
        // the cache above and `imageResult` is `nil` by construction, so
        // there's nothing further to do for the image here.

        guard description != nil || image != nil else { return }

        // Only advances the recorded prompt version and language if
        // regeneration actually succeeded — a failed attempt should retry next
        // time, not get stuck permanently stale by being marked current.
        let record = DishAIContentRecord(
            descriptionText: description ?? existing?.descriptionText,
            imageData: image ?? existing?.imageData,
            descriptionPromptVersion: description != nil ? currentPromptVersion : (existing?.descriptionPromptVersion ?? currentPromptVersion),
            descriptionLanguage: description != nil ? currentLanguage : existing?.descriptionLanguage
        )
        store.save(dishID: dish.id, record)
    }

    private func generateDescriptionIfAvailable() async -> String? {
        guard descriptionGenerator.isAvailable else { return nil }
        return try? await descriptionGenerator.generateDescription(for: dish)
    }

    private func generateImageIfAvailable() async -> Data? {
        try? await imageGenerator.generateImage(for: dish)
    }
}

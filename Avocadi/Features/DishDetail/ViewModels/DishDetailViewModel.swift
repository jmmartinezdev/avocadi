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
    /// loaded, unavailable (generation wasn't possible, or failed, or an
    /// already-cached dish has no image on record), or hidden. `DishDetailView`
    /// renders the first three inside the same fixed-size square container so
    /// switching between them never changes the layout.
    ///
    /// `hidden` is the exception, and is why it isn't folded into
    /// `unavailable`: that one means "we tried and there's nothing", which
    /// still earns the square and its placeholder icon, whereas this one means
    /// the user switched generated content off — so there is no image section
    /// on screen at all, square included.
    enum ImageLoadState {
        case loading
        case loaded(Data)
        case unavailable
        case hidden
    }

    private(set) var descriptionText: String?
    /// The language `descriptionText` is actually written in, kept in lockstep
    /// with it so `fallbackLanguage` describes what's on screen rather than
    /// what the generator would produce if asked right now.
    private(set) var descriptionLanguage: String?
    private(set) var isGeneratingDescription = false
    private(set) var imageState: ImageLoadState = .loading

    /// The language the description is in when that *isn't* the app's own —
    /// which happens when the on-device model can't write in the app's
    /// language and `DishDescriptionGenerating` fell back (see its
    /// `language`/`appLanguage`). `DishDetailView` turns this into a note
    /// above the description, because a Catalan screen holding a Spanish
    /// paragraph is otherwise indistinguishable from a bug.
    var fallbackLanguage: String? {
        guard let descriptionLanguage,
              descriptionLanguage != appLanguage else { return nil }
        return descriptionLanguage
    }

    /// The language the app itself is being read in, so the view can name
    /// `fallbackLanguage` in it rather than in the fallback language.
    var appLanguage: String { descriptionGenerator.appLanguage }

    private let dish: Dish
    private let store: DishAIContentStoring
    private let descriptionGenerator: DishDescriptionGenerating
    private let imageGenerator: DishImageGenerating
    private let isAIContentEnabled: Bool

    init(
        dish: Dish,
        store: DishAIContentStoring,
        descriptionGenerator: DishDescriptionGenerating,
        imageGenerator: DishImageGenerating,
        isAIContentEnabled: Bool = AIContentSettings.isEnabledDefault
    ) {
        self.dish = dish
        self.store = store
        self.descriptionGenerator = descriptionGenerator
        self.imageGenerator = imageGenerator
        self.isAIContentEnabled = isAIContentEnabled
    }

    /// Loads cached content for `dish` if it exists; otherwise generates
    /// the description and illustration concurrently, updating each
    /// section's state as soon as its piece finishes rather than waiting
    /// for both, then persists whatever was generated.
    ///
    /// Does none of that when `isAIContentEnabled` is `false` — see the guard
    /// below.
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
        // Off means off on screen, not just off in the generators: returning
        // before the store is even read is what makes a dish generated last
        // week look identical to one never opened. Nothing is deleted here —
        // flipping the switch back on brings the cache straight back, and
        // actually throwing it away is the settings screen's separate,
        // explicit action.
        guard isAIContentEnabled else {
            imageState = .hidden
            return
        }

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
            descriptionLanguage = existing.descriptionLanguage
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
        descriptionLanguage = description != nil ? currentLanguage : existing?.descriptionLanguage
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

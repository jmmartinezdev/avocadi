//
//  DishDescriptionGenerator.swift
//  Avocadi
//
//  Created by Chema Martinez on 24/8/26.
//

import Foundation
import FoundationModels

/// Generates a short description for a dish using on-device Apple
/// Intelligence (the Foundation Models framework).
///
/// Only works on Apple Intelligence–eligible hardware with Apple
/// Intelligence enabled in Settings — check `isAvailable` before calling
/// `generateDescription(for:)`, and treat a thrown error as "nothing to
/// show" rather than a failure to surface to the user, per
/// `DishDetailViewModel`.
protocol DishDescriptionGenerating {
    /// Whether on-device text generation is available on this device right
    /// now. Cheap/synchronous, so callers can check it before ever showing
    /// a loading state for the description.
    var isAvailable: Bool { get }

    /// Bumped whenever `generateDescription`'s instructions/prompt change in
    /// a way that should invalidate previously cached descriptions (e.g. a
    /// wording fix). `DishDetailViewModel` compares this against each cached
    /// record's `descriptionPromptVersion` and regenerates on a mismatch, so
    /// a prompt fix like this doesn't require users to clear cached data
    /// manually.
    ///
    /// Translating the prompt into a new language is *not* a reason to bump
    /// this — `language` is the separate axis for that, so that adding a
    /// localization doesn't invalidate descriptions already cached in the
    /// languages that haven't changed.
    var promptVersion: Int { get }

    /// The language `generateDescription` will answer in, as a language code
    /// (e.g. `"en"`, `"es"`). Paired with `promptVersion` as the second
    /// staleness signal `DishDetailViewModel` checks cached descriptions
    /// against, so switching the app's language regenerates them.
    var language: String { get }

    func generateDescription(for dish: Dish) async throws -> String
}

struct FoundationModelsDishDescriptionGenerator: DishDescriptionGenerating {
    enum GenerationError: Error {
        case unavailable
    }

    var isAvailable: Bool {
        SystemLanguageModel.default.availability == .available
    }

    let promptVersion = 2

    /// Read out of `Prompts.xcstrings` itself rather than from
    /// `Locale.current` or `Bundle.main.preferredLocalizations`, so that it is
    /// by construction the language the prompt below actually resolved to.
    ///
    /// The distinction matters because this value is what a cached description
    /// gets stamped with. `Locale.current` is simply the wrong question — the
    /// app ships only English and Spanish, so a French device reads the app in
    /// English and must get English descriptions, not French ones.
    /// `preferredLocalizations` asks the right question but is still a
    /// separate lookup that could in principle answer differently from the one
    /// that resolves the prompt (regional variants, development-region
    /// fallback); going through the same table removes that whole class of
    /// disagreement.
    var language: String {
        String(localized: "prompt.language.code", defaultValue: "en", table: "Prompts")
    }

    func generateDescription(for dish: Dish) async throws -> String {
        guard isAvailable else { throw GenerationError.unavailable }

        // Prompt text lives in Prompts.xcstrings, translated per language
        // rather than written here, because the on-device model follows the
        // language of its surrounding context far more reliably than a
        // "respond in X" directive. Every dish name in Menu.json is Spanish
        // whatever the app's language, so that context — the instructions and
        // the "Dish:"/"Plato:" label alike — is what holds the answer in the
        // language the user is reading the app in.
        let session = LanguageModelSession(
            instructions: String(
                localized: "You are a concise culinary assistant. Given the name of a dish, which may be written in Spanish, write a brief, appetizing description of 1 or 2 sentences in English. Do not simply repeat the name of the dish.",
                table: "Prompts"
            )
        )
        let response = try await session.respond(
            to: String(localized: "Dish: \(dish.name)", table: "Prompts")
        )
        return response.content
    }
}

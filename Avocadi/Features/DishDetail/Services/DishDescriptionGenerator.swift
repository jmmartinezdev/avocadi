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
    /// Whether a description can be generated on this device right now.
    /// Cheap/synchronous, so callers can check it before ever showing a
    /// loading state for the description.
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
    ///
    /// Not necessarily `appLanguage`: see `DishDescriptionGenerating`'s
    /// conforming types for the fallback when the model can't write in the
    /// app's language.
    var language: String { get }

    /// The language the *app* is being read in, which `language` matches
    /// whenever the model is able to. Where the two differ,
    /// `DishDetailViewModel` says so on screen rather than quietly handing
    /// the user a description in a language they didn't ask for.
    var appLanguage: String { get }

    func generateDescription(for dish: Dish) async throws -> String
}

struct FoundationModelsDishDescriptionGenerator: DishDescriptionGenerating {
    enum GenerationError: Error {
        case unavailable
    }

    /// Keys into `Prompts.xcstrings`. Named constants rather than inline
    /// literals because the prompt is looked up in an explicitly chosen
    /// language (see `prompt(_:in:)`) rather than through
    /// `String(localized:)`, which would always resolve to the app's own.
    /// Internal rather than private so `PromptLocalizationTests` can assert
    /// the per-language lookup still returns exactly what `String(localized:)`
    /// used to — the check that lets `promptVersion` stay put.
    enum PromptKey {
        static let languageCode = "prompt.language.code"
        static let dishLabel = "Dish: %@"
        static let instructions = """
            You are a concise culinary assistant. Given the name of a dish, which may be \
            written in Spanish, write a brief, appetizing description of 1 or 2 sentences \
            in English. Do not simply repeat the name of the dish.
            """
    }

    /// The language `Menu.json`'s dish names are written in, and so the
    /// sensible language to describe them in when the model can't manage the
    /// app's own.
    private static let contentLanguage = "es"

    let promptVersion = 2

    /// Read out of `Prompts.xcstrings` itself rather than from
    /// `Locale.current` or `Bundle.main.preferredLocalizations`, so that it is
    /// by construction the language the app's own prompts resolve to.
    ///
    /// `Locale.current` is simply the wrong question — the app ships a fixed
    /// set of languages, so a device set to one it doesn't ship falls back to
    /// English and must be treated as English. `preferredLocalizations` asks
    /// the right question but is a separate lookup that could in principle
    /// answer differently from the one that resolves the prompt (regional
    /// variants, development-region fallback); going through the same table
    /// removes that whole class of disagreement.
    var appLanguage: String {
        String(localized: "prompt.language.code", defaultValue: "en", table: "Prompts")
    }

    /// Falls back to `appLanguage` when nothing is supported — a value that is
    /// never used, since `isAvailable` is `false` in exactly that case.
    var language: String {
        resolvedLanguage ?? appLanguage
    }

    /// Unlike `promptVersion`, availability has to account for language:
    /// `SystemLanguageModel.Availability.UnavailableReason` covers only
    /// `deviceNotEligible`, `appleIntelligenceNotEnabled` and `modelNotReady`,
    /// saying nothing about whether the model can write in a given language.
    /// Without the `resolvedLanguage` check, an unsupported language would
    /// pass this, start the loading shimmer, and then throw
    /// `unsupportedLanguageOrLocale` from `respond` — showing the user a
    /// placeholder that resolves into nothing.
    var isAvailable: Bool {
        SystemLanguageModel.default.availability == .available && resolvedLanguage != nil
    }

    private var resolvedLanguage: String? {
        let model = SystemLanguageModel.default
        return Self.resolveLanguage(appLanguage: appLanguage) { candidate in
            model.supportsLocale(Locale(identifier: candidate))
        }
    }

    /// The first of the app's language and the content language that the model
    /// can actually write in, or `nil` if it can write in neither.
    ///
    /// Pure, and taking `isSupported` as a parameter, so the fallback order is
    /// testable without an Apple Intelligence–capable device — which no
    /// simulator is.
    static func resolveLanguage(
        appLanguage: String,
        contentLanguage: String = contentLanguage,
        isSupported: (String) -> Bool
    ) -> String? {
        var candidates = [appLanguage]
        if contentLanguage != appLanguage { candidates.append(contentLanguage) }
        return candidates.first(where: isSupported)
    }

    func generateDescription(for dish: Dish) async throws -> String {
        guard isAvailable, let language = resolvedLanguage else {
            throw GenerationError.unavailable
        }

        // Prompt text lives in Prompts.xcstrings, translated per language
        // rather than written here, because the on-device model follows the
        // language of its surrounding context far more reliably than a
        // "respond in X" directive. Every dish name in Menu.json is Spanish
        // whatever the app's language, so that context — the instructions and
        // the "Dish:"/"Plato:" label alike — is what holds the answer in the
        // language being asked for.
        let session = LanguageModelSession(
            instructions: prompt(PromptKey.instructions, in: language)
        )
        let response = try await session.respond(
            to: String(format: prompt(PromptKey.dishLabel, in: language), dish.name)
        )
        return response.content
    }

    /// One prompt string in an explicitly chosen language, rather than in the
    /// app's — which is what lets a Catalan reader be handed a Spanish prompt
    /// when the model can't write Catalan. `String(localized:)` can't do this:
    /// it always resolves against the app's own localization.
    ///
    /// The `guard`'s fallthrough is what makes the development region work. It
    /// ships no `.strings` of its own, because there every value is identical
    /// to its key — so returning the key *is* returning the source string.
    func prompt(_ key: String, in language: String) -> String {
        guard let path = Bundle.main.path(forResource: language, ofType: "lproj"),
              let bundle = Bundle(path: path) else { return key }
        return bundle.localizedString(forKey: key, value: key, table: "Prompts")
    }
}

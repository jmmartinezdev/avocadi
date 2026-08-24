//
//  DishDescriptionGenerator.swift
//  Avocadi
//
//  Created by Chema Martinez on 24/8/26.
//

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
    /// wording/language fix). `DishDetailViewModel` compares this against
    /// each cached record's `descriptionPromptVersion` and regenerates on a
    /// mismatch, so a prompt fix like this doesn't require users to clear
    /// cached data manually.
    var promptVersion: Int { get }

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

    func generateDescription(for dish: Dish) async throws -> String {
        guard isAvailable else { throw GenerationError.unavailable }

        // Written directly in Spanish (rather than an English instruction
        // asking the model to "respond in Spanish") since the on-device
        // model follows the language of its surrounding context far more
        // reliably than a language directive, and every dish name in
        // Menu.json is Spanish anyway.
        let session = LanguageModelSession(
            instructions: """
            Eres un asistente culinario conciso. Dado el nombre de un plato, \
            escribe una descripción breve y apetitosa de 1 o 2 frases en \
            español. No te limites a repetir el nombre del plato.
            """
        )
        let response = try await session.respond(to: "Plato: \(dish.name)")
        return response.content
    }
}

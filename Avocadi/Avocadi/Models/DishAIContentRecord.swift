//
//  DishAIContentRecord.swift
//  Avocadi
//
//  Created by Chema Martinez on 24/8/26.
//

import Foundation

/// A dish's cached AI content, decoupled from `DishAIContent` (the SwiftData
/// `@Model`) so the storage layer's protocol (`DishAIContentStoring`) can be
/// mocked in tests without a real `ModelContainer`.
///
/// `nonisolated` + `Sendable`: this app defaults every type to `@MainActor`
/// isolation, but this is a plain immutable data carrier that needs to
/// cross into `DishDetailViewModel`'s concurrent generation tasks (see its
/// `async let` calls), so it's explicitly exempted from that default.
nonisolated struct DishAIContentRecord: Equatable, Sendable {
    /// The generated description, if description generation was available
    /// and succeeded when this record was created.
    var descriptionText: String?
    /// PNG data for the generated illustration, if image generation was
    /// available and succeeded when this record was created.
    var imageData: Data?
    /// The generator's prompt version at the time `descriptionText` was
    /// generated. See `DishDescriptionGenerating.promptVersion`.
    var descriptionPromptVersion: Int
}

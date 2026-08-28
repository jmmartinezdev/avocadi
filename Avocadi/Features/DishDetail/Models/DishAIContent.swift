//
//  DishAIContent.swift
//  Avocadi
//
//  Created by Chema Martinez on 24/8/26.
//

import Foundation
import SwiftData

/// Cached Apple Intelligence–generated content for a single dish, keyed by
/// `Dish.id`.
///
/// Generation (a `LanguageModelSession` call plus an `ImageCreator` call) is
/// slow enough, and costly enough in on-device compute, that it should only
/// ever run once per dish. `DishDetailView` checks this cache first and only
/// falls back to generating when no entry exists yet for the dish.
@Model
final class DishAIContent {
    @Attribute(.unique) var dishID: String
    /// The generated description, if description generation was available
    /// and succeeded when this entry was created.
    var descriptionText: String?
    /// PNG data for the generated illustration, if image generation was
    /// available and succeeded when this entry was created.
    var imageData: Data?
    /// `DishAIContentGenerator.descriptionPromptVersion` at the time
    /// `descriptionText` was generated. If the generator's prompt version
    /// has since been bumped (e.g. a wording/language fix),
    /// `DishDetailView` treats this entry's description as stale and
    /// regenerates it rather than keep showing text produced by the old
    /// prompt.
    var descriptionPromptVersion: Int
    /// `DishDescriptionGenerating.language` at the time `descriptionText` was
    /// generated. If the app is now running in a different language,
    /// `DishDetailView` treats this entry's description as stale and
    /// regenerates it, so descriptions always match the language the rest of
    /// the app is being read in.
    ///
    /// Optional both because entries written before descriptions were
    /// language-aware genuinely have no language on them — `nil` reads as
    /// stale, so they regenerate once — and because an optional with no
    /// default keeps this a lightweight SwiftData migration.
    var descriptionLanguage: String?
    var generatedAt: Date

    init(dishID: String, descriptionText: String?, imageData: Data?, descriptionPromptVersion: Int, descriptionLanguage: String?, generatedAt: Date = .now) {
        self.dishID = dishID
        self.descriptionText = descriptionText
        self.imageData = imageData
        self.descriptionPromptVersion = descriptionPromptVersion
        self.descriptionLanguage = descriptionLanguage
        self.generatedAt = generatedAt
    }
}

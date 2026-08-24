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
    var generatedAt: Date

    init(dishID: String, descriptionText: String?, imageData: Data?, descriptionPromptVersion: Int, generatedAt: Date = .now) {
        self.dishID = dishID
        self.descriptionText = descriptionText
        self.imageData = imageData
        self.descriptionPromptVersion = descriptionPromptVersion
        self.generatedAt = generatedAt
    }
}

//
//  DishImageConceptTests.swift
//  AvocadiTests
//
//  Created by Chema Martinez on 29/8/26.
//

import Testing
@testable import Avocadi

/// Covers `ImagePlaygroundDishImageGenerator.conceptTexts(for:)` on its own.
///
/// The generator around it can't be tested at all — `ImageCreator` is a
/// concrete framework type with no seam, and no simulator has Apple
/// Intelligence — which is exactly why the splitting is a pure static function
/// rather than inline in `generateImage(for:)`.
struct DishImageConceptTests {

    @Test func plainNameIsASingleUnchangedConcept() {
        #expect(
            ImagePlaygroundDishImageGenerator.conceptTexts(for: "Bacalao pisto de verduras")
                == ["Bacalao pisto de verduras"]
        )
    }

    /// The bug this all exists for: `Menu.json` joins two plates with "+", and
    /// `ImageCreator` rejects the joined string outright.
    @Test func compoundNameSplitsIntoOneConceptPerPlate() {
        #expect(
            ImagePlaygroundDishImageGenerator.conceptTexts(for: "Tortilla francesa + queso fresco de cabra")
                == ["Tortilla francesa", "queso fresco de cabra"]
        )
    }

    /// `20-4-0`, the longest compound name in `Menu.json`.
    @Test func realCompoundNameFromTheMenuSplitsIntoItsTwoPlates() {
        let name = "Gambas y almejas salteadas con ajo + Ensalada de rúcula con tomate cherry y queso fresco"

        #expect(
            ImagePlaygroundDishImageGenerator.conceptTexts(for: name) == [
                "Gambas y almejas salteadas con ajo",
                "Ensalada de rúcula con tomate cherry y queso fresco",
            ]
        )
    }

    @Test(arguments: ["Crema+Tosta", "Crema  +  Tosta", "Crema +Tosta", "Crema+ Tosta"])
    func spacingAroundTheSeparatorDoesNotMatter(name: String) {
        #expect(ImagePlaygroundDishImageGenerator.conceptTexts(for: name) == ["Crema", "Tosta"])
    }

    @Test func namesWithMoreThanOneSeparatorSplitAtEach() {
        #expect(
            ImagePlaygroundDishImageGenerator.conceptTexts(for: "Crema + Tosta + Ensalada")
                == ["Crema", "Tosta", "Ensalada"]
        )
    }

    /// Never an empty array: `creator.images(for: [], …)` would be a worse
    /// failure than the one the splitting fixes.
    @Test(arguments: ["+", " + ", "", "   "])
    func namesThatSplitIntoNothingFallBackToTheRawName(name: String) {
        #expect(ImagePlaygroundDishImageGenerator.conceptTexts(for: name) == [name])
    }
}

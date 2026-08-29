//
//  DishImageGenerator.swift
//  Avocadi
//
//  Created by Chema Martinez on 24/8/26.
//

import ImagePlayground
import OSLog
import UIKit

private let logger = Logger(subsystem: "dev.jmmartinez.Avocadi", category: "DishImageGenerator")

/// Generates a stylized illustration of a dish using on-device Apple
/// Intelligence (the Image Playground framework) — not a photorealistic
/// photo, Apple Intelligence doesn't offer that.
///
/// Only works on Apple Intelligence–eligible hardware with Apple
/// Intelligence enabled in Settings — treat a thrown error as "nothing to
/// show" rather than a failure to surface to the user, per
/// `DishDetailViewModel`.
protocol DishImageGenerating {
    func generateImage(for dish: Dish) async throws -> Data
}

struct ImagePlaygroundDishImageGenerator: DishImageGenerating {
    enum GenerationError: Error {
        case unavailable
    }

    /// Splits a dish name into one concept string per plate.
    ///
    /// `Menu.json` writes plates served together as "A + B" — "Crema de
    /// verduras + Lomo de atún a la plancha con patata al horno". Handed to
    /// `ImageCreator` whole, that string is one concept describing two
    /// different dishes, and every such name is rejected with
    /// `ImageCreator.Error.unsupportedLanguage`: the iOS 27 SDK has no
    /// `unsupportedInputText` case, so `unsupportedLanguage` is what surfaces
    /// when the framework can't derive concepts from the text at all. Passing
    /// each plate as its own concept — which is what they are — is what the
    /// framework can actually work with.
    ///
    /// Returns the concept *strings* rather than `ImagePlaygroundConcept`s
    /// because that type is opaque and not `Equatable`, so there would be
    /// nothing to assert about them. Pure and static so the splitting is
    /// testable without an Apple Intelligence–capable device — which no
    /// simulator is — the same way
    /// `FoundationModelsDishDescriptionGenerator.resolveLanguage` is.
    ///
    /// The empty-parts fallback isn't defensive padding: a name of nothing but
    /// separators would otherwise yield an empty array, and
    /// `creator.images(for: [], …)` is a worse failure than the one this fixes.
    static func conceptTexts(for name: String) -> [String] {
        let parts = name
            .split(separator: "+")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        return parts.isEmpty ? [name] : parts
    }

    /// Whether `error` means "I couldn't make sense of that text", and so is
    /// worth retrying with concepts built a different way.
    ///
    /// Deliberately narrow. `notSupported`/`unavailable` mean the device can't
    /// generate images at all and `creationCancelled` means the user left the
    /// screen — retrying any of those is on-device compute spent to fail twice.
    private static func isTextRejection(_ error: ImageCreator.Error) -> Bool {
        switch error {
        case .unsupportedLanguage, .creationFailed: true
        default: false
        }
    }

    /// Returns PNG data ready to store as `DishAIContentRecord.imageData`.
    ///
    /// `ImageCreator` doesn't expose a separate synchronous availability
    /// check the way `SystemLanguageModel` does — construction itself
    /// throws when image generation isn't available on this device, so
    /// that failure doubles as the availability check here.
    ///
    /// Names too long or too run-on to parse are rejected the same way
    /// compound ones are (the 131-character "Boquerones con ajito…" is the
    /// known case), and no amount of splitting fixes that, so a text rejection
    /// gets one retry with `.extracted(from:)` — the concept API built for
    /// longer free text, which picks the concepts out itself instead of taking
    /// the string as one. Where Apple's threshold actually sits isn't
    /// documented, so this asks rather than guesses.
    func generateImage(for dish: Dish) async throws -> Data {
        let creator = try await ImageCreator()
        let texts = Self.conceptTexts(for: dish.name)

        do {
            return try await image(from: creator, concepts: texts.map(ImagePlaygroundConcept.text))
        } catch let error as ImageCreator.Error where Self.isTextRejection(error) {
            logger.notice(
                "Text concepts rejected for dish \(dish.id, privacy: .public) (\(String(describing: error), privacy: .public)); retrying with extracted concepts"
            )
            return try await image(from: creator, concepts: texts.map { .extracted(from: $0) })
        }
    }

    private func image(from creator: ImageCreator, concepts: [ImagePlaygroundConcept]) async throws -> Data {
        let images = creator.images(for: concepts, style: .illustration, limit: 1)

        for try await generated in images {
            guard let pngData = UIImage(cgImage: generated.cgImage).pngData() else {
                throw GenerationError.unavailable
            }
            return pngData
        }
        throw GenerationError.unavailable
    }
}

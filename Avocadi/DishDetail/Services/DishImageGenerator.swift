//
//  DishImageGenerator.swift
//  Avocadi
//
//  Created by Chema Martinez on 24/8/26.
//

import ImagePlayground
import UIKit

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

    /// Returns PNG data ready to store as `DishAIContentRecord.imageData`.
    ///
    /// `ImageCreator` doesn't expose a separate synchronous availability
    /// check the way `SystemLanguageModel` does — construction itself
    /// throws when image generation isn't available on this device, so
    /// that failure doubles as the availability check here.
    func generateImage(for dish: Dish) async throws -> Data {
        let creator = try await ImageCreator()
        let concepts: [ImagePlaygroundConcept] = [.text(dish.name)]
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

//
//  DishImageSweep.swift
//  Avocadi
//
//  Created by Chema Martinez on 29/8/26.
//

#if DEBUG
import Foundation
import OSLog

private let logger = Logger(subsystem: "dev.jmmartinez.Avocadi", category: "DishImageSweep")

/// A DEBUG-only diagnostic: runs every dish in `Menu.json` through image
/// generation and logs which ones `ImageCreator` refuses.
///
/// It exists because the failures were only ever found by hand, one dish at a
/// time — nine of them, all noticed because someone happened to open that
/// dish. That's a biased sample, and no amount of spot-checking turns it into
/// the actual failure set. This walks all of them, so a fix can be judged
/// against before/after counts rather than against whichever dishes came to
/// mind.
///
/// Deliberately writes nothing to `DishAIContentStore`. It's a diagnostic, not
/// a cache warm-up: the run should leave the device exactly as it found it, so
/// it can be repeated on the same build and compared.
enum DishImageSweep {
    private enum Outcome {
        case ok
        case failed(Error)
    }

    /// Generates an image for every dish, one at a time, logging each result.
    ///
    /// Serial on purpose: 75 concurrent `ImageCreator` runs would swamp the
    /// device's neural engine and turn a slow diagnostic into an unusable one.
    /// It is slow regardless — expect several minutes for the full menu — so it
    /// checks for cancellation between dishes and stops when the caller's task
    /// goes away.
    static func run(generator: DishImageGenerating = ImagePlaygroundDishImageGenerator()) async {
        let dishes: [Dish]
        do {
            dishes = try MenuLoader.load().meals.flatMap(\.dishCategories).flatMap(\.dishes)
        } catch {
            logger.error("Sweep couldn't load the menu: \(String(describing: error), privacy: .public)")
            return
        }

        logger.notice("Sweep starting over \(dishes.count, privacy: .public) dishes")

        var failures: [Dish] = []
        for dish in dishes {
            if Task.isCancelled {
                logger.notice("Sweep cancelled after \(failures.count, privacy: .public) failures")
                return
            }

            switch await outcome(of: dish, using: generator) {
            case .ok:
                logger.notice("ok   \(dish.id, privacy: .public)  \(dish.name, privacy: .public)")
            case .failed(let error):
                failures.append(dish)
                logger.error(
                    "FAIL \(dish.id, privacy: .public)  \(dish.name, privacy: .public)  — \(String(describing: error), privacy: .public)"
                )
            }
        }

        logger.notice(
            "Sweep finished: \(failures.count, privacy: .public) of \(dishes.count, privacy: .public) failed — \(failures.map(\.id).joined(separator: ", "), privacy: .public)"
        )
    }

    private static func outcome(of dish: Dish, using generator: DishImageGenerating) async -> Outcome {
        do {
            _ = try await generator.generateImage(for: dish)
            return .ok
        } catch {
            return .failed(error)
        }
    }
}
#endif

//
//  DishCategoryView.swift
//  Avocadi
//
//  Created by Chema Martinez on 21/8/26.
//

import SwiftUI

/// Shows a dish category's name as a title and its dishes as a numbered list.
///
/// This is a plain content view (no scrolling or outer padding of its own)
/// so it composes cleanly inside a container that already scrolls, such as
/// `DayView`.
struct DishCategoryView: View {
    let dishCategory: DishCategory

    @Environment(FavoritesStore.self) private var favorites

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(dishCategory.name)
                .font(.title2.bold())

            if let comment = dishCategory.comment {
                Text(comment)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(dishCategory.dishes.enumerated()), id: \.element.id) { index, dish in
                    NavigationLink(value: DishSelection(dish: dish, categoryName: dishCategory.name)) {
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text(verbatim: "\(index + 1).")
                                .foregroundStyle(.secondary)
                            dishName(dish)
                        }
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.primary)
                    // Named explicitly because the heart lives inside the
                    // name's own `Text` — left to combine on its own, VoiceOver
                    // would read the symbol's description as part of the dish.
                    // The state is announced as the link's value instead, so
                    // it stays audible rather than just visible.
                    .accessibilityLabel(dish.name)
                    .accessibilityValue(favorites.contains(dish.id) ? Text("Favorite") : Text(verbatim: ""))
                }
            }
        }
    }

    /// The dish name, with the heart flowing inline after its last word when
    /// the dish is a favorite.
    ///
    /// It has to be one `Text` rather than a sibling view in the `HStack`.
    /// Dish names here average 65 characters and routinely wrap, and a
    /// separate view is laid out against the *widest* line of the wrapped
    /// name, leaving the heart wherever that line happens to end — floating
    /// mid-row rather than reading as part of the dish. Pinning it to the
    /// row's trailing edge instead is stable, but that makes it an accessory
    /// column rather than part of the name, and reserving that column costs
    /// every row width it never uses.
    ///
    /// Both obvious spellings of "one `Text`" are wrong here, hence the
    /// interpolation built by hand. `Text + Text` is deprecated as of iOS 26,
    /// and the replacement it suggests — writing the interpolation as a
    /// literal, `Text("\(name) \(image)")` — is a `LocalizedStringKey`, so
    /// the build extracts a junk `"%@ %@"` key into the string catalog for
    /// five people to translate. A dish name is not copy and must stay out of
    /// there, the same reason the numbering above it uses `Text(verbatim:)`.
    ///
    /// Interpolating a `Text` rather than the `Image` directly is what lets
    /// the heart carry a size and a colour of its own.
    private func dishName(_ dish: Dish) -> Text {
        guard favorites.contains(dish.id) else { return Text(dish.name) }

        var interpolation = LocalizedStringKey.StringInterpolation(
            literalCapacity: 1,
            interpolationCount: 2
        )
        interpolation.appendInterpolation(dish.name)
        interpolation.appendLiteral(" ")
        interpolation.appendInterpolation(
            Text(Image(systemName: "heart.fill"))
                .font(.footnote)
                .foregroundStyle(Color.red)
        )
        return Text(key(from: interpolation))
    }

    /// Wraps the one call the string extractor watches for.
    ///
    /// Building the interpolation at runtime is not by itself enough to stay
    /// out of the catalog: the extractor keys off `LocalizedStringKey`'s
    /// interpolation initializer wherever it appears, literal or not, and
    /// reconstructs `"%@ %@"` from the `append` calls preceding it. It doesn't
    /// follow that reasoning across a function boundary, so making the call
    /// here leaves it with nothing to name.
    ///
    /// If that ever changes the result is the junk key being offered in the
    /// catalog again — noise to decline, not a build or runtime failure. The
    /// key itself is never found in any table at runtime either way, so it
    /// falls back to serving as its own format string, which is exactly the
    /// substitution wanted.
    private func key(from interpolation: LocalizedStringKey.StringInterpolation) -> LocalizedStringKey {
        LocalizedStringKey(stringInterpolation: interpolation)
    }
}

#Preview {
    ScrollView {
        DishCategoryView(
            dishCategory: DishCategory(
                id: "20-0",
                name: "Verduras + huevo",
                comment: nil,
                dishes: [
                    Dish(id: "20-0-0", name: "Tortilla francesa + queso fresco de cabra"),
                    Dish(id: "20-0-1", name: "Tortilla rellena de espinacas frescas, jamón cocido y queso mozzarella"),
                    Dish(id: "20-0-2", name: "Fajita integral con huevo plancha, tomate en rodajas y aguacate")
                ]
            )
        )
        .padding()
    }
    .environment(FavoritesStore.preview)
}

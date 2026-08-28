//
//  DishDetailView.swift
//  Avocadi
//
//  Created by Chema Martinez on 24/8/26.
//

import SwiftData
import SwiftUI
import UIKit

/// Shows a single dish with an Apple Intelligence–generated illustration
/// and description, generated on first visit and cached afterwards.
///
/// Purely declarative: all loading/generation/persistence logic lives in
/// `DishDetailViewModel`, this view just renders whatever state it reports.
///
/// The image section is shown as a fixed-size square in one of three
/// states (loading, loaded, unavailable), so its frame never jumps as
/// generation resolves. The description section, on the other hand, simply
/// doesn't appear when unavailable — there's no placeholder text for it, by
/// design.
///
/// With generated content switched off in settings both sections are absent
/// entirely, square included, leaving just the category and the dish name on
/// screen.
struct DishDetailView: View {
    let dish: Dish
    /// The category the dish was tapped under, shown above its name. Handed
    /// over by `DishSelection` because `Dish` itself doesn't know it.
    let categoryName: String

    @Environment(\.modelContext) private var modelContext
    @AppStorage(AIContentSettings.isEnabledKey)
    private var isAIContentEnabled = AIContentSettings.isEnabledDefault
    @State private var viewModel: DishDetailViewModel?

    private let imageCornerRadius: CGFloat = 16

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(categoryName)
                        .font(.caption.weight(.semibold))
                        .textCase(.uppercase)
                        .foregroundStyle(.secondary)

                    Text(dish.name)
                        .font(.largeTitle.bold())
                }

                imageSection

                if viewModel?.descriptionText != nil || viewModel?.isGeneratingDescription == true {
                    descriptionSection
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("Dish")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            // Reading `isAIContentEnabled` once, here, is enough: settings are
            // reachable only from the week view, so this screen is always
            // popped before the switch can change under it.
            guard viewModel == nil else { return }
            let vm = DishDetailViewModel(
                dish: dish,
                store: SwiftDataDishAIContentStore(modelContext: modelContext),
                descriptionGenerator: FoundationModelsDishDescriptionGenerator(),
                imageGenerator: ImagePlaygroundDishImageGenerator(),
                isAIContentEnabled: isAIContentEnabled
            )
            viewModel = vm
            await vm.load()
        }
    }

    /// Each state wraps itself in `imageSquare` rather than the switch being
    /// wrapped as a whole, because `hidden` has to skip the sizing modifiers
    /// too — sized but empty, it would leave a square-shaped gap under the
    /// dish name instead of disappearing.
    @ViewBuilder
    private var imageSection: some View {
        switch viewModel?.imageState ?? .loading {
        case .loaded(let data):
            if let uiImage = UIImage(data: data) {
                imageSquare {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                }
            } else {
                imageSquare { unavailableImagePlaceholder }
            }
        case .loading:
            imageSquare {
                Color(.systemGray5)
                    .shimmering()
            }
        case .unavailable:
            imageSquare { unavailableImagePlaceholder }
        case .hidden:
            EmptyView()
        }
    }

    /// The fixed-size square every visible image state shares, so switching
    /// between them never changes the layout.
    private func imageSquare(@ViewBuilder _ content: () -> some View) -> some View {
        content()
            .aspectRatio(1, contentMode: .fit)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: imageCornerRadius))
    }

    private var unavailableImagePlaceholder: some View {
        Color(.systemGray5)
            .overlay {
                // Reuses the same "no dish" icon the home-screen widget's
                // empty state already uses, for a consistent app-wide
                // symbol.
                Image(systemName: "fork.knife")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
            }
    }

    @ViewBuilder
    private var descriptionSection: some View {
        if let descriptionText = viewModel?.descriptionText {
            VStack(alignment: .leading, spacing: 8) {
                if let fallbackLanguage = viewModel?.fallbackLanguage {
                    fallbackNote(language: fallbackLanguage)
                }
                Text(descriptionText)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        } else if viewModel?.isGeneratingDescription == true {
            descriptionPlaceholder
        }
    }

    /// Explains a description that isn't in the app's language, which happens
    /// when Apple Intelligence can't write in it and generation fell back to
    /// the language the dish names themselves are in. Without this the screen
    /// just looks broken.
    ///
    /// Sits inside the `descriptionText` branch above rather than alongside
    /// it, so it can never appear over the loading placeholder — there is no
    /// description to explain yet at that point.
    private func fallbackNote(language: String) -> some View {
        // Named in the app's own language ("espanyol" to a Catalan reader),
        // falling back to the raw code if the system has no name for it.
        let appLanguage = viewModel?.appLanguage ?? language
        let languageName = Locale(identifier: appLanguage)
            .localizedString(forLanguageCode: language) ?? language

        return Text("The description below is in \(languageName) because Apple Intelligence can't generate text in this app's language.")
            .font(.footnote)
            .foregroundStyle(.tertiary)
    }

    /// Six redacted, shimmering lines of varying width standing in for the
    /// description while it generates — their actual text is irrelevant
    /// (`.redacted` hides it), only each line's rendered width matters,
    /// giving the placeholder a natural paragraph shape rather than uniform
    /// bars. Hence `Text(verbatim:)`: this is layout scaffolding, not copy, so
    /// it must stay out of the string catalog — a translator shortening these
    /// lines would silently reshape the placeholder.
    private var descriptionPlaceholder: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(verbatim: "Placeholder description line that is fairly long")
            Text(verbatim: "A shorter second placeholder line")
            Text(verbatim: "Short line")
            Text(verbatim: "Another placeholder line, this one a bit longer")
            Text(verbatim: "Yet another shorter placeholder line")
            Text(verbatim: "One last short line")
        }
        .font(.body)
        .foregroundStyle(.secondary)
        .redacted(reason: .placeholder)
        .shimmering()
    }
}

#Preview {
    NavigationStack {
        DishDetailView(
            dish: Dish(id: "20-0-0", name: "Tortilla francesa + queso fresco de cabra"),
            categoryName: "Verduras + huevo"
        )
    }
    .modelContainer(for: DishAIContent.self, inMemory: true)
}

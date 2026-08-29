//
//  SettingsView.swift
//  Avocadi
//
//  Created by Chema Martinez on 28/8/26.
//

import SwiftData
import SwiftUI

/// The app's settings, pushed from the week view's toolbar.
///
/// Holds one switch and one destructive action, deliberately kept as the two
/// separate things they are: the switch decides whether generated content is
/// produced and shown at all, while deleting throws away what's already on
/// disk. Turning the switch off doesn't delete anything — flipping it back on
/// restores every description and illustration instantly rather than paying
/// for generation again — so someone who wants the data actually gone needs
/// the button too.
///
/// Clearing favorites is a third thing again, in its own section on purpose.
/// It would be easy to fold into "Delete generated content" as one "reset the
/// app" button, and that would be wrong: everything else on this screen is
/// about what the machine wrote and can write again, while the hearts are the
/// only thing here the user typed in themselves and the only thing nothing can
/// regenerate.
struct SettingsView: View {
    @AppStorage(AIContentSettings.isEnabledKey)
    private var isAIContentEnabled = AIContentSettings.isEnabledDefault

    @Environment(\.modelContext) private var modelContext
    @Environment(FavoritesStore.self) private var favorites

    @State private var isConfirmingDelete = false
    @State private var isConfirmingClearFavorites = false
    #if DEBUG
    @State private var isSweepingDishImages = false
    #endif

    var body: some View {
        Form {
            Section {
                Toggle("Generated descriptions and images", isOn: $isAIContentEnabled)
            } header: {
                // A brand name, spelled identically in every language the app
                // ships. `verbatim` keeps it out of the string catalog, where
                // it would only ever be five copies of itself.
                Text(verbatim: "Apple Intelligence")
            } footer: {
                Text("Dishes show only their name when this is off. Nothing is generated, and anything generated before stays hidden.")
            }

            Section {
                Button("Delete generated content", role: .destructive) {
                    isConfirmingDelete = true
                }
            } footer: {
                Text("Removes every description and illustration saved on this device.")
            }

            Section {
                Button("Clear favorites", role: .destructive) {
                    isConfirmingClearFavorites = true
                }
            } footer: {
                Text("Removes every dish you've marked as a favorite on this device.")
            }

            #if DEBUG
            // Diagnostic, never shipped — see `DishImageSweep`. `verbatim`
            // for the same reason as the "Apple Intelligence" header above:
            // no user ever reads this, so it has no business in the string
            // catalog in five translations.
            Section {
                Button {
                    isSweepingDishImages = true
                    Task {
                        await DishImageSweep.run()
                        isSweepingDishImages = false
                    }
                } label: {
                    Text(verbatim: isSweepingDishImages ? "Sweeping dish images…" : "Sweep dish images")
                }
                .disabled(isSweepingDishImages)
            } footer: {
                Text(verbatim: "Generates an image for every dish and logs which ones Image Playground rejects. Takes several minutes; results go to Console, not to the cache.")
            }
            #endif
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "Delete all generated content?",
            isPresented: $isConfirmingDelete,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                deleteGeneratedContent()
            }
            // No explicit cancel button. Anchored to a form row like this,
            // the dialog comes up as a popover, which is dismissed by tapping
            // outside it and conventionally carries no cancel of its own —
            // adding one would just be a button the popover style doesn't ask
            // for, in five translations.
        }
        .confirmationDialog(
            "Clear all favorites?",
            isPresented: $isConfirmingClearFavorites,
            titleVisibility: .visible
        ) {
            Button("Clear", role: .destructive) {
                favorites.clear()
            }
        }
    }

    /// Goes through `SwiftDataDishAIContentStore` rather than the model context
    /// directly, so the one place that knows how `DishAIContent` is stored
    /// stays the one place that knows how it's thrown away.
    private func deleteGeneratedContent() {
        SwiftDataDishAIContentStore(modelContext: modelContext).deleteAll()
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .modelContainer(for: DishAIContent.self, inMemory: true)
    .environment(FavoritesStore.preview)
}

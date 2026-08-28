//
//  PromptLocalizationTests.swift
//  AvocadiTests
//
//  Created by Chema Martinez on 28/8/26.
//

import Testing
import Foundation
@testable import Avocadi

/// Guards the coupling between `Prompts.xcstrings` and the language stamped
/// onto cached descriptions.
///
/// `FoundationModelsDishDescriptionGenerator.language` reads
/// `prompt.language.code` out of that table precisely so the stamp can't
/// disagree with the prompt it describes — but a localization that declares the
/// wrong code there still compiles fine. It would just silently mis-stamp every
/// description it generates, which shows up either as descriptions that never
/// refresh after a language switch or as descriptions that regenerate on every
/// single launch. Both are the kind of bug that only surfaces in the wrong
/// language, long after the change that caused it.
///
/// `Bundle.main` is the host app here, so these read the same bundle the app
/// reads at runtime.
@MainActor
struct PromptLocalizationTests {

    @Test func spanishIsActuallyShipping() {
        #expect(Bundle.main.localizations.contains("es"))
    }

    /// The development region ships no `.strings` of its own — every value
    /// there is the source string, covered by `language`'s `defaultValue` — so
    /// only localizations with an `.lproj` can be checked this way.
    @Test func everyShippedLocalizationDeclaresItsOwnLanguageCode() {
        for localization in Bundle.main.localizations where localization != "Base" {
            guard let path = Bundle.main.path(forResource: localization, ofType: "lproj"),
                  let bundle = Bundle(path: path) else { continue }

            let code = bundle.localizedString(
                forKey: "prompt.language.code",
                value: "<missing>",
                table: "Prompts"
            )
            #expect(
                code == localization,
                "\(localization).lproj must declare prompt.language.code as \"\(localization)\", got \"\(code)\""
            )
        }
    }

    /// The widget is a separate bundle, so its strings have to be in *its*
    /// catalog — putting them in the app's would still build and still read
    /// correctly in English, and only show up as an untranslated widget
    /// gallery.
    @Test func widgetShipsItsOwnSpanishStrings() throws {
        let appexPath = try #require(
            Bundle.main.builtInPlugInsURL?
                .appendingPathComponent("AvocadiWidgetExtension.appex").path
        )
        let widgetBundle = try #require(Bundle(path: appexPath))
        let path = try #require(widgetBundle.path(forResource: "es", ofType: "lproj"))
        let spanish = try #require(Bundle(path: path))

        let galleryName = spanish.localizedString(
            forKey: "Today's menu",
            value: "<missing>",
            table: "Localizable"
        )
        #expect(galleryName == "Menú del día")
    }

    /// A prompt left untranslated would still read fine in English while
    /// claiming, via `prompt.language.code`, to be in the other language.
    @Test func spanishPromptsAreTranslatedNotJustTheLanguageCode() throws {
        let path = try #require(Bundle.main.path(forResource: "es", ofType: "lproj"))
        let bundle = try #require(Bundle(path: path))

        let label = bundle.localizedString(forKey: "Dish: %@", value: "<missing>", table: "Prompts")
        #expect(label == "Plato: %@")
    }
}

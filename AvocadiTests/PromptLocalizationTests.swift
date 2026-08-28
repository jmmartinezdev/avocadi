//
//  PromptLocalizationTests.swift
//  AvocadiTests
//
//  Created by Chema Martinez on 28/8/26.
//

import Testing
import Foundation
@testable import Avocadi

/// Guards the parts of localization that fail silently rather than failing to
/// compile.
///
/// Two things here can go wrong without anyone noticing. A localization that
/// declares the wrong `prompt.language.code` mis-stamps every description it
/// generates, which surfaces either as text that never refreshes after a
/// language switch or as text that regenerates on every single launch — see
/// `FoundationModelsDishDescriptionGenerator.language`. And a key left
/// untranslated in one language simply falls back to English at runtime, which
/// reads as "fine" to anyone testing in the other languages.
///
/// These are deliberately written against whatever the bundle actually ships
/// rather than against a list of languages, so adding one is covered without
/// touching them. `Bundle.main` is the host app here, so they read the same
/// bundles the app reads at runtime.
@MainActor
struct PromptLocalizationTests {

    private let sentinel = "<missing>"

    /// The one place a shipped language is written down. Adding a language means
    /// updating exactly here — every other test below then picks it up on its
    /// own and starts demanding its translations.
    @Test func everyIntendedLocalizationIsShipping() {
        let shipped = Set(Bundle.main.localizations)
        #expect(
            shipped.isSuperset(of: ["en", "es", "it", "ca"]),
            "app bundle ships \(shipped.sorted())"
        )
    }

    /// The development region ships no `.strings` of its own — every value there
    /// is the source string, covered by `language`'s `defaultValue` — so only
    /// localizations with an `.lproj` can be checked this way.
    @Test func everyShippedLocalizationDeclaresItsOwnLanguageCode() {
        var checked: [String] = []

        for localization in Bundle.main.localizations where localization != "Base" {
            guard let path = Bundle.main.path(forResource: localization, ofType: "lproj"),
                  let bundle = Bundle(path: path) else { continue }

            let code = bundle.localizedString(
                forKey: "prompt.language.code",
                value: sentinel,
                table: "Prompts"
            )
            #expect(
                code == localization,
                "\(localization).lproj must declare prompt.language.code as \"\(localization)\", got \"\(code)\""
            )
            checked.append(localization)
        }

        #expect(!checked.isEmpty, "no localization was actually checked")
    }

    /// Every localization has to translate the *same* keys. Comparing whole key
    /// sets rather than sampling a representative string is what makes this
    /// catch the realistic mistake — adding a language and filling in one
    /// catalog but not another — and it covers the widget, whose strings have to
    /// live in its own bundle. Filing them into the app's catalog instead would
    /// still build and still read correctly in English, showing up only as an
    /// untranslated widget gallery.
    @Test func everyLocalizationTranslatesTheSameKeys() throws {
        let targets: [(name: String, bundle: Bundle, tables: [String])] = [
            ("app", Bundle.main, ["Localizable", "Prompts"]),
            ("widget", try widgetBundle(), ["Localizable"]),
        ]

        for target in targets {
            for table in target.tables {
                var keysByLocalization: [String: Set<String>] = [:]
                for localization in target.bundle.localizations where localization != "Base" {
                    if let keys = keys(in: target.bundle, table: table, localization: localization) {
                        keysByLocalization[localization] = keys
                    }
                }

                // Fewer than two and there is nothing to compare — which would
                // mean this passed without checking anything.
                #expect(
                    keysByLocalization.count >= 2,
                    "\(target.name)/\(table): expected at least two localizations to compare, found \(keysByLocalization.keys.sorted())"
                )

                guard let reference = keysByLocalization.values.first else { continue }
                for (localization, keys) in keysByLocalization {
                    #expect(
                        keys == reference,
                        "\(target.name)/\(table): \(localization) differs by \(keys.symmetricDifference(reference).sorted())"
                    )
                }
            }
        }
    }

    private func widgetBundle() throws -> Bundle {
        let path = try #require(
            Bundle.main.builtInPlugInsURL?
                .appendingPathComponent("AvocadiWidgetExtension.appex").path
        )
        return try #require(Bundle(path: path))
    }

    /// Every key a localization actually ships for one table, read straight out
    /// of the compiled `.strings`. `nil` when that localization has no table at
    /// all, which for the development region is expected.
    private func keys(in bundle: Bundle, table: String, localization: String) -> Set<String>? {
        guard let path = bundle.path(forResource: localization, ofType: "lproj"),
              let lproj = Bundle(path: path),
              let url = lproj.url(forResource: table, withExtension: "strings"),
              let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil),
              let strings = plist as? [String: String] else { return nil }
        return Set(strings.keys)
    }
}

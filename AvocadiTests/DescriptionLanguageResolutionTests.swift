//
//  DescriptionLanguageResolutionTests.swift
//  AvocadiTests
//
//  Created by Chema Martinez on 28/8/26.
//

import Testing
@testable import Avocadi

/// Covers which language descriptions get generated in when the on-device
/// model can't write in the app's.
///
/// `SystemLanguageModel.supportsLocale` needs Apple Intelligence–capable
/// hardware, which no simulator is, so the real generator can never exercise
/// this in a test. That is exactly why the ordering lives in a pure
/// `resolveLanguage(appLanguage:contentLanguage:isSupported:)` — these tests
/// are the only coverage the fallback has.
struct DescriptionLanguageResolutionTests {

    private func resolve(app: String, supported: Set<String>) -> String? {
        FoundationModelsDishDescriptionGenerator.resolveLanguage(
            appLanguage: app,
            contentLanguage: "es",
            isSupported: { supported.contains($0) }
        )
    }

    @Test func supportedAppLanguageIsUsedAsIs() {
        #expect(resolve(app: "en", supported: ["en", "es", "it"]) == "en")
        #expect(resolve(app: "it", supported: ["en", "es", "it"]) == "it")
    }

    /// The Catalan case: the app is read in a language the model can't write,
    /// so descriptions come back in the language the dish names are already in.
    @Test func unsupportedAppLanguageFallsBackToTheContentLanguage() {
        #expect(resolve(app: "ca", supported: ["en", "es", "it"]) == "es")
    }

    /// With nothing to generate in, the generator reports itself unavailable
    /// rather than starting a shimmer that can only resolve into nothing.
    @Test func nothingSupportedResolvesToNil() {
        #expect(resolve(app: "ca", supported: []) == nil)
        #expect(resolve(app: "ca", supported: ["fr"]) == nil)
    }

    /// When the app language *is* the content language there's nothing to fall
    /// back to, so an unsupported Spanish must resolve to nil rather than
    /// retrying Spanish a second time.
    @Test func appLanguageEqualToContentLanguageIsNotTriedTwice() {
        #expect(resolve(app: "es", supported: ["en"]) == nil)
        #expect(resolve(app: "es", supported: ["es"]) == "es")
    }
}

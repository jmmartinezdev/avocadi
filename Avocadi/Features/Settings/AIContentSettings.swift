//
//  AIContentSettings.swift
//  Avocadi
//
//  Created by Chema Martinez on 28/8/26.
//

import Foundation

/// The app's single user preference: whether Apple Intelligence content —
/// dish descriptions and illustrations alike — is generated and shown at all.
///
/// The key and its default live here rather than inline at each `@AppStorage`
/// site so `SettingsView` (which writes it) and `DishDetailView` (which reads
/// it) can't drift apart on either. A typo in one of two string literals would
/// otherwise silently give the two screens separate switches.
enum AIContentSettings {
    static let isEnabledKey = "aiContentEnabled"

    /// On by default: the generated illustration and description are
    /// essentially the whole dish screen, so an app that shipped with this off
    /// would read as broken rather than as private.
    static let isEnabledDefault = true
}

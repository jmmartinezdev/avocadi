//
//  EmptyMenuView.swift
//  AvocadiWidget
//
//  Created by Chema Martinez on 23/08/2026.
//

import SwiftUI

/// Shown by every widget when its entry carries no days, which means the menu
/// failed to load.
struct EmptyMenuView: View {
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "fork.knife")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("No menu available")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

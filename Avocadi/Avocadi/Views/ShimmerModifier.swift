//
//  ShimmerModifier.swift
//  Avocadi
//
//  Created by Chema Martinez on 24/8/26.
//

import SwiftUI

/// A translucent gradient band that sweeps across a view on a loop,
/// signaling "still loading" the way a skeleton screen's shimmer typically
/// does. Generic on purpose so it can be reused on any future loading
/// placeholder, not just `DishDetailView`'s image section.
private struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.35), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width)
                    .offset(x: phase * geometry.size.width * 2 - geometry.size.width)
                }
                // Clips the gradient to content's own rendered shape, so it
                // only lights up actual content (e.g. each redacted text
                // line's bar) rather than sweeping across the surrounding
                // empty space in its bounding box (e.g. the gaps between
                // lines). For a fully opaque view like a solid color square,
                // this mask is a no-op.
                .mask(content)
            }
            .onAppear {
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

extension View {
    /// Overlays a looping shimmer sweep on top of this view, typically used
    /// on a plain color/shape as a loading placeholder.
    func shimmering() -> some View {
        modifier(ShimmerModifier())
    }
}

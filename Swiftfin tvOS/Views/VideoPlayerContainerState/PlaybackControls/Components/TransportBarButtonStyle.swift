//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// MARK: - Native tvOS Focus Button

/// A button wrapper that provides native Apple TV focus behavior
/// with the signature "lift and glow" effect
struct TransportBarButton<Label: View>: View {

    @FocusState
    private var isFocused: Bool

    let action: () -> Void
    let label: () -> Label

    init(
        action: @escaping () -> Void,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.action = action
        self.label = label
    }

    var body: some View {
        Button(action: action) {
            label()
                .font(.title3)
                .fontWeight(.medium)
                .foregroundStyle(isFocused ? .black : .white)
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background {
                    backgroundView
                }
        }
        .buttonStyle(.plain)
        .focused($isFocused)
        // Native Apple TV focus effect: lift + shadow
        .scaleEffect(isFocused ? 1.1 : 1.0)
        .shadow(
            color: isFocused ? .black.opacity(0.3) : .clear,
            radius: isFocused ? 20 : 0,
            x: 0,
            y: isFocused ? 15 : 0
        )
        // Use linear animation to reduce main thread load (prevents audio crackling)
        .animation(.linear(duration: 0.15), value: isFocused)
    }

    @ViewBuilder
    private var backgroundView: some View {
        if isFocused {
            // Focused: solid white capsule (Apple TV standard)
            Capsule().fill(Color.white)
        } else {
            // Unfocused: transparent - button blends with transport bar glass
            Color.clear
        }
    }
}

// MARK: - Transport Bar Menu Button

/// A menu wrapper with native focus behavior
struct TransportBarMenu<Label: View, Content: View>: View {

    @FocusState
    private var isFocused: Bool

    let title: String
    let label: () -> Label
    let content: () -> Content

    init(
        _ title: String,
        @ViewBuilder label: @escaping () -> Label,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.label = label
        self.content = content
    }

    var body: some View {
        Menu {
            content()
        } label: {
            label()
                .font(.title3)
                .fontWeight(.medium)
                .foregroundStyle(isFocused ? .black : .white)
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background {
                    backgroundView
                }
        }
        .focused($isFocused)
        .scaleEffect(isFocused ? 1.1 : 1.0)
        .shadow(
            color: isFocused ? .black.opacity(0.3) : .clear,
            radius: isFocused ? 20 : 0,
            x: 0,
            y: isFocused ? 15 : 0
        )
        // Use linear animation to reduce main thread load (prevents audio crackling)
        .animation(.linear(duration: 0.15), value: isFocused)
    }

    @ViewBuilder
    private var backgroundView: some View {
        if isFocused {
            // Focused: solid white capsule (Apple TV standard)
            Capsule().fill(Color.white)
        } else {
            // Unfocused: transparent - button blends with transport bar glass
            Color.clear
        }
    }
}

// MARK: - Legacy ButtonStyle (kept for compatibility)

/// Button style for transport bar action buttons
/// Note: Prefer TransportBarButton for proper focus handling
struct TransportBarButtonStyle: ButtonStyle {

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title3)
            .fontWeight(.medium)
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background {
                if #available(tvOS 18.0, *) {
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .opacity(configuration.isPressed ? 1.0 : 0.8)
                } else {
                    Capsule()
                        .fill(.white.opacity(configuration.isPressed ? 0.5 : 0.3))
                }
            }
            .scaleEffect(configuration.isPressed ? 1.05 : 1.0)
            .animation(.spring(response: 0.2), value: configuration.isPressed)
    }
}

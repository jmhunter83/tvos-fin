//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct CapsuleSlider<Value: BinaryFloatingPoint>: View {

    @Binding
    private var value: Value

    private let total: Value
    private var onEditingChanged: (Bool) -> Void

    init(value: Binding<Value>, total: Value) {
        self._value = value
        self.total = total
        self.onEditingChanged = { _ in }
    }

    var body: some View {
        SliderContainer(
            value: $value,
            total: total,
            onEditingChanged: onEditingChanged
        ) {
            CapsuleSliderContent()
        }
    }
}

extension CapsuleSlider {

    func onEditingChanged(_ action: @escaping (Bool) -> Void) -> Self {
        copy(modifying: \.onEditingChanged, with: action)
    }
}

private struct CapsuleSliderContent: SliderContentView {

    @EnvironmentObject
    var sliderState: SliderContainerState<Double>

    var body: some View {
        ProgressView(value: sliderState.value, total: sliderState.total)
            .progressViewStyle(PlaybackProgressViewStyle(cornerStyle: .round))
            .frame(height: 8)
            .scaleEffect(sliderState.isFocused ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: sliderState.isFocused)
    }
}

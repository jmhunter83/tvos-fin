//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct SliderContainer<Value: BinaryFloatingPoint>: UIViewRepresentable {

    private var value: Binding<Value>
    private let total: Value
    private let onEditingChanged: (Bool) -> Void
    private let view: AnyView

    init(
        value: Binding<Value>,
        total: Value,
        onEditingChanged: @escaping (Bool) -> Void = { _ in },
        @ViewBuilder view: @escaping () -> some SliderContentView
    ) {
        self.value = value
        self.total = total
        self.onEditingChanged = onEditingChanged
        self.view = AnyView(view())
    }

    init(
        value: Binding<Value>,
        total: Value,
        onEditingChanged: @escaping (Bool) -> Void = { _ in },
        view: AnyView
    ) {
        self.value = value
        self.total = total
        self.onEditingChanged = onEditingChanged
        self.view = view
    }

    func makeUIView(context: Context) -> UISliderContainer<Value> {
        UISliderContainer(
            value: value,
            total: total,
            onEditingChanged: onEditingChanged,
            view: view
        )
    }

    func updateUIView(_ uiView: UISliderContainer<Value>, context: Context) {
        // Don't update value while user is actively scrubbing to prevent jumps
        guard !uiView.containerState.isEditing else { return }
        DispatchQueue.main.async {
            uiView.containerState.value = value.wrappedValue
        }
    }
}

/// A slider container that displays progress, handles focus, and supports swipe-to-scrub.
/// Click-first paradigm: click to enter scrub mode, swipe to scrub, click to commit.
final class UISliderContainer<Value: BinaryFloatingPoint>: UIControl {

    private let onEditingChanged: (Bool) -> Void
    private let total: Value
    private let valueBinding: Binding<Value>

    // MARK: - Scrub Mode State

    /// Whether user is in active scrub mode (after clicking to enter)
    private var isInScrubMode: Bool = false

    /// Value being scrubbed (separate from committed value)
    private var scrubbedValue: Value = 0

    /// Value when scrub mode was entered (for cancel/revert)
    private var valueAtScrubStart: Value = 0

    /// Damping factor: higher = slower/more precise scrubbing
    /// Dynamic based on video duration for consistent feel
    private var dampingFactor: CGFloat {
        // Base damping of 5.0, scales up for longer videos
        // 10 min video = 5.0, 2hr video = 12.0
        let totalSeconds = CGFloat(total)
        return max(5.0, min(15.0, totalSeconds / 600))
    }

    private lazy var progressHostingController: UIHostingController<AnyView> = {
        let hostingController = UIHostingController(rootView: AnyView(view.environmentObject(containerState)))
        hostingController.view.backgroundColor = .clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        return hostingController
    }()

    private var progressHostingView: UIView { progressHostingController.view }

    let containerState: SliderContainerState<Value>
    let view: AnyView

    init(
        value: Binding<Value>,
        total: Value,
        onEditingChanged: @escaping (Bool) -> Void,
        view: AnyView
    ) {
        self.onEditingChanged = onEditingChanged
        self.total = total
        self.valueBinding = value
        self.containerState = .init(
            isEditing: false,
            isFocused: false,
            value: value.wrappedValue,
            total: total
        )
        self.view = view
        super.init(frame: .zero)

        setupViews()
        setupGestures()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        addSubview(progressHostingView)
        NSLayoutConstraint.activate([
            progressHostingView.leadingAnchor.constraint(equalTo: leadingAnchor),
            progressHostingView.trailingAnchor.constraint(equalTo: trailingAnchor),
            progressHostingView.topAnchor.constraint(equalTo: topAnchor),
            progressHostingView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    private func setupGestures() {
        // Pan gesture for swipe-to-scrub
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        panGesture.allowedTouchTypes = [NSNumber(value: UITouch.TouchType.indirect.rawValue)]
        addGestureRecognizer(panGesture)
    }

    // MARK: - Focus

    override var canBecomeFocused: Bool {
        true
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        let wasFocused = containerState.isFocused
        containerState.isFocused = (context.nextFocusedView == self)

        // Exit scrub mode if we lose focus
        if wasFocused && !containerState.isFocused && isInScrubMode {
            cancelScrubMode()
        }
    }

    // MARK: - Press Handling (Click to Enter/Exit Scrub Mode)

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard containerState.isFocused else {
            super.pressesBegan(presses, with: event)
            return
        }

        for press in presses {
            switch press.type {
            case .select:
                // Click toggles scrub mode
                if isInScrubMode {
                    commitScrubMode()
                } else {
                    enterScrubMode()
                }
                return
            case .menu:
                // Menu cancels scrub mode (reverts to original position)
                if isInScrubMode {
                    cancelScrubMode()
                    return
                }
            default:
                break
            }
        }

        super.pressesBegan(presses, with: event)
    }

    // MARK: - Scrub Mode Management

    private func enterScrubMode() {
        isInScrubMode = true
        valueAtScrubStart = valueBinding.wrappedValue
        scrubbedValue = valueBinding.wrappedValue
        containerState.isEditing = true
        onEditingChanged(true)
    }

    private func commitScrubMode() {
        isInScrubMode = false
        // Commit the scrubbed value
        valueBinding.wrappedValue = scrubbedValue
        containerState.isEditing = false
        onEditingChanged(false)
    }

    private func cancelScrubMode() {
        isInScrubMode = false
        // Revert to original value
        scrubbedValue = valueAtScrubStart
        containerState.value = valueAtScrubStart
        valueBinding.wrappedValue = valueAtScrubStart
        containerState.isEditing = false
        onEditingChanged(false)
    }

    // MARK: - Pan Gesture Handling

    @objc
    private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard containerState.isFocused else { return }

        switch gesture.state {
        case .began:
            // Auto-enter scrub mode on pan start if not already in it
            if !isInScrubMode {
                enterScrubMode()
            }

        case .changed:
            guard isInScrubMode else { return }

            let translation = gesture.translation(in: self)

            // Calculate value delta with damping for precision
            // Touchpad displacement is mapped to percentage of total duration
            let scrubDelta = Value(translation.x / dampingFactor)

            // Map pixel delta to value delta (based on view width to total ratio)
            let viewWidth = bounds.width > 0 ? bounds.width : 1000 // Fallback for zero width
            let valueDelta = scrubDelta / Value(viewWidth) * total

            // Update scrubbed position (clamped to valid range)
            scrubbedValue = max(0, min(total, scrubbedValue + valueDelta))

            // Update visual state
            containerState.value = scrubbedValue

            // Update binding for real-time time label updates
            valueBinding.wrappedValue = scrubbedValue

            // Reset translation for incremental updates
            gesture.setTranslation(.zero, in: self)

        case .ended, .cancelled:
            // On gesture end, commit if in scrub mode
            if isInScrubMode {
                commitScrubMode()
            }

        default:
            break
        }
    }
}

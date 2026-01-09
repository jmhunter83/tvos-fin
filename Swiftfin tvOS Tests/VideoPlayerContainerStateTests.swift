//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

@testable import Swiftfin_tvOS
import XCTest

/// Tests for VideoPlayerContainerState
@MainActor
final class VideoPlayerContainerStateTests: XCTestCase {

    var sut: VideoPlayerContainerState!

    override func setUp() async throws {
        sut = VideoPlayerContainerState()
    }

    override func tearDown() async throws {
        sut = nil
    }

    // MARK: - Overlay State Tests

    func testInitialOverlayStateIsHidden() {
        XCTAssertEqual(sut.overlayState, .hidden)
        XCTAssertFalse(sut.isPresentingOverlay)
    }

    func testSettingIsPresentingOverlayUpdatesOverlayState() {
        sut.isPresentingOverlay = true

        XCTAssertEqual(sut.overlayState, .visible)
        XCTAssertTrue(sut.isPresentingOverlay)
    }

    func testSettingIsPresentingOverlayToFalseUpdatesOverlayState() {
        sut.isPresentingOverlay = true
        sut.isPresentingOverlay = false

        XCTAssertEqual(sut.overlayState, .hidden)
        XCTAssertFalse(sut.isPresentingOverlay)
    }

    func testGestureLockPreventsOverlayFromShowing() {
        sut.isGestureLocked = true
        sut.isPresentingOverlay = true // Should be ignored

        XCTAssertEqual(sut.overlayState, .locked)
        XCTAssertFalse(sut.isPresentingOverlay) // Still false because locked
    }

    func testUnlockingGestureResetsToHidden() {
        sut.isGestureLocked = true
        sut.isGestureLocked = false

        XCTAssertEqual(sut.overlayState, .hidden)
        XCTAssertFalse(sut.isGestureLocked)
    }

    // MARK: - Supplement State Tests

    func testInitialSupplementStateIsClosed() {
        XCTAssertEqual(sut.supplementState, .closed)
        XCTAssertFalse(sut.isPresentingSupplement)
    }

    func testPresentationControllerShouldDismissWhenSupplementClosed() {
        XCTAssertTrue(sut.presentationControllerShouldDismiss)
    }

    // MARK: - Scrub State Tests

    func testInitialScrubStateIsIdle() {
        XCTAssertEqual(sut.scrubState, .idle)
        XCTAssertFalse(sut.isScrubbing)
    }

    func testSettingIsScrubbingUpdatesScrubState() {
        sut.isScrubbing = true

        XCTAssertEqual(sut.scrubState, .scrubbing)
        XCTAssertTrue(sut.isScrubbing)
    }

    func testSettingIsScrubbingToFalseReturnsToIdle() {
        sut.isScrubbing = true
        sut.isScrubbing = false

        XCTAssertEqual(sut.scrubState, .idle)
        XCTAssertFalse(sut.isScrubbing)
    }

    // MARK: - Helper Method Tests

    func testSetOverlayVisibleTrue() {
        sut.setOverlayVisible(true, animated: false)

        XCTAssertEqual(sut.overlayState, .visible)
    }

    func testSetOverlayVisibleFalse() {
        sut.setOverlayVisible(true, animated: false)
        sut.setOverlayVisible(false, animated: false)

        XCTAssertEqual(sut.overlayState, .hidden)
    }

    func testSetOverlayVisibleIgnoredWhenLocked() {
        sut.isGestureLocked = true
        sut.setOverlayVisible(true, animated: false)

        XCTAssertEqual(sut.overlayState, .locked)
    }

    func testToggleOverlay() {
        sut.toggleOverlay()
        XCTAssertEqual(sut.overlayState, .visible)

        sut.toggleOverlay()
        XCTAssertEqual(sut.overlayState, .hidden)
    }
}

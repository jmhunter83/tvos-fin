//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

@testable import Swiftfin_tvOS
import XCTest

/// Tests for MediaError
final class MediaErrorTests: XCTestCase {

    // MARK: - Error Description Tests

    func testNoPlayableSourceDescription() {
        let error = MediaError.noPlayableSource
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("playable"))
    }

    func testUnsupportedFormatWithFormat() {
        let error = MediaError.unsupportedFormat(format: "HEVC")
        XCTAssertTrue(error.errorDescription!.contains("HEVC"))
    }

    func testUnsupportedFormatWithoutFormat() {
        let error = MediaError.unsupportedFormat(format: nil)
        XCTAssertTrue(error.errorDescription!.contains("format"))
    }

    func testItemNotFoundWithId() {
        let error = MediaError.itemNotFound(itemId: "abc123")
        XCTAssertTrue(error.errorDescription!.contains("abc123"))
    }

    func testItemNotFoundWithoutId() {
        let error = MediaError.itemNotFound(itemId: nil)
        XCTAssertTrue(error.errorDescription!.contains("not found"))
    }

    // MARK: - Error Title Tests

    func testNoPlayableSourceTitle() {
        XCTAssertEqual(MediaError.noPlayableSource.errorTitle, "Cannot Play")
    }

    func testTranscodingFailedTitle() {
        XCTAssertEqual(MediaError.transcodingFailed(reason: nil).errorTitle, "Transcoding Error")
    }

    func testStreamEndedTitle() {
        XCTAssertEqual(MediaError.streamEnded.errorTitle, "Playback Error")
    }

    func testItemNotFoundTitle() {
        XCTAssertEqual(MediaError.itemNotFound(itemId: nil).errorTitle, "Item Error")
    }

    func testSessionExpiredTitle() {
        XCTAssertEqual(MediaError.sessionExpired.errorTitle, "Session Error")
    }

    // MARK: - Retryability Tests

    func testTranscodingFailedIsRetryable() {
        XCTAssertTrue(MediaError.transcodingFailed(reason: nil).isRetryable)
    }

    func testStreamEndedIsRetryable() {
        XCTAssertTrue(MediaError.streamEnded.isRetryable)
    }

    func testLoadFailedIsRetryable() {
        XCTAssertTrue(MediaError.loadFailed(reason: nil).isRetryable)
    }

    func testSessionExpiredIsRetryable() {
        XCTAssertTrue(MediaError.sessionExpired.isRetryable)
    }

    func testNoPlayableSourceIsNotRetryable() {
        XCTAssertFalse(MediaError.noPlayableSource.isRetryable)
    }

    func testUnsupportedFormatIsNotRetryable() {
        XCTAssertFalse(MediaError.unsupportedFormat(format: nil).isRetryable)
    }

    func testItemNotFoundIsNotRetryable() {
        XCTAssertFalse(MediaError.itemNotFound(itemId: nil).isRetryable)
    }

    func testNotPlayableIsNotRetryable() {
        XCTAssertFalse(MediaError.notPlayable.isRetryable)
    }

    // MARK: - Hashable Conformance Tests

    func testErrorsAreHashable() {
        var set = Set<MediaError>()
        set.insert(.noPlayableSource)
        set.insert(.streamEnded)
        set.insert(.noPlayableSource) // Duplicate

        XCTAssertEqual(set.count, 2)
    }

    func testDifferentItemNotFoundErrorsAreDistinct() {
        let error1 = MediaError.itemNotFound(itemId: "abc")
        let error2 = MediaError.itemNotFound(itemId: "xyz")

        XCTAssertNotEqual(error1, error2)
    }
}

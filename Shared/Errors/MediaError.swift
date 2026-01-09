//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

/// Errors that can occur during media playback
enum MediaError: LocalizedError, Hashable {

    // MARK: - Playback Errors

    /// No playable media source available for this item
    case noPlayableSource

    /// The media format is not supported
    case unsupportedFormat(format: String?)

    /// Transcoding failed on the server
    case transcodingFailed(reason: String?)

    /// The media stream ended unexpectedly
    case streamEnded

    /// Failed to load the media
    case loadFailed(reason: String?)

    // MARK: - Item Errors

    /// The requested item was not found
    case itemNotFound(itemId: String?)

    /// The item has no associated media
    case noMediaInfo

    /// The item type is not playable
    case notPlayable

    // MARK: - Session Errors

    /// Failed to create a playback session
    case sessionCreationFailed

    /// The playback session expired
    case sessionExpired

    /// Failed to report playback progress
    case reportingFailed

    // MARK: - LocalizedError

    var errorDescription: String? {
        switch self {
        case .noPlayableSource:
            return "No playable source available for this item."
        case let .unsupportedFormat(format):
            if let format {
                return "The media format '\(format)' is not supported."
            }
            return "The media format is not supported."
        case let .transcodingFailed(reason):
            return reason ?? "Server transcoding failed."
        case .streamEnded:
            return "The media stream ended unexpectedly."
        case let .loadFailed(reason):
            return reason ?? "Failed to load media."
        case let .itemNotFound(itemId):
            if let itemId {
                return "Item '\(itemId)' was not found."
            }
            return "The requested item was not found."
        case .noMediaInfo:
            return "No media information available for this item."
        case .notPlayable:
            return "This item type cannot be played."
        case .sessionCreationFailed:
            return "Failed to create playback session."
        case .sessionExpired:
            return "Your playback session has expired."
        case .reportingFailed:
            return "Failed to report playback progress."
        }
    }

    /// A user-friendly title for the error
    var errorTitle: String {
        switch self {
        case .noPlayableSource, .unsupportedFormat, .notPlayable:
            return "Cannot Play"
        case .transcodingFailed:
            return "Transcoding Error"
        case .streamEnded, .loadFailed:
            return "Playback Error"
        case .itemNotFound, .noMediaInfo:
            return "Item Error"
        case .sessionCreationFailed, .sessionExpired, .reportingFailed:
            return "Session Error"
        }
    }

    /// Whether the user should retry
    var isRetryable: Bool {
        switch self {
        case .transcodingFailed, .streamEnded, .loadFailed, .sessionExpired, .reportingFailed:
            return true
        case .noPlayableSource, .unsupportedFormat, .itemNotFound, .noMediaInfo, .notPlayable, .sessionCreationFailed:
            return false
        }
    }
}

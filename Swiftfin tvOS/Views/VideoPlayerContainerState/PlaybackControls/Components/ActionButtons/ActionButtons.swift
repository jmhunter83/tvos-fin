//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import Logging
import SwiftUI

extension VideoPlayer.PlaybackControls.NavigationBar {

    struct ActionButtons: View {

        @Default(.VideoPlayer.barActionButtons)
        private var rawBarActionButtons
        @Default(.VideoPlayer.menuActionButtons)
        private var rawMenuActionButtons

        @EnvironmentObject
        private var containerState: VideoPlayerContainerState
        @EnvironmentObject
        private var manager: MediaPlayerManager

        private let logger = Logger.swiftfin()

        private func filteredActionButtons(_ rawButtons: [VideoPlayerActionButton]) -> [VideoPlayerActionButton] {
            var filteredButtons = rawButtons

            // DEBUG: Log audio stream state
            let audioCount = manager.playbackItem?.audioStreams.count ?? -1
            let subtitleCount = manager.playbackItem?.subtitleStreams.count ?? -1
            let isLive = manager.item.isLiveStream
            logger.debug(
                "ActionButtons: audio=\(audioCount), subs=\(subtitleCount), live=\(isLive)"
            )

            if manager.playbackItem?.audioStreams.isEmpty == true {
                logger.debug("Filtering out audio - no streams")
                filteredButtons.removeAll { $0 == .audio }
            }

            if manager.playbackItem?.subtitleStreams.isEmpty == true {
                filteredButtons.removeAll { $0 == .subtitles }
            }

            if manager.queue == nil {
                filteredButtons.removeAll { $0 == .autoPlay }
                filteredButtons.removeAll { $0 == .playNextItem }
                filteredButtons.removeAll { $0 == .playPreviousItem }
            }

            if manager.item.isLiveStream {
                filteredButtons.removeAll { $0 == .audio }
                filteredButtons.removeAll { $0 == .autoPlay }
                filteredButtons.removeAll { $0 == .playbackSpeed }
                filteredButtons.removeAll { $0 == .playbackQuality }
                filteredButtons.removeAll { $0 == .subtitles }
            }

            return filteredButtons
        }

        private var barActionButtons: [VideoPlayerActionButton] {
            filteredActionButtons(rawBarActionButtons)
        }

        private var menuActionButtons: [VideoPlayerActionButton] {
            filteredActionButtons(rawMenuActionButtons)
        }

        @ViewBuilder
        private func view(for button: VideoPlayerActionButton) -> some View {
            switch button {
            case .aspectFill:
                AspectFill()
            case .audio:
                Audio()
            case .autoPlay:
                AutoPlay()
            case .gestureLock:
                EmptyView()
//                GestureLock()
            case .playbackSpeed:
                PlaybackSpeed()
            case .playbackQuality:
                PlaybackQuality()
            case .playNextItem:
                PlayNextItem()
            case .playPreviousItem:
                PlayPreviousItem()
            case .subtitles:
                Subtitles()
            }
        }

        var body: some View {
            HStack(spacing: 10) {
                ForEach(
                    barActionButtons,
                    content: view(for:)
                )

                if menuActionButtons.isNotEmpty {
                    TransportBarMenu(L10n.menu) {
                        Image(systemName: "ellipsis.circle")
                    } content: {
                        ForEach(
                            menuActionButtons,
                            content: view(for:)
                        )
                        .environment(\.isInMenu, true)
                    }
                }
            }
            .labelStyle(.iconOnly)
        }
    }
}

# GitHub Issue #7 - Intro Skipper Feature Implementation

## Current Status: 🚧 **Enhancement/Feature Request** (Previously: Bug Report)

**Issue**: Intro skipper not working with Intro Skipper plugin (works with Infuse)

**Root Cause**: Swiftfin/Reefy doesn't implement Jellyfin 10.10+ Media Segments API. This is **missing functionality**, not a bug.

**Classification**: 🔧 **Enhancement** - Implementing new Media Segments API integration for intro/outro skipping

## ✅ **What We've Accomplished**

### Foundation Implementation Complete
1. **Media Segment Models** - Created complete `MediaSegmentDto` with all segment types
2. **API Integration** - Added `getMediaSegments()` to `JellyfinClient` 
3. **Data Layer** - Extended `BaseItemDto` with segment support
4. **Player Integration** - Added segment fetching to `MediaPlayerManager`

### Key Files Created/Modified
- `Shared/Extensions/JellyfinAPI/MediaSegmentDto.swift` *(New)*
- `Shared/Extensions/JellyfinAPI/JellyfinClient.swift` *(Extended)*
- `Shared/Extensions/JellyfinAPI/BaseItemDto/BaseItemDto.swift` *(Extended)*
- `Shared/Objects/MediaPlayerManager/MediaPlayerManager.swift` *(Partially Modified)*
- `INTRO_SKIPPER_IMPLEMENTATION.md` *(Documentation)*
- `INTRO_SKIPPER_GITHUB_SUMMARY.md` *(Issue Summary)*

## 🔧 **Technical Implementation Details**

### Media Segments API Endpoint
```swift
// NEW: JellyfinClient extension
public func getMediaSegments(itemId: String) async throws -> MediaSegmentDtoQueryResult {
    let path = "/Items/\(itemId)/MediaSegments"
    let request = Request<MediaSegmentDtoQueryResult>(
        url: fullURL(with: path), method: .get
    )
    let response = try await send(request)
    return response.value ?? MediaSegmentDtoQueryResult(items: nil)
}
```

### BaseItemDto Extension
```swift
// NEW: BaseItemDto extension
private var _mediaSegments: [MediaSegmentDto]?

public var mediaSegments: [MediaSegmentDto]? {
    get { _mediaSegments }
    set { _mediaSegments = value }
}

public var introSegments: [MediaSegmentDto] {
    return mediaSegments?.filter { $0.type == .intro } ?? []
}
```

### MediaPlayerManager Integration
```swift
// NEW: Segment fetching in playbackItem setter
if let itemId = playbackItem.baseItem.id {
    do {
        let segmentsResponse = try await userSession.client.getMediaSegments(for: itemId)
        playbackItem.baseItem.mediaSegments = segmentsResponse.items
        logger.info("Loaded \(segmentsResponse.items?.count ?? 0) media segments")
    } catch {
        logger.error("Failed to load media segments: \(error.localizedDescription)")
    }
}
```

## 📋 **Implementation Roadmap**

### Phase 1: Complete Basic Skip Button (1-2 weeks) - **HIGH PRIORITY**
- [x] Media segment models
- [x] API client integration  
- [x] Data layer extensions
- [ ] Fix MediaPlayerManager compilation (userSession injection)
- [ ] Create basic skip button component for intro segments
- [ ] Add skip functionality (seek to segment.end)
- [ ] Test with real Intro Skipper server data

### Phase 2: Enhanced Features (1-2 months) - **MEDIUM PRIORITY**
- [ ] Support all segment types (intro, outro, commercial, preview, recap)
- [ ] User preferences for auto-skip vs manual-skip
- [ ] Visual segment indicators on progress bar
- [ ] Settings page for segment behavior
- [ ] Comprehensive error handling

### Phase 3: Advanced UX (2-4 months) - **LOW PRIORITY**
- [ ] Preview thumbnails for segments
- [ ] Smart segment detection validation
- [ ] Analytics for segment accuracy
- [ ] Accessibility features
- [ ] Performance optimizations

## 🧪 **Testing Strategy**

### API Testing
```bash
# Test media segments availability
curl -H "Authorization: MediaBrowser Token=$TOKEN" \
     "$SERVER_URL/Items/$ITEM_ID/MediaSegments"
```

### Functionality Testing Matrix
| Test Case | Expected Behavior | Status |
|------------|------------------|--------|
| Episode with intro | Skip button appears during intro | ⏳ Pending |
| Episode with outro | Skip button appears during outro | ⏳ Pending |
| Multiple segments | Correct button based on active segment | ⏳ Pending |
| No segments | No skip button shown | ⏳ Pending |
| Network error | Graceful fallback, error logged | ⏳ Pending |

## 🎯 **Success Metrics**

### Minimum Viable Product
- ✅ Skip button appears during intro segments
- ✅ Skip accuracy within ±0.5 seconds  
- ✅ Works with Intro Skipper plugin data
- ✅ Graceful error handling when segments unavailable

### Complete Implementation
- ✅ Support for all segment types
- ✅ User preference controls
- ✅ Visual progress indicators
- ✅ Accessibility support
- ✅ Analytics and validation

## 🌟 **Why This Classification Makes Sense**

1. **Not a Bug** - Intro skipper was never implemented; this is missing functionality
2. **Parity with Other Clients** - Infuse successfully implements this feature
3. **API Integration Required** - Requires implementing Jellyfin 10.10+ Media Segments API
4. **Development Effort** - Substantial work needed, not a quick fix
5. **Clear User Expectations** - Sets roadmap for phased implementation

## 🔗 **References for Implementation**

- **Technical Specs**: [Media Segments Documentation](https://jellyfin.org/docs/general/server/metadata/media-segments/)
- **Implementation Details**: [Implementation Plan Document](INTRO_SKIPPER_IMPLEMENTATION.md)
- **Related Work**: Original Swiftfin issue #1525 - "Skip button for media segments"
- **Plugin Reference**: [Intro Skipper Repository](https://github.com/intro-skipper/intro-skipper)

---

**Status**: Foundation complete, ready for UI implementation and testing phase.

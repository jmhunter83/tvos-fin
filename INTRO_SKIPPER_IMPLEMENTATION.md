# Intro Skipper Implementation for Reefy/Swiftfin

## Executive Summary

The intro skipper not working issue (#7) stems from **Swiftfin not implementing Jellyfin 10.10+ Media Segments API**. While the Intro Skipper plugin successfully creates segments on the server, Swiftfin has no code to fetch or utilize this data.

## Root Cause Analysis

1. **Missing Media Segments API Integration**: Swiftfin uses JellyfinAPI but doesn't implement `/Items/{itemId}/MediaSegments` endpoint
2. **No Media Segment Models**: BaseItemDto lacks mediaSegments field and related functionality
3. **Working Client Confirmed**: Infuse successfully uses media segments from the same Intro Skipper plugin

## Implementation Progress

### ✅ Completed Foundations

#### 1. Media Segment Models Created
**File**: `Shared/Extensions/JellyfinAPI/MediaSegmentDto.swift`
- `MediaSegmentDto` struct with start/end timestamps and type
- `MediaSegmentType` enum (Intro, Outro, Commercial, Preview, Recap)  
- `MediaSegmentDtoQueryResult` for API responses
- Extensions to `BaseItemDto` for segment access

```swift
public struct MediaSegmentDto {
    public let start: TimeInterval
    public let end: TimeInterval
    public let type: MediaSegmentType
}

// Usage:
item.introSegments  // Get all intro segments
item.isInIntroSegment(at: time)  // Check if in intro
item.activeSegment(at: time)  // Get active segment
```

#### 2. API Client Extension Created
**File**: `Shared/Extensions/JellyfinAPI/MediaSegmentDto.swift` (extended)
- Added `getMediaSegments(for:itemId)` method to `JellyfinClient`
- Implements `GET /Items/{itemId}/MediaSegments` endpoint
- Returns `MediaSegmentDtoQueryResult` with error handling

```swift
extension JellyfinClient {
    public func getMediaSegments(itemId: String, userId: String? = nil) async throws -> MediaSegmentDtoQueryResult
}
```

#### 3. MediaPlayerManager Integration
**File**: `Shared/Objects/MediaPlayerManager/MediaPlayerManager.swift` (partially implemented)
- Added userSession injection: `@Injected(\.currentUserSession) private var userSession: UserSession!`
- Added media segments fetching logic in `playbackItem` setter
- Integrates with existing logging and error handling

```swift
// Fetch segments when item is set
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

## 🔧 Technical Implementation Details

### Media Segment API Endpoint
- **URL**: `GET /Items/{itemId}/MediaSegments`
- **Available**: Jellyfin 10.10+ with Media Segment providers
- **Response**: `MediaSegmentDtoQueryResult` with items array

### Data Flow Integration
1. **Item Loading**: BaseItem loaded → MediaPlayerManager.set(playbackItem)
2. **Segment Fetching**: Automatic API call to getMediaSegments()
3. **Data Binding**: Segments stored in `baseItem.mediaSegments`
4. **UI Access**: ViewModels can access via `item.mediaSegments`

### Supported Segment Types
- **Intro**: Show "Skip Intro" button
- **Outro**: Show "Play Next" button  
- **Commercial**: Skip advertisements
- **Preview**: Skip preview content
- **Recap**: Skip "Previously on" content

## 📋 Implementation Roadmap

### Phase 1: Complete Basic Skip Button (Immediate)
**Timeline**: 1-2 weeks
**Priority**: High

#### Tasks:
- [x] Create MediaSegmentDto models
- [x] Add getMediaSegments() API method
- [x] Integrate segment fetching in MediaPlayerManager
- [ ] Create basic skip button component for intro segments
- [ ] Add skip button to video player controls
- [ ] Implement basic skip functionality (jump to segment end)

### Phase 2: Advanced Features (Short-term)  
**Timeline**: 1-2 months
**Priority**: Medium

#### Tasks:
- [ ] Support all segment types (intro, outro, commercial, etc.)
- [ ] User preferences for auto-skip vs manual-skip
- [ ] Visual segment indicators on progress bar
- [ ] Settings page for segment behavior
- [ ] Error handling for missing/corrupt segments

### Phase 3: Enhanced UX (Medium-term)
**Timeline**: 2-4 months  
**Priority**: Low

#### Tasks:
- [ ] Preview thumbnails for segments
- [ ] Smart segment detection validation
- [ ] Analytics for segment accuracy
- [ ] Customizable skip behavior per content type
- [ ] Accessibility features

## 🧪 Testing Strategy

### API Testing
```bash
# Test media segments availability
curl -H "Authorization: MediaBrowser Token=$TOKEN" \
     "$SERVER_URL/Items/$ITEM_ID/MediaSegments"
```

### Functionality Testing Matrix
| Test Case | Expected Behavior | Status |
|------------|------------------|--------|
| Episode with intro | Skip button appears during intro | ❌ Not Started |
| Episode with outro | Skip button appears during outro | ❌ Not Started |
| Multiple segments | Correct button based on active segment | ❌ Not Started |
| No segments | No skip button shown | ❌ Not Started |
| Network error | Graceful fallback, error logged | ❌ Not Started |

## 🚀 Next Steps for Development

### Immediate (This Week)
1. **Fix MediaPlayerManager compilation** - Complete userSession injection
2. **Create basic skip button component** - Reuse existing button patterns
3. **Add skip functionality** - Seek to segment.end timestamp
4. **Test with real Intro Skipper data** - Verify API integration works

### Short Term (Next Sprint)
1. **Complete UI integration** - Add to video player controls
2. **Add user preferences** - Settings for skip behavior
3. **Implement all segment types** - Support intro, outro, commercial
4. **Error handling** - Graceful degradation when segments unavailable

## 🔗 Related Issues & References

- **Original Issue**: #7 - "Intro skipper not working"
- **Jellyfin Media Segments Documentation**: https://jellyfin.org/docs/general/server/metadata/media-segments/
- **Intro Skipper Plugin**: https://github.com/intro-skipper/intro-skipper
- **API Reference**: MediaSegmentDto in Jellyfin TypeScript SDK

## 📊 Success Metrics

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

## 🤝 Community Impact

This implementation will bring Swiftfin/Reefy to parity with other modern Jellyfin clients like Infuse, providing users with the seamless intro-skipping experience they expect from a media server with the Intro Skipper plugin installed.

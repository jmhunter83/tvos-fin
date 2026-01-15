# Intro Skipper Implementation - Testing & Validation Plan

## 🧪 Phase 1: Code Validation (Immediate)

### Compilation Check
**File**: `Shared/Objects/MediaPlayerManager/MediaPlayerManager.swift`

**Expected**: 
```swift
@Injected(\.currentUserSession) private var userSession: UserSession!
```

**Status**: ✅ PASS - Injection correctly added at line 50

**Verification Commands**:
```bash
# Check for Swift compilation errors
swift build -scheme "Swiftfin tvOS" -destination "platform=tvOS"

# Check for type safety violations
swiftlint lint --strict

# Verify MediaSegmentDto is accessible
swift -typecheck Shared/Extensions/JellyfinAPI/MediaSegmentDto.swift
```

### API Integration Test
**Endpoint**: `/Items/{itemId}/MediaSegments`

**Manual API Test**:
```bash
# Requires: Jellyfin server with Intro Skipper plugin installed
# Test with known item ID that has intro segments

curl -X GET \
  -H "X-Emby-Authorization: MediaBrowser Token=YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  "$SERVER_URL/Items/$ITEM_ID/MediaSegments" \
  | jq '.'
```

**Expected Response**:
```json
{
  "Items": [
    {
      "Start": 0,
      "End": 90,
      "Type": "Intro"
    }
  ],
  "TotalRecordCount": 1
}
```

**Test Cases**:
- [ ] Item with intro segments → Returns valid array
- [ ] Item without segments → Returns empty array or null
- [ ] Invalid item ID → Returns 404 error
- [ ] Unauthorized token → Returns 401 error

---

## 🎮 Phase 2: Functional Testing (After Compilation Pass)

### Unit Tests - Media Segment Detection
**Test Class**: `BaseItemDto` Extensions

```swift
// Test: isInIntroSegment(at:) accuracy
let testItem = BaseItemDto()
testItem.mediaSegments = [
    MediaSegmentDto(start: 0, end: 90, type: .intro),
    MediaSegmentDto(start: 120, end: 150, type: .intro)
]

// Assertions
XCTAssertTrue(testItem.isInIntroSegment(at: 45))  // In intro
XCTAssertTrue(testItem.isInIntroSegment(at: 80))  // In intro
XCTAssertFalse(testItem.isInIntroSegment(at: 10)) // Before intro
XCTAssertFalse(testItem.isInIntroSegment(at: 100)) // After intro
XCTAssertFalse(testItem.isInIntroSegment(at: 140)) // Between intros
```

**Test Class**: `activeSegment(at:)` Logic
```swift
// Test: Correct segment identification
XCTAssertNotNil(testItem.activeSegment(at: 45))  // In first intro
XCTAssertNotNil(testItem.activeSegment(at: 80))  // Still in first intro
XCTAssertNil(testItem.activeSegment(at: 100))  // Between segments
XCTAssertNotNil(testItem.activeSegment(at: 130)) // In second intro
```

### Integration Tests - MediaPlayerManager
**Test Scenario**: Segment Fetching on Item Load

```swift
// Arrange
let mockUserSession = MockUserSession()
let testItem = BaseItemDto(id: "test-id", name: "Test Episode")
mockUserSession.client.setMockResponse(
    itemId: "test-id",
    response: MediaSegmentDtoQueryResult(
        items: [MediaSegmentDto(start: 0, end: 90, type: .intro)]
    )
)

// Act
let manager = MediaPlayerManager()
manager.send(.playNewItem(provider: testProvider))

// Assert
XCTAssertEqual(testItem.mediaSegments?.count, 1) // Segments loaded
XCTAssertNotNil(logger.lastLogEntry(message: "Loaded media segments")) // Logged
```

### UI Tests - SkipIntro Button
**Test Scenarios**:

1. **Button Visibility**
   - [ ] Button shows when `activeSegment` is intro
   - [ ] Button hides when `activeSegment` is nil
   - [ ] Button disables when `activeSegment` is outro

2. **Skip Functionality**
   - [ ] Tapping button seeks to `segment.end`
   - [ ] Playback continues smoothly after skip
   - [ ] No audio/video glitches on seek

3. **Edge Cases**
   - [ ] Overlapping segments handled correctly
   - [ ] Multiple intro segments in one episode
   - [ ] Zero-length segments don't cause issues
   - [ ] Very short intros (<15s) work correctly

---

## 📱 Phase 3: Device Testing (Apple TV)

### Real Server Test Setup
**Requirements**:
- Jellyfin server 10.10+ with Intro Skipper plugin installed
- Test content with confirmed intro segments
- Apple TV device running Swiftfin tvOS build

### Test Content Preparation
**Create test library**:
```
Test Library Structure/
├── Show with Intros/
│   ├── Episode 1 (Intro: 0:00-1:30)
│   ├── Episode 2 (Intro: 0:00-0:45)
│   └── Episode 3 (Intro: 0:00-2:00)
├── Show without Intros/
│   ├── Episode 1 (No segments)
│   └── Episode 2 (No segments)
└── Show with Edge Cases/
    ├── Very Short Intro (0:00-0:15)
    ├── Very Long Intro (0:00-2:30)
    └── Multiple Intros (0:00-0:30, 0:08-0:25, 0:16-0:20)
```

### Manual Test Procedure
1. **API Connectivity Test**
   ```
   Step 1: Play episode with confirmed intro
   Step 2: Check logs for "Loaded media segments" message
   Step 3: Verify segment count matches expected
   Step 4: Confirm no error messages
   ```

2. **Skip Button Appearance Test**
   ```
   Step 1: Seek to 0:45 (middle of intro)
   Step 2: Verify skip button appears
   Step 3: Check button is enabled (not disabled)
   Step 4: Seek to 1:30 (after intro)
   Step 5: Verify button disappears
   ```

3. **Skip Functionality Test**
   ```
   Step 1: Play from start, enter intro at 0:00
   Step 2: Let intro play to 0:30
   Step 3: Tap skip button
   Step 4: Verify playback jumps to 1:30
   Step 5: Confirm audio/video continues smoothly
   Step 6: Check no jump/glitches
   ```

4. **Comparison Test with Infuse**
   ```
   Step 1: Play same episode in Infuse
   Step 2: Record skip button behavior
   Step 3: Play same episode in Swiftfin
   Step 4: Compare skip timing and behavior
   Step 5: Document any differences
   ```

---

## 🐛 Phase 4: Error Handling Validation

### Network Failure Scenarios
**Test Cases**:
- [ ] Server unreachable → Graceful error, log shown, button doesn't crash
- [ ] Timeout (30s) → App remains responsive, retry attempted
- [ ] Corrupt JSON response → Error logged, graceful fallback
- [ ] 404 Not Found → Button doesn't appear, no crash

### Missing Plugin Scenarios
**Test Cases**:
- [ ] Intro Skipper not installed → No segments returned, app works normally
- [ ] Outdated Jellyfin (<10.10) → 404 error, graceful fallback
- [ ] Server version 10.10 without plugin → Empty segments, app works normally

### Edge Case Testing
**Test Cases**:
- [ ] Item ID is nil → No API call, button doesn't crash
- [ ] Empty segments array → Button doesn't appear, no warnings
- [ ] Invalid segment data (start > end) → Error logged, corrupt segment ignored
- [ ] Negative timestamps → Error logged, segment ignored

---

## 📊 Phase 5: Performance Testing

### API Performance
**Metrics to Track**:
- API call duration (target: <500ms for cached data)
- Memory impact of segment storage
- Playback smoothness during segment loading

**Acceptance Criteria**:
- API call completes within 1 second
- No visible lag before skip button appears
- Memory increase <5MB per item

### Playback Performance
**Metrics to Track**:
- Seek accuracy (±0.5s tolerance)
- Buffer recovery time after skip
- Audio/video sync after skip

**Acceptance Criteria**:
- Skip accuracy within ±0.5 seconds
- Buffer recovery <1 second
- No audio/video desync

---

## ✅ Success Criteria - Minimum Viable Product

### Must Have (Blockers)
- [x] Code compiles without errors
- [ ] API successfully fetches media segments
- [ ] Skip button appears during intro segments
- [ ] Skip button works (seeks to end)
- [ ] Error handling doesn't crash app
- [ ] Tested with real Intro Skipper data

### Should Have (Enhancers)
- [ ] Button appears at correct time (segment start)
- [ ] Button disappears at correct time (segment end)
- [ ] Smooth playback after skip
- [ ] Works with multiple intro segments
- [ ] Graceful degradation when segments unavailable

### Nice to Have (Future)
- [ ] Visual indicator on progress bar
- [ ] Auto-skip preference setting
- [ ] Support for outros, commercials
- [ ] Skip confirmation dialog
- [ ] Analytics for skip accuracy

---

## 📝 Test Documentation Template

### Test Run Log
```
Date: January 14, 2026
Tester: [Name]
Build: [Commit hash or version]
Environment: [Jellyfin version, Plugin version]

Test Cases:
----------
1. API Fetching Test
   Status: PASS/FAIL
   Notes: [Details]
   Evidence: [Screenshot or log snippet]

2. Skip Button Visibility Test
   Status: PASS/FAIL
   Notes: [Details]
   Evidence: [Screenshot]

3. Skip Functionality Test
   Status: PASS/FAIL
   Notes: [Details]
   Evidence: [Video or timing]

[Continue for each test case...]

Bugs Found:
----------
[Detailed list of any bugs discovered]

Action Items:
----------
[1] [Description] - [Priority] - [Status]
[2] [Description] - [Priority] - [Status]
[etc...]
```

---

## 🎯 Next Actions After Testing

### If All Tests Pass:
1. Deploy to staging environment
2. Gather beta tester feedback
3. Fix any reported issues
4. Update documentation with real-world findings
5. Create PR with test results

### If Tests Fail:
1. Identify root cause (API vs UI vs Logic)
2. Create fix branch
3. Apply targeted fix
4. Re-run failed test
5. Document regression prevention

---

**Status**: Ready for comprehensive testing and validation phase.

# Saferadar Navigation & Socket Management Guide

## Uber-Style Location Tracking System

Saferadar implements an Uber-like system where seekers and givers can see each other's live locations during active help requests. This requires seamless navigation between screens while maintaining real-time communication.

## Navigation Architecture

### Screen Hierarchy
```
Main App (Bottom Navigation)
├── Home Screen (Seeker/Giver View) 
│   ├── Emergency Button (Creates Help Request)
│   └── Active Help Status
├── Map Screen (Real-time Location Tracking)
│   ├── Live Seeker & Giver Markers
│   ├── Route Visualization 
│   └── Distance/ETA Display
├── Notifications
├── History
└── Settings
```

### State Management During Navigation

#### Active Help Request State
- Preserved across all screen navigations
- Socket room membership maintained
- Location sharing continues regardless of active screen

#### Socket Connection Management
- Single persistent connection per user session
- Room-based communication (one room per help request)
- Automatic reconnection with room rejoining

## Navigation & Socket Lifecycle

### 1. Initial Help Request Creation
```dart
// Flow: Home → Create Request → Join Room → Location Sharing
1. User taps emergency button
2. HTTP request creates help request in backend
3. Socket joins room: `helpRequest:{requestId}`
4. Location sharing starts automatically
5. Givers receive notifications
```

### 2. Navigation to Map Screen
```dart
// During active help request
1. Navigate from Home to Map screen
2. Socket connection continues in background
3. Location updates continue
4. Map displays seeker and giver locations
5. Room membership unchanged
```

### 3. Returning from Map Screen
```dart
// Critical moment - socket state verification
1. App returns from Map to Home
2. Socket state may have changed (background processing)
3. Room membership may need revalidation
4. Location sharing should continue seamlessly
```

## Fix for Navigation Issues

### Problem: Socket Disconnected After Map Navigation
When returning from the map, the app may show "socket connected" but location sharing doesn't work because:
- Socket instance is connected but not the right one
- Room membership lost during navigation
- Cached socket reference is stale

### Solution: Comprehensive Refresh Method
```dart
// Call this when returning from map navigation
await locationController.refreshAfterMapReturn();
```

### Implementation Details

#### 1. Socket Cache Management
```dart
// In SeakerLocationsController
SocketService? getActiveSocket() {
  // Checks if cached socket is still valid and connected
  // If not, finds fresh socket instance from controllers
}
```

#### 2. Room Rejoining Logic
```dart
Future<void> rejoinRoomIfNeeded() async {
  // Verifies current room membership
  // Joins correct room if needed
  // Waits for room join to complete
}
```

#### 3. Navigation Event Handling
```dart
// In Map Screen - when popping back
@override
void dispose() {
  // Ensure location sharing state is preserved
  super.dispose();
}

// After navigation returns
Future<void> onMapReturn() async {
  await Get.find<SeakerLocationsController>().refreshAfterMapReturn();
}
```

## Uber-Style Location Sharing Implementation

### Real-time Position Updates
```dart
// Similar to Uber's driver-rider tracking
- Seeker position updates every 5 seconds OR 10m moved
- Giver position updates every 5 seconds OR 10m moved  
- Both positions visible to each other in real-time
- Distance and ETA calculated dynamically
```

### Map Visualization
- **Seeker Marker**: Red, shows current location
- **Giver Marker**: Green, shows current location  
- **Route Line**: Blue line connecting both parties
- **Distance Display**: Real-time distance between them
- **ETA Display**: Estimated time for giver to reach seeker

## Navigation Best Practices

### 1. Always Refresh After Map Return
```dart
// Example in a StatefulWidget's after navigation
class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  @override
  void dispose() {
    // Critical: Refresh socket state when leaving map
    _refreshSocketOnReturn();
    super.dispose();
  }
  
  Future<void> _refreshSocketOnReturn() async {
    final locationController = Get.find<SeakerLocationsController>();
    await locationController.refreshAfterMapReturn();
  }
}
```

### 2. Preserve Active State
```dart
// During navigation, preserve help request ID
class LocationController extends GetxController {
  String currentHelpRequestId = '';
  
  // This should persist across screen navigations
  // Only cleared when help request ends
}
```

### 3. Handle Connectivity Events
```dart
// Monitor socket state during navigation
Timer.periodic(Duration(seconds: 5), (timer) {
  if (isSharingLocation.value) {
    // Verify socket is still connected and in correct room
    _verifySocketConnection();
  }
});
```

## Common Navigation Scenarios

### Scenario 1: Normal Map Navigation
```
Home → Map → Home (Works fine - socket maintained)
```

### Scenario 2: Background App Navigation  
```
Home → Map → Background → Resume → Home 
(Requires socket refresh to restore connection)
```

### Scenario 3: App Killed During Navigation
```
Home → Map → App Killed → Restart
(Requires full connection and room rejoin)
```

## Error Recovery

### When Socket Is Disconnected After Navigation
```dart
// Detect and recover
if (!isSocketConnected.value && isSharingLocation.value) {
  // Force full refresh
  await refreshSocketAndRejoinRoom();
  
  // Re-share current location
  shareCurrentLocation();
}
```

### When Room Membership Is Lost
```dart
// Verify and rejoin room
if (socketService.currentRoom != currentHelpRequestId.value) {
  await joinRoom(currentHelpRequestId.value);
}
```

## Uber-Style Features Implemented

### 1. Real-time Tracking
- Both parties see each other's location live
- Position updates every few seconds
- Smooth marker transitions on map

### 2. Distance & ETA Calculation
- Real-time distance between seeker and giver
- Estimated time of arrival
- Route progress tracking

### 3. Navigation Integration
- Seamless navigation between screens
- Location sharing continues during navigation
- State preserved across screen transitions

### 4. Connection Resilience
- Auto-reconnection when connection lost
- Room rejoining after reconnection
- Navigation-aware socket management

## Testing Checklist

### Before Deployment
- [ ] Socket maintains connection during navigation
- [ ] Location sharing continues after map return  
- [ ] Room membership preserved during navigation
- [ ] Markers update correctly on both ends
- [ ] Distance/ETA calculates properly
- [ ] Error recovery works when connection lost

### Common Test Cases
1. Navigate to map and back multiple times
2. Put app in background during active request
3. Test with poor network connection
4. Test when app is killed in background
5. Verify location sharing resumes after network issues

## Key Methods for Navigation Management

| Method | Purpose | When to Call |
|--------|---------|--------------|
| `refreshAfterMapReturn()` | Complete socket refresh after map navigation | After returning from map screen |
| `refreshSocketAndRejoinRoom()` | Refresh connection and room membership | Periodic refresh during active help |
| `forceLocationSharingStart()` | Force start location sharing | When sharing stops unexpectedly |
| `rejoinRoomIfNeeded()` | Verify room membership | When connection issues detected |

This Uber-style system ensures that users can navigate between screens while maintaining real-time location sharing, similar to how driver and rider locations are shared during an Uber ride.
# Saferadar Socket & Navigation Complete Guide

## Uber-Style Real-Time Communication Architecture

Saferadar implements an Uber-like system where users can see each other's live location during active help requests. This document explains the socket communication patterns, navigation flows, and how to maintain seamless real-time functionality.

## Socket.IO Event Architecture

### Core Event Flow
```
Frontend (Flutter) ↔ Socket.IO Server ↔ Backend API
         ↓                  ↓               ↓
   Real-time Events    Broadcast/Room   Database Storage
```

### Socket Event Types

#### Seeker Events
| Event (Client → Server) | Description | When Triggered |
|------------------------|-------------|----------------|
| `joinRoom` | Join help request room | When request accepted |
| `sendLocationUpdate` | Send location | Every 5s or 10m moved |
| `cancelHelpRequest` | Cancel request | User cancels request |
| `completeHelpRequest` | Complete request | Help completed |

| Event (Server → Client) | Description | When Received |
|-------------------------|-------------|---------------|
| `helpRequestAccepted` | Request accepted | Giver accepts |
| `receiveLocationUpdate` | Giver location | Giver moves |
| `helpRequestCancelled` | Request cancelled | By either party |
| `helpRequestCompleted` | Request completed | Help finished |

#### Giver Events
| Event (Client → Server) | Description | When Triggered |
|------------------------|-------------|----------------|
| `giver_newHelpRequest` | New request | Nearby request created |
| `acceptHelpRequest` | Accept request | User accepts |
| `declineHelpRequest` | Decline request | User declines |
| `giver_receiveLocationUpdate` | Send location | Every 5s or 10m moved |
| `leaveHelpRequestRoom` | Leave room | Request ends |

| Event (Server → Client) | Description | When Received |
|-------------------------|-------------|---------------|
| `giver_receiveLocationUpdate` | Seeker location | Seeker moves |
| `giver_helpRequestCancelled` | Request cancelled | By either party |
| `giver_helpRequestCompleted` | Request completed | Help finished |

## Navigation Patterns & Socket Management

### 1. App Lifecycle with Socket Connections

#### App Startup
```
1. App launches → Get token from storage
2. Initialize Socket.IO with authentication
3. Connect to server with JWT token
4. Register all event listeners
5. Load user role (seeker/giver/both)
6. Ready for navigation and communication
```

#### Active Help Request State
```
Connected Socket → Joined Room → Active Location Sharing
       ↓              ↓               ↓
   Events OK      Communication   Live Tracking
```

### 2. Navigation-Related Socket Issues

#### Problem: Socket Stale After Navigation
When navigating between screens (especially maps), the socket connection may become stale or disconnected while still showing as connected.

#### Root Causes:
1. **App Backgrounding**: Android/iOS may throttle network when app goes to background
2. **Cached References**: Old socket service instances may be cached
3. **Room Membership Loss**: Socket disconnects and loses room membership
4. **Connection Timing**: Race conditions between navigation and socket events

### 3. Uber-Style Navigation Flow

#### Seeker Journey
```
Home (Emergency Button) → HTTP Create Request → Wait for Acceptance
         ↓
Giver Accepts → Join Private Room → Start Location Sharing
         ↓
Navigate Map ↔ Share Live Locations ↔ Help Completion
         ↓
Leave Room → Stop Sharing → Return to Home
```

#### Giver Journey  
```
Home (Helper Status ON) → Monitor for Requests → Receive Notifications
         ↓
Accept Request → Join Private Room → Start Location Sharing  
         ↓
Navigate Map ↔ Share Live Locations ↔ Help Completion
         ↓
Leave Room → Stop Sharing → Return to Home
```

## Navigation Event Handling

### 1. Route Navigation Events

#### Using GetX Navigation Events
```dart
class MapScreen extends GetView {
  @override
  Widget build(BuildContext context) {
    return GetBuilder<MapController>(
      init: MapController(),
      builder: (controller) {
        // Handle navigation events
        return Scaffold(
          // ... your UI
        );
      },
      // Lifecycle callbacks
      onInit: () => controller.onMapOpen(),
      onClose: () => controller.onMapClose(),
    );
  }
}
```

#### Map Screen Lifecycle
```dart
class MapController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    // Initialize map and socket monitoring
    startSocketMonitoring();
  }

  @override
  void onClose() {
    // Critical: Clean up and refresh socket for return
    refreshSocketOnReturn();
    super.onClose();
  }

  Future<void> onMapOpen() async {
    // Ensure location sharing continues
    final locationController = Get.find<SeakerLocationsController>();
    locationController.startLocationSharing();
  }

  Future<void> onMapClose() async {
    // Prepare for return to main screen
    final locationController = Get.find<SeakerLocationsController>();
    await locationController.refreshAfterMapReturn();
  }
}
```

### 2. Navigation State Preservation

#### Preserving Help Request State
```dart
class NavigationStateService extends GetxService {
  RxString currentHelpRequestId = ''.obs;
  RxBool isHelpActive = false.obs;
  RxBool isLocationSharing = false.obs;

  // Called when help request starts
  void setHelpRequestActive(String requestId) {
    currentHelpRequestId.value = requestId;
    isHelpActive.value = true;
    isLocationSharing.value = true;
  }

  // Called when help request ends
  void setHelpRequestInactive() {
    currentHelpRequestId.value = '';
    isHelpActive.value = false;
    isLocationSharing.value = false;
  }

  // Called when returning from map
  Future<void> onNavigationReturn() async {
    if (isHelpActive.value && currentHelpRequestId.value.isNotEmpty) {
      // Refresh socket for active help request
      final locationController = Get.find<SeakerLocationsController>();
      await locationController.refreshAfterMapReturn();
    }
  }
}
```

### 3. Socket Connection Monitoring During Navigation

#### Continuous Monitoring Service
```dart
class SocketMonitorService extends GetxService {
  Timer? _monitorTimer;

  @override
  void onInit() {
    super.onInit();
    startMonitoring();
  }

  void startMonitoring() {
    _monitorTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      checkSocketHealth();
    });
  }

  void checkSocketHealth() {
    final locationController = Get.find<SeakerLocationsController>();
    final socketService = locationController.getActiveSocket();
    
    if (socketService != null) {
      if (!socketService.isConnected.value) {
        // Attempt reconnection
        reconnectAndRejoin();
      } else if (locationController.isSharingLocation.value) {
        // Verify room membership
        verifyRoomMembership(socketService, locationController);
      }
    }
  }

  Future<void> verifyRoomMembership(SocketService socket, SeakerLocationsController locationController) async {
    final expectedRoom = locationController.currentHelpRequestId.value;
    
    if (expectedRoom.isNotEmpty && socket.currentRoom != expectedRoom) {
      // Rejoin the correct room
      await socket.joinRoom(expectedRoom);
    }
  }

  @override
  void onClose() {
    _monitorTimer?.cancel();
    super.onClose();
  }
}
```

## Uber-Style Real-Time Features

### 1. Live Location Tracking (Like Uber)

#### Position Updates
```dart
// Similar to Uber's driver/rider tracking
class LocationSharingService {
  // Distance threshold (like Uber's accuracy)
  static const double DISTANCE_THRESHOLD = 10.0; // meters
  
  // Time threshold (like Uber's update frequency) 
  static const int TIME_THRESHOLD = 5000; // milliseconds
  
  // Location accuracy threshold
  static const double ACCURACY_THRESHOLD = 50.0; // meters
  
  bool shouldSendUpdate(Position newPosition, Position? lastPosition) {
    if (lastPosition == null) return true;
    
    double distance = Geolocator.distanceBetween(
      lastPosition.latitude, lastPosition.longitude,
      newPosition.latitude, newPosition.longitude,
    );
    
    return distance >= DISTANCE_THRESHOLD;
  }
  
  void onLocationUpdate(Position position) {
    if (shouldSendUpdate(position, _lastSentPosition)) {
      sendLocationUpdate(position);
      _lastSentPosition = position;
    }
  }
}
```

#### Map Visualization
```dart
// Uber-style smooth marker transitions
class MapVisualizationService {
  // Animate marker movement (like Uber's smooth transitions)
  void updateMarkerSmoothly(MarkerId markerId, LatLng newPosition) {
    // Use animation for smooth transitions
    animateToPosition(markerId, newPosition, duration: Duration(milliseconds: 500));
  }
  
  // Draw route between seeker and giver (like Uber's route display)
  void drawRouteBetween(LatLng seekerPos, LatLng giverPos) {
    // Calculate and display route polyline
    final route = calculateRoute(seekerPos, giverPos);
    updateRoutePolyline(route);
  }
  
  // Calculate distance and ETA (like Uber's calculation)
  void calculateDistanceAndETA(LatLng seekerPos, LatLng giverPos) {
    final distance = Geolocator.distanceBetween(
      seekerPos.latitude, seekerPos.longitude,
      giverPos.latitude, giverPos.longitude,
    );
    
    // Simple ETA calculation (Uber uses more complex algorithms)
    final eta = (distance / AVERAGE_SPEED_MPS).round();
  }
}
```

### 2. Connection Resilience (Like Uber's Robustness)

#### Auto-Reconnection
```dart
class ConnectionResilienceService {
  static const int MAX_RECONNECTION_ATTEMPTS = 5;
  static const Duration RECONNECTION_DELAY = Duration(seconds: 3);
  
  int _reconnectionAttempts = 0;
  
  Future<void> handleDisconnection() async {
    if (_reconnectionAttempts >= MAX_RECONNECTION_ATTEMPTS) {
      showConnectionError();
      return;
    }
    
    _reconnectionAttempts++;
    await Future.delayed(RECONNECTION_DELAY);
    
    final success = await attemptReconnection();
    if (!success) {
      await handleDisconnection(); // Recursive retry
    } else {
      _reconnectionAttempts = 0;
      await rejoinRooms();
    }
  }
  
  Future<bool> attemptReconnection() async {
    try {
      final token = await TokenService().getToken();
      final role = Get.find<UserController>().userRole.value;
      
      final socketService = await Get.find<SocketService>().init(token, role: role);
      return socketService.isConnected.value;
    } catch (e) {
      return false;
    }
  }
}
```

## Navigation Testing Scenarios

### 1. Normal Navigation Flow
```
✅ Home → Map → Home: Socket reconnects, location sharing continues
✅ Home → Settings → Home: Socket maintains, no interruption
✅ Background → Resume: Socket reconnects automatically
```

### 2. Edge Cases
```
⚠️ App killed during active request: Full reconnection required
⚠️ Network loss during navigation: Auto-reconnection with room rejoin
⚠️ Multiple rapid navigations: Socket caching prevents multiple connections
```

### 3. Uber-Style Behavior Verification
```
✅ Both parties see each other's live locations
✅ Distance updates in real-time
✅ ETA calculation works during navigation
✅ Markers move smoothly during navigation
✅ Connection maintains during app backgrounding
```

## Implementation Checklist

### For Map Screen Implementation
- [ ] Call `refreshAfterMapReturn()` when exiting map
- [ ] Preserve help request state during navigation
- [ ] Verify socket connection on screen return
- [ ] Rejoin room if needed after navigation
- [ ] Continue location sharing after navigation

### For Socket Management
- [ ] Implement socket health monitoring
- [ ] Add room membership verification
- [ ] Create auto-reconnection logic
- [ ] Add error handling for disconnections
- [ ] Test background app scenarios

### For Navigation Flow
- [ ] Preserve active help request state
- [ ] Maintain location sharing across screens
- [ ] Handle navigation lifecycle events properly
- [ ] Test all navigation paths with active requests
- [ ] Verify Uber-style smooth operation

## Troubleshooting Guide

### Common Issues & Solutions

#### Issue: Socket Connected But Not Sending Updates
**Symptoms**: Console shows connected but location not updating
**Solution**: Call `refreshAfterMapReturn()` to clear cached socket and rejoin room

#### Issue: Location Sharing Stops After Navigation
**Symptoms**: Markers freeze, no updates received
**Solution**: Verify room membership and restart location sharing

#### Issue: Multiple Socket Connections  
**Symptoms**: Duplicate event handlers, memory leaks
**Solution**: Proper cleanup in `dispose()` and `onClose()` methods

#### Issue: Room Not Rejoined After Connection
**Symptoms**: Can send updates but not received by other party
**Solution**: Implement room rejoining in connection handler

This complete guide shows how Saferadar implements Uber-style navigation with real-time location sharing, ensuring seamless operation during screen transitions while maintaining the critical safety communication features.
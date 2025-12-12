# Complete Socket.IO Implementation Guide for Mobile Team

## 📋 Table of Contents

1. [Overview](#overview)
2. [Connection Setup](#connection-setup)
3. [Socket Events Reference](#socket-events-reference)
4. [Implementation Steps](#implementation-steps)
5. [Room Management](#room-management)
6. [Location Updates](#location-updates)
7. [Error Handling](#error-handling)
8. [Best Practices](#best-practices)
9. [Common Pitfalls & Solutions](#common-pitfalls--solutions)
10. [Testing Checklist](#testing-checklist)

---

## Overview

This guide provides **complete, step-by-step instructions** for implementing Socket.IO in the mobile app. The backend uses Socket.IO for real-time communication between Seekers and Givers.

### Key Concepts

- **Seeker**: User who needs help (creates help request)
- **Giver**: User who provides help (accepts help request)
- **Room**: Socket.IO room for a specific help request (format: `helpRequest:{id}`)
- **Events**: Messages sent between client and server

### Architecture Flow

```
Seeker App                    Server                    Giver App
    │                            │                          │
    ├─ Create Request (HTTP) ───┤                          │
    │                            ├─ Broadcast ──────────────┤
    │                            │  (giver_newHelpRequest)  │
    │                            │                          │
    │                            │←─ Accept (Socket) ───────┤
    │←─ Accepted (Socket) ───────┤                          │
    │                            │                          │
    ├─ Join Room ────────────────┤←─ Join Room ────────────┤
    │                            │                          │
    ├─ Send Location ────────────┤                          │
    │                            ├─ Broadcast ──────────────┤
    │                            │  (receiveLocationUpdate) │
    │                            │                          │
```

---

## Connection Setup

### Step 1: Install Socket.IO Client

**Flutter:**
```yaml
dependencies:
  socket_io_client: ^2.0.3+1
```

**React Native:**
```bash
npm install socket.io-client
```

### Step 2: Initialize Socket Connection

**⚠️ CRITICAL:** You MUST provide a valid JWT access token from the login API.

**Flutter Example:**
```dart
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  IO.Socket? socket;
  RxBool isConnected = false.obs;
  
  Future<void> init(String token, {String? role}) async {
    // Get server URL from config
    final serverUrl = 'http://localhost:5000'; // or your server URL
    
    socket = IO.io(serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'auth': {
        'token': token  // ⚠️ REQUIRED: JWT access token
      },
      'reconnection': true,
      'reconnectionDelay': 1000,
      'reconnectionAttempts': 5,
    });
    
    _setupConnectionHandlers();
    socket!.connect();
  }
  
  void _setupConnectionHandlers() {
    socket!.onConnect((_) {
      isConnected.value = true;
      print('✅ Connected to Socket.IO server');
    });
    
    socket!.onDisconnect((_) {
      isConnected.value = false;
      print('❌ Disconnected from server');
    });
    
    socket!.onConnectError((error) {
      print('❌ Connection error: $error');
      // Handle authentication errors
      if (error.toString().contains('Authentication')) {
        // Token might be expired, refresh it
      }
    });
  }
}
```

**React Native Example:**
```javascript
import io from 'socket.io-client';

class SocketService {
  constructor(token) {
    this.socket = io('http://localhost:5000', {
      auth: {
        token: token  // ⚠️ REQUIRED: JWT access token
      },
      transports: ['websocket'],
      reconnection: true,
      reconnectionDelay: 1000,
      reconnectionAttempts: 5
    });
    
    this.setupHandlers();
  }
  
  setupHandlers() {
    this.socket.on('connect', () => {
      console.log('✅ Connected to Socket.IO server');
    });
    
    this.socket.on('disconnect', (reason) => {
      console.log('❌ Disconnected:', reason);
    });
    
    this.socket.on('connect_error', (error) => {
      console.error('Connection error:', error);
    });
  }
}
```

### Step 3: Connection Lifecycle

**When to Connect:**
- ✅ After user successfully logs in
- ✅ After token refresh
- ✅ When app comes to foreground (if disconnected)

**When to Disconnect:**
- ✅ When user logs out
- ✅ When app goes to background (optional, depends on requirements)

**Token Refresh:**
- Access tokens expire (default: 15 minutes)
- Implement token refresh logic
- Reconnect with new token when current one expires

---

## Socket Events Reference

### Client → Server Events (You Emit)

| Event Name | Payload | When to Use | Who Sends |
|------------|---------|-------------|-----------|
| `acceptHelpRequest` | `helpRequestId` (String) | When giver accepts a help request | **Giver only** |
| `declineHelpRequest` | `helpRequestId` (String) | When giver declines a help request | **Giver only** |
| `sendLocationUpdate` | `{ latitude, longitude }` | To share live location | **Both Seeker & Giver** |

### Server → Client Events (You Listen)

| Event Name | Payload | Who Receives | Description |
|------------|---------|--------------|-------------|
| `giver_newHelpRequest` | HelpRequest object | **Giver** | New help request created nearby |
| `helpRequestAccepted` | `{ helpRequest, giverLocation }` | **Seeker** | Their request was accepted |
| `giver_helpRequestDeclined` | `{ helpRequestId }` | **Giver** | Confirmation after declining |
| `giver_helpRequestCancelled` | HelpRequest object | **Giver** | Seeker cancelled the request |
| `giver_helpRequestCompleted` | HelpRequest object | **Giver** | Request marked as completed |
| `helpRequestCompleted` | HelpRequest object | **Seeker** | Request marked as completed |
| `receiveLocationUpdate` | `{ userId, latitude, longitude }` | **Seeker** | Giver's location update |
| `giver_receiveLocationUpdate` | `{ userId, latitude, longitude }` | **Giver** | Seeker's location update |
| `message` | String | **Both** | System messages |
| `error` | String | **Both** | Error messages |

---

## Implementation Steps

### Step 1: Setup Event Listeners

**⚠️ IMPORTANT:** Setup listeners **BEFORE** emitting any events.

**Flutter Example:**
```dart
void setupSocketListeners() {
  // For Seekers
  socket!.on('helpRequestAccepted', (data) {
    _handleHelpRequestAccepted(data);
  });
  
  socket!.on('receiveLocationUpdate', (data) {
    _handleLocationUpdate(data);
  });
  
  socket!.on('helpRequestCancelled', (data) {
    _handleRequestCancelled(data);
  });
  
  socket!.on('helpRequestCompleted', (data) {
    _handleRequestCompleted(data);
  });
  
  // For Givers
  socket!.on('giver_newHelpRequest', (data) {
    _handleNewHelpRequest(data);
  });
  
  socket!.on('giver_receiveLocationUpdate', (data) {
    _handleLocationUpdate(data);
  });
  
  socket!.on('giver_helpRequestCancelled', (data) {
    _handleRequestCancelled(data);
  });
  
  socket!.on('giver_helpRequestCompleted', (data) {
    _handleRequestCompleted(data);
  });
  
  // Common events
  socket!.on('message', (data) {
    print('System message: $data');
  });
  
  socket!.on('error', (error) {
    print('Socket error: $error');
    // Show error to user
  });
}
```

### Step 2: Seeker Flow - Create Help Request

**1. Create Request via HTTP API:**
```dart
// POST /api/help-requests
final response = await http.post(
  Uri.parse('$baseUrl/api/help-requests'),
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token'
  },
  body: jsonEncode({
    'latitude': currentLatitude,
    'longitude': currentLongitude,
    'description': 'Need help with...' // Optional
  }),
);

final helpRequest = jsonDecode(response.body);
final helpRequestId = helpRequest['data']['id'];
```

**2. Join Room (CRITICAL!):**
```dart
// ⚠️ MUST join room before sending location updates
socket!.emit('joinRoom', helpRequestId);
// OR if your SocketService has a joinRoom method:
socketService.joinRoom(helpRequestId);

// ⚠️ Wait for room join to complete (add delay or confirmation)
await Future.delayed(Duration(milliseconds: 500));
```

**3. Wait for Acceptance:**
```dart
void _handleHelpRequestAccepted(dynamic data) {
  // data = { helpRequest: {...}, giverLocation: {...} }
  final helpRequest = data['helpRequest'];
  final giverLocation = data['giverLocation'];
  
  // Store help request ID
  currentHelpRequestId = helpRequest['_id'];
  
  // Server automatically joins both sockets to room
  // But you should also call joinRoom() on client side
  
  // Start location sharing
  startLocationSharing();
  
  // Update UI - show giver's info
  updateUI(helpRequest, giverLocation);
}
```

### Step 3: Giver Flow - Accept Help Request

**1. Receive New Help Request:**
```dart
void _handleNewHelpRequest(dynamic data) {
  // data = HelpRequest object with seeker info, distance, ETA
  final helpRequest = data;
  
  // Add to pending requests list
  pendingRequests.add(helpRequest);
  
  // Show notification to user
  showNotification('New help request from ${helpRequest['seeker']['name']}');
}
```

**2. Accept Help Request:**
```dart
void acceptHelpRequest(String helpRequestId) {
  // ⚠️ Emit acceptHelpRequest event
  socket!.emit('acceptHelpRequest', helpRequestId);
  
  // ⚠️ Server automatically joins both sockets to room
  // But you should also call joinRoom() on client side
  socketService.joinRoom(helpRequestId);
  
  // Wait for room join
  await Future.delayed(Duration(milliseconds: 500));
  
  // Start location sharing
  startLocationSharing();
  
  // Update UI
  updateUI();
}
```

**3. Decline Help Request:**
```dart
void declineHelpRequest(String helpRequestId) {
  socket!.emit('declineHelpRequest', helpRequestId);
  
  // You'll receive 'giver_helpRequestDeclined' confirmation
}

void _handleHelpRequestDeclined(dynamic data) {
  // data = { helpRequestId: "..." }
  // Remove from pending requests
  pendingRequests.removeWhere((req) => req['_id'] == data['helpRequestId']);
}
```

---

## Room Management

### ⚠️ CRITICAL: Understanding Rooms

**Room Format:** `helpRequest:{helpRequestId}`

**Why Rooms Matter:**
- Location updates are sent to sockets in the same room
- Server identifies which help request an update belongs to by checking which room the socket is in
- **If socket is NOT in a room, location updates are silently ignored!**

### When to Join Rooms

**Seeker:**
1. ✅ After creating help request (HTTP API)
2. ✅ After receiving `helpRequestAccepted` event

**Giver:**
1. ✅ After accepting help request (emitting `acceptHelpRequest`)
2. ✅ Server automatically joins, but client should also call `joinRoom()`

### Room Join Implementation

**Flutter:**
```dart
void joinRoom(String helpRequestId) {
  // Method 1: If SocketService has joinRoom method
  socketService.joinRoom(helpRequestId);
  
  // Method 2: Direct emit (if server supports it)
  // socket!.emit('joinRoom', helpRequestId);
  
  // ⚠️ IMPORTANT: Wait for room join to complete
  // Server-side join is async, add delay or wait for confirmation
  await Future.delayed(Duration(milliseconds: 500));
}
```

**⚠️ Common Mistake:**
```dart
// ❌ WRONG: Sending location before room is joined
socketService.joinRoom(helpRequestId);
sendLocationUpdate(); // Too early! Room might not be joined yet

// ✅ CORRECT: Wait for room join
socketService.joinRoom(helpRequestId);
await Future.delayed(Duration(milliseconds: 500));
sendLocationUpdate(); // Now safe
```

---

## Location Updates

### ⚠️ CRITICAL: How Location Updates Work

**Key Points:**
1. **Socket MUST be in a room** before sending location updates
2. **Payload does NOT include helpRequestId** - server gets it from room
3. **Server adds userId** before broadcasting to other party

### Sending Location Updates

**Format:**
```dart
// Payload: { latitude, longitude }
// NO helpRequestId in payload!

socket!.emit('sendLocationUpdate', {
  'latitude': position.latitude,  // double
  'longitude': position.longitude  // double
});
```

**Implementation:**
```dart
void sendLocationUpdate(double latitude, double longitude) {
  // ⚠️ Verify socket is in a room first
  if (!isInRoom) {
    print('⚠️ Socket not in room - location update will be ignored');
    return;
  }
  
  // ⚠️ Verify socket is connected
  if (!socket!.connected) {
    print('⚠️ Socket not connected');
    return;
  }
  
  // Send update
  socket!.emit('sendLocationUpdate', {
    'latitude': latitude,
    'longitude': longitude
  });
}
```

### Receiving Location Updates

**Seeker Receives (from Giver):**
```dart
socket!.on('receiveLocationUpdate', (data) {
  // data = { userId, latitude, longitude }
  final userId = data['userId'];
  final latitude = data['latitude'] as double;
  final longitude = data['longitude'] as double;
  
  // Update giver's position on map
  updateGiverPosition(latitude, longitude);
  
  // Recalculate distance/ETA
  calculateDistanceAndETA();
});
```

**Giver Receives (from Seeker):**
```dart
socket!.on('giver_receiveLocationUpdate', (data) {
  // data = { userId, latitude, longitude }
  final userId = data['userId'];
  final latitude = data['latitude'] as double;
  final longitude = data['longitude'] as double;
  
  // Update seeker's position on map
  updateSeekerPosition(latitude, longitude);
  
  // Recalculate distance/ETA
  calculateDistanceAndETA();
});
```

### Location Update Frequency

**Recommended:**
- Send updates when user moves **10+ meters** (distance threshold)
- Send updates **every 5 seconds** (time threshold)
- Don't send if location hasn't changed significantly

**Implementation:**
```dart
Position? lastSentPosition;
final double distanceThreshold = 10.0; // meters
final int timeThreshold = 5000; // milliseconds

void onLocationUpdate(Position newPosition) {
  if (shouldSendUpdate(newPosition)) {
    sendLocationUpdate(newPosition.latitude, newPosition.longitude);
    lastSentPosition = newPosition;
  }
}

bool shouldSendUpdate(Position newPosition) {
  if (lastSentPosition == null) return true;
  
  final distance = calculateDistance(
    lastSentPosition!.latitude,
    lastSentPosition!.longitude,
    newPosition.latitude,
    newPosition.longitude
  );
  
  return distance >= distanceThreshold;
}
```

---

## Error Handling

### Connection Errors

```dart
socket!.onConnectError((error) {
  if (error.toString().contains('Authentication')) {
    // Token expired or invalid
    refreshTokenAndReconnect();
  } else {
    // Network error
    showError('Connection failed. Please check your internet.');
  }
});
```

### Event Errors

```dart
socket!.on('error', (error) {
  // Server sends error messages
  // Examples:
  // - "Help request already accepted."
  // - "Help request not found."
  // - "Failed to decline help request."
  
  showError(error.toString());
  
  // Handle specific errors
  if (error.contains('already accepted')) {
    // Update UI - request already taken
    updateUI();
  }
});
```

### Location Update Errors

**Silent Failures:**
- If socket not in room → Update silently ignored (no error sent)
- Always verify room membership before sending

**Validation:**
```dart
void sendLocationUpdate(double lat, double lng) {
  // Validate coordinates
  if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
    print('❌ Invalid coordinates');
    return;
  }
  
  // Validate socket state
  if (!socket!.connected) {
    print('❌ Socket not connected');
    return;
  }
  
  // Validate room membership
  if (!isInRoom) {
    print('❌ Socket not in room');
    return;
  }
  
  // Send update
  socket!.emit('sendLocationUpdate', {
    'latitude': lat,
    'longitude': lng
  });
}
```

---

## Best Practices

### 1. Connection Management

✅ **DO:**
- Connect after login
- Disconnect on logout
- Handle reconnection automatically
- Refresh token when expired

❌ **DON'T:**
- Connect multiple times
- Leave connections open indefinitely
- Ignore connection errors

### 2. Event Listeners

✅ **DO:**
- Setup listeners immediately after connection
- Remove listeners when disconnecting
- Handle all events, even if not used yet

❌ **DON'T:**
- Setup listeners multiple times (causes duplicates)
- Forget to remove listeners (memory leaks)

### 3. Room Management

✅ **DO:**
- Join room before sending location updates
- Wait for room join confirmation
- Verify room membership before sending

❌ **DON'T:**
- Send location before room is joined
- Assume room join is instant
- Forget to join room

### 4. Location Updates

✅ **DO:**
- Validate coordinates before sending
- Use distance/time thresholds
- Handle connection state

❌ **DON'T:**
- Send updates too frequently
- Send invalid coordinates
- Send when not in room

### 5. Error Handling

✅ **DO:**
- Handle all error events
- Show user-friendly messages
- Log errors for debugging

❌ **DON'T:**
- Ignore error events
- Show technical error messages to users
- Crash on errors

---

## Common Pitfalls & Solutions

### Pitfall 1: Location Updates Not Working

**Symptoms:**
- Location sent but not received
- No errors shown

**Causes:**
1. Socket not in room
2. Socket not connected
3. Wrong event name

**Solution:**
```dart
// ✅ Always verify before sending
void sendLocationUpdate() {
  // Check 1: Socket connected
  if (!socket!.connected) {
    print('❌ Socket not connected');
    return;
  }
  
  // Check 2: In room
  if (!isInRoom) {
    print('❌ Not in room - joining now...');
    joinRoom(helpRequestId);
    await Future.delayed(Duration(milliseconds: 500));
  }
  
  // Check 3: Valid coordinates
  if (!isValidCoordinates(lat, lng)) {
    print('❌ Invalid coordinates');
    return;
  }
  
  // Now safe to send
  socket!.emit('sendLocationUpdate', {
    'latitude': lat,
    'longitude': lng
  });
}
```

### Pitfall 2: Duplicate Event Listeners

**Symptoms:**
- Events fired multiple times
- Memory leaks

**Solution:**
```dart
// ✅ Remove old listeners before adding new ones
void setupListeners() {
  // Remove existing listeners first
  socket!.off('helpRequestAccepted');
  socket!.off('receiveLocationUpdate');
  
  // Add new listeners
  socket!.on('helpRequestAccepted', (data) {
    // Handle event
  });
  
  socket!.on('receiveLocationUpdate', (data) {
    // Handle event
  });
}
```

### Pitfall 3: Room Not Joined

**Symptoms:**
- Location updates ignored
- No errors shown

**Solution:**
```dart
// ✅ Always join room and wait
Future<void> joinRoomAndWait(String helpRequestId) async {
  socketService.joinRoom(helpRequestId);
  
  // Wait for server to process
  await Future.delayed(Duration(milliseconds: 500));
  
  // Verify (if possible)
  // Some Socket.IO clients allow checking room membership
  print('✅ Room joined: $helpRequestId');
}
```

### Pitfall 4: Token Expiration

**Symptoms:**
- Connection lost
- Authentication errors

**Solution:**
```dart
// ✅ Handle token refresh
socket!.onConnectError((error) {
  if (error.toString().contains('Authentication')) {
    // Refresh token
    refreshToken().then((newToken) {
      // Reconnect with new token
      socket!.disconnect();
      init(newToken);
    });
  }
});
```

### Pitfall 5: Wrong Event Names

**Symptoms:**
- Events not received
- Confusion between seeker/giver events

**Solution:**
```dart
// ✅ Use correct event names based on role

// Seeker listens for:
socket!.on('receiveLocationUpdate', ...);  // From giver
socket!.on('helpRequestAccepted', ...);

// Giver listens for:
socket!.on('giver_receiveLocationUpdate', ...);  // From seeker
socket!.on('giver_newHelpRequest', ...);
socket!.on('giver_helpRequestCancelled', ...);
```

---

## Testing Checklist

### Connection
- [ ] Can connect with valid token
- [ ] Connection fails with invalid token
- [ ] Reconnects automatically on network issues
- [ ] Handles token expiration

### Seeker Flow
- [ ] Can create help request (HTTP)
- [ ] Receives `helpRequestAccepted` event
- [ ] Joins room after acceptance
- [ ] Can send location updates
- [ ] Receives `receiveLocationUpdate` events
- [ ] Receives `helpRequestCompleted` event

### Giver Flow
- [ ] Receives `giver_newHelpRequest` events
- [ ] Can accept help request
- [ ] Joins room after acceptance
- [ ] Can send location updates
- [ ] Receives `giver_receiveLocationUpdate` events
- [ ] Can decline help request
- [ ] Receives `giver_helpRequestDeclined` confirmation
- [ ] Receives `giver_helpRequestCancelled` event
- [ ] Receives `giver_helpRequestCompleted` event

### Location Updates
- [ ] Location sent only when in room
- [ ] Location received by other party
- [ ] Coordinates validated
- [ ] Updates sent at appropriate frequency
- [ ] Handles connection loss gracefully

### Error Handling
- [ ] Handles `error` events
- [ ] Shows user-friendly messages
- [ ] Handles connection errors
- [ ] Handles authentication errors

---

## Quick Reference

### Event Names Summary

**Seeker Listens:**
- `helpRequestAccepted`
- `receiveLocationUpdate`
- `helpRequestCancelled`
- `helpRequestCompleted`
- `message`
- `error`

**Giver Listens:**
- `giver_newHelpRequest`
- `giver_receiveLocationUpdate`
- `giver_helpRequestDeclined`
- `giver_helpRequestCancelled`
- `giver_helpRequestCompleted`
- `message`
- `error`

**Both Emit:**
- `sendLocationUpdate`

**Giver Only Emits:**
- `acceptHelpRequest`
- `declineHelpRequest`

### Payload Formats

**sendLocationUpdate:**
```json
{
  "latitude": 23.7808945,
  "longitude": 90.4075576
}
```

**receiveLocationUpdate / giver_receiveLocationUpdate:**
```json
{
  "userId": "69245dcc54a019edcaa8f888",
  "latitude": 23.7808945,
  "longitude": 90.4075576
}
```

**acceptHelpRequest:**
```
"692f52a94983d29a62d4572d"  // helpRequestId as string
```

---

## Support & Resources

### Related Documentation
- [Location Update Formats](./location_update_formats.md) - Detailed location update formats
- [Socket Documentation](./socket_documentation.md) - General socket documentation
- [API Documentation](./api.md) - REST API documentation

### Common Issues

**Q: Location updates not working?**
A: Check if socket is in room and connected. See [Pitfall 1](#pitfall-1-location-updates-not-working)

**Q: Events not received?**
A: Verify event names match exactly. See [Pitfall 5](#pitfall-5-wrong-event-names)

**Q: Connection keeps dropping?**
A: Check token expiration and implement refresh logic. See [Pitfall 4](#pitfall-4-token-expiration)

**Q: Duplicate events?**
A: Remove old listeners before adding new ones. See [Pitfall 2](#pitfall-2-duplicate-event-listeners)

---

## Implementation Timeline

### Phase 1: Basic Connection (Day 1)
- [ ] Setup Socket.IO client
- [ ] Implement connection/disconnection
- [ ] Handle authentication
- [ ] Test connection

### Phase 2: Help Request Flow (Day 2-3)
- [ ] Seeker: Create request
- [ ] Giver: Receive new request
- [ ] Giver: Accept request
- [ ] Seeker: Receive acceptance
- [ ] Room joining

### Phase 3: Location Updates (Day 4-5)
- [ ] Send location updates
- [ ] Receive location updates
- [ ] Update map markers
- [ ] Calculate distance/ETA

### Phase 4: Error Handling & Polish (Day 6-7)
- [ ] Error handling
- [ ] Reconnection logic
- [ ] Token refresh
- [ ] Testing & bug fixes

---

**Last Updated:** December 2025
**Version:** 1.0


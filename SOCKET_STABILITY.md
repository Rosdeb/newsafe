# Socket Stability & Single Connection - Mobile Team Guide

**Date:** March 2025  
**Purpose:** Fix socket disconnects and ensure help requests reach nearby users

---

## Critical: Use ONE Socket Connection Per User

The backend stores **one socket ID per user** in Redis. When you connect, your socket ID overwrites any previous one.

### Do NOT:
- Create separate "Giver socket" and "Seeker socket" connections
- Maintain two concurrent connections for the same user
- Disconnect and reconnect when switching between Giver/Seeker screens

### Do:
- Use **one socket connection** for the entire app session
- Reuse the same socket whether the user is viewing Giver or Seeker screens
- Connect once after login and keep the connection alive

### Why:
When you maintain two sockets (Giver + Seeker), each connection overwrites the Redis `user:${userId}:socketId`. Only the **last connected** socket receives events. If the Giver socket disconnects when the user switches to Seeker screen, the backend will send `giver_newHelpRequest` to the Seeker socket—but that socket might be stale or the user might have reconnected with a different socket. This causes missed notifications.

With one socket, all events (`giver_newHelpRequest`, `helpRequestAccepted`, etc.) arrive on the same connection. The client can route them to the correct UI based on the event type.

---

## Backend Changes (Already Applied)

### 1. Socket.IO Timeouts (Mobile-Friendly)
- **pingTimeout:** 60 seconds (was 5s) – server waits longer before disconnecting idle clients
- **pingInterval:** 25 seconds – heartbeat interval
- **connectTimeout:** 45 seconds – allows slow mobile connections to establish

### 2. Consistent User ID Format
Redis keys now use `user._id.toString()` consistently. No change needed on mobile.

### 3. Debug Logging
When a help request is created, the server logs:
- Which users received `giver_newHelpRequest`
- "Socket not found" if the user was marked online but the socket disconnected
- Disconnect reason when a user disconnects

---

## Mobile Implementation Checklist

### Connection
- [ ] Connect **once** after login with the JWT token
- [ ] Store the socket instance in a singleton/service
- [ ] Use the same socket for all screens (Giver, Seeker, Both)
- [ ] Do NOT create a new connection when switching screens

### Reconnection
- [ ] If the socket disconnects, reconnect with the **same** token
- [ ] On reconnect, the new socket ID is automatically stored; no extra API calls needed
- [ ] Avoid "reconnection" logic that creates a second connection—reuse the existing one

### Event Handling
- [ ] Listen for `giver_newHelpRequest` on the single socket
- [ ] Listen for `helpRequestAccepted` on the same socket (when user is seeker)
- [ ] Route events to the correct screen/state based on event type, not socket type

### Connection Health
- [ ] Use Socket.IO's built-in `reconnection: true` (default)
- [ ] Consider `reconnectionDelay` of 1–3 seconds for mobile
- [ ] Do NOT implement custom "health check" logic that disconnects and reconnects—this causes the issues you're seeing

---

## Common Causes of "Other Users Not Getting Help Requests"

1. **Multiple sockets** – Last connection overwrites; notifications go to the wrong/stale socket
2. **Frequent disconnect/reconnect** – User appears offline during the window when the help request is created
3. **Token refresh** – If you disconnect and reconnect on token refresh, ensure the new connection is established before the old one is fully torn down
4. **App backgrounding** – Socket may disconnect when app goes to background; ensure you reconnect when app returns to foreground (one connection)

---

## Testing

1. User A (Giver): Connect socket, stay on "available to help" screen
2. User B (Seeker): Create help request
3. User A should receive `giver_newHelpRequest` within 1–2 seconds
4. Check server logs for "Sent giver_newHelpRequest to user" to confirm delivery

If User A does not receive:
- Check server logs for "Socket not found" or "No socket ID in Redis"
- Verify User A has only one active connection
- Verify User A's `isAvailable` is true and they have location set

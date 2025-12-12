# Message for Backend Team - Socket Ping Timeout Issue

---

**Subject: Socket.IO Ping Timeout Configuration - Urgent Fix Required**

Hi Backend Team,

We're experiencing frequent socket disconnections in our Flutter mobile app with the error: **"ping timeout"**. 

## 🔴 Problem

The socket connections are being terminated by the server because ping responses from the client are not arriving within the server's timeout window. This is causing:
- Frequent disconnections during active sessions
- Poor user experience with location sharing features
- Automatic reconnections that disrupt the app flow

## 🔍 Root Cause

The server's `pingTimeout` setting is likely too short (default is 20 seconds). On mobile networks, especially with:
- Network latency variations
- App backgrounding (Android/iOS may delay network packets)
- Network switching (WiFi ↔ Mobile data)

The ping responses can arrive after the timeout period, causing the server to disconnect the client.

## ✅ Solution

Please update the Socket.IO server configuration to increase the `pingTimeout`:

### For Node.js/Express:

```javascript
const { Server } = require("socket.io");

const io = new Server(httpServer, {
  pingTimeout: 60000,      // Increase from 20s to 60s
  pingInterval: 25000,     // Keep at 25s (standard)
  transports: ['websocket'],
  // ... other config
});
```

### For Python (python-socketio):

```python
import socketio

sio = socketio.Server(
    ping_timeout=60,      # 60 seconds (increase from default 20s)
    ping_interval=25,     # 25 seconds (standard)
    transports=['websocket']
)
```

## 📊 Recommended Settings

| Setting | Current (Default) | Recommended | Reason |
|---------|------------------|-------------|--------|
| `pingTimeout` | 20s | **60s** | Accommodates mobile network latency and app backgrounding |
| `pingInterval` | 25s | **25s** | Standard interval, no change needed |

## 🧪 Testing

After making this change, please test:
1. Connection stability over extended periods (30+ minutes)
2. Behavior when client has high latency
3. No negative impact on server resources

## 📝 Additional Notes

- The client-side code has been improved to handle reconnections better, but the primary fix is on the server side
- This is a common issue with mobile Socket.IO clients and increasing `pingTimeout` to 60s is a standard practice
- The timeout should be at least 2-3x the `pingInterval` to account for network delays

## ⚠️ Important

If you're using a load balancer or proxy in front of your Socket.IO server, ensure their timeout settings are also adjusted to be greater than the Socket.IO `pingTimeout` (e.g., 70-90 seconds).

---

**Priority**: High  
**Impact**: Affects all users with active socket connections  
**Estimated Fix Time**: 5-10 minutes (configuration change only)

Please let us know once this is deployed so we can verify the fix. Thank you!

---

*For detailed technical analysis, see: `SOCKET_PING_TIMEOUT_ISSUE.md`*


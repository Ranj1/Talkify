# Socket.IO + WebRTC Integration Guide

This guide explains how to integrate the Socket.IO service with your frontend for real-time chat and WebRTC calling.

## 🚀 Quick Start

### 1. Install Socket.IO Client

```bash
npm install socket.io-client
```

### 2. Initialize Socket Connection

```javascript
import io from 'socket.io-client';

// Connect to your backend
const socket = io('http://localhost:3000', {
  auth: {
    token: 'your-jwt-token' // Required for authentication
  }
});

// Handle connection
socket.on('connected', (data) => {
  console.log('Connected to server:', data);
  // Store your socket ID and user ID
  this.socketId = data.socketId;
  this.userId = data.userId;
});
```

## 💬 Chat Features

### Send Message

```javascript
// Send message to specific user
socket.emit('send-message', {
  to: 'recipient_uid',
  message: 'Hello!',
  type: 'text' // or 'image', 'file', etc.
});

// Send message to room
socket.emit('send-message', {
  roomId: 'room_123',
  message: 'Hello everyone!',
  type: 'text'
});

// Handle incoming messages
socket.on('message-received', (data) => {
  console.log('New message:', data);
  // data: { id, from, fromName, to, message, type, timestamp, roomId }
});
```

### Typing Indicators

```javascript
// Start typing
socket.emit('typing-start', {
  to: 'recipient_uid' // or roomId: 'room_123'
});

// Stop typing
socket.emit('typing-stop', {
  to: 'recipient_uid' // or roomId: 'room_123'
});

// Handle typing indicators
socket.on('user-typing', (data) => {
  console.log('User typing:', data);
  // data: { from, fromName, isTyping, timestamp }
});
```

### Room Management

```javascript
// Join room
socket.emit('join', { roomId: 'room_123' });

// Leave room
socket.emit('leave', { roomId: 'room_123' });

// Handle room events
socket.on('joined-room', (data) => {
  console.log('Joined room:', data.roomId);
});

socket.on('left-room', (data) => {
  console.log('Left room:', data.roomId);
});
```

## 📞 WebRTC Calling Features

### Initiate Call

```javascript
// Start a call
socket.emit('call-user', {
  to: 'recipient_uid',
  callType: 'audio', // or 'video'
  roomId: 'optional_room_id'
});

// Handle call initiated
socket.on('call-initiated', (data) => {
  console.log('Call initiated:', data);
  // data: { callId, to, status }
});
```

### Handle Incoming Calls

```javascript
// Handle incoming call
socket.on('incoming-call', (data) => {
  console.log('Incoming call:', data);
  // data: { callId, from, fromName, to, callType, roomId, timestamp }
  
  // Show call UI and ask user to accept/reject
  showIncomingCallUI(data);
});

// Accept call
socket.emit('accept-call', { callId: 'call_123' });

// Reject call
socket.emit('reject-call', { callId: 'call_123' });

// Handle call responses
socket.on('call-accepted', (data) => {
  console.log('Call accepted:', data);
  // Start WebRTC connection
});

socket.on('call-rejected', (data) => {
  console.log('Call rejected:', data);
  // Hide call UI
});
```

### WebRTC Signaling

```javascript
// Send WebRTC offer
socket.emit('call-offer', {
  callId: 'call_123',
  offer: rtcOffer,
  to: 'recipient_uid'
});

// Send WebRTC answer
socket.emit('call-answer', {
  callId: 'call_123',
  answer: rtcAnswer,
  to: 'caller_uid'
});

// Send ICE candidate
socket.emit('ice-candidate', {
  callId: 'call_123',
  candidate: iceCandidate,
  to: 'peer_uid'
});

// Handle WebRTC signaling
socket.on('call-offer', (data) => {
  // Handle incoming offer
  handleWebRTCOffer(data.offer);
});

socket.on('call-answer', (data) => {
  // Handle incoming answer
  handleWebRTCAnswer(data.answer);
});

socket.on('ice-candidate', (data) => {
  // Handle incoming ICE candidate
  handleICECandidate(data.candidate);
});
```

### End Call

```javascript
// End call
socket.emit('end-call', { callId: 'call_123' });

// Handle call ended
socket.on('call-ended', (data) => {
  console.log('Call ended:', data);
  // data: { callId, endedBy, duration, timestamp }
  // Clean up WebRTC connection
});
```

## 👥 Presence Features

### Online/Offline Status

```javascript
// Handle user online
socket.on('user-online', (data) => {
  console.log('User came online:', data);
  // data: { userId, name, timestamp }
  updateUserStatus(data.userId, 'online');
});

// Handle user offline
socket.on('user-offline', (data) => {
  console.log('User went offline:', data);
  // data: { userId, timestamp }
  updateUserStatus(data.userId, 'offline');
});
```

## 🔧 Error Handling

```javascript
// Handle connection errors
socket.on('connect_error', (error) => {
  console.error('Connection error:', error);
  // Handle authentication errors, network issues, etc.
});

// Handle message errors
socket.on('message-error', (data) => {
  console.error('Message error:', data);
  // Handle message sending failures
});

// Handle call errors
socket.on('call-error', (data) => {
  console.error('Call error:', data);
  // Handle call failures
});
```

## 📱 Complete WebRTC Implementation Example

```javascript
class WebRTCManager {
  constructor(socket) {
    this.socket = socket;
    this.peerConnection = null;
    this.currentCallId = null;
    this.setupSocketListeners();
  }

  setupSocketListeners() {
    // Handle incoming call
    this.socket.on('incoming-call', (data) => {
      this.handleIncomingCall(data);
    });

    // Handle call accepted
    this.socket.on('call-accepted', (data) => {
      this.handleCallAccepted(data);
    });

    // Handle WebRTC offer
    this.socket.on('call-offer', (data) => {
      this.handleOffer(data);
    });

    // Handle WebRTC answer
    this.socket.on('call-answer', (data) => {
      this.handleAnswer(data);
    });

    // Handle ICE candidate
    this.socket.on('ice-candidate', (data) => {
      this.handleICECandidate(data);
    });
  }

  async startCall(to, callType = 'audio') {
    try {
      // Create peer connection
      this.peerConnection = new RTCPeerConnection({
        iceServers: [
          { urls: 'stun:stun.l.google.com:19302' }
        ]
      });

      // Setup media streams
      const stream = await navigator.mediaDevices.getUserMedia({
        audio: true,
        video: callType === 'video'
      });

      stream.getTracks().forEach(track => {
        this.peerConnection.addTrack(track, stream);
      });

      // Setup ICE candidate handling
      this.peerConnection.onicecandidate = (event) => {
        if (event.candidate) {
          this.socket.emit('ice-candidate', {
            callId: this.currentCallId,
            candidate: event.candidate,
            to: to
          });
        }
      };

      // Initiate call
      this.socket.emit('call-user', {
        to: to,
        callType: callType
      });

    } catch (error) {
      console.error('Error starting call:', error);
    }
  }

  async handleIncomingCall(data) {
    // Show incoming call UI
    const accept = confirm(`Incoming ${data.callType} call from ${data.fromName}`);
    
    if (accept) {
      this.currentCallId = data.callId;
      this.socket.emit('accept-call', { callId: data.callId });
    } else {
      this.socket.emit('reject-call', { callId: data.callId });
    }
  }

  async handleCallAccepted(data) {
    // Create offer and send it
    const offer = await this.peerConnection.createOffer();
    await this.peerConnection.setLocalDescription(offer);
    
    this.socket.emit('call-offer', {
      callId: data.callId,
      offer: offer,
      to: data.acceptedBy
    });
  }

  async handleOffer(data) {
    await this.peerConnection.setRemoteDescription(data.offer);
    const answer = await this.peerConnection.createAnswer();
    await this.peerConnection.setLocalDescription(answer);
    
    this.socket.emit('call-answer', {
      callId: data.callId,
      answer: answer,
      to: data.from
    });
  }

  async handleAnswer(data) {
    await this.peerConnection.setRemoteDescription(data.answer);
  }

  async handleICECandidate(data) {
    await this.peerConnection.addIceCandidate(data.candidate);
  }

  endCall() {
    if (this.currentCallId) {
      this.socket.emit('end-call', { callId: this.currentCallId });
      this.currentCallId = null;
    }
    
    if (this.peerConnection) {
      this.peerConnection.close();
      this.peerConnection = null;
    }
  }
}

// Usage
const socket = io('http://localhost:3000', {
  auth: { token: 'your-jwt-token' }
});

const webrtcManager = new WebRTCManager(socket);
```

## 🛠️ Server-Side Utilities

```javascript
const SocketUtils = require('./utils/socketUtils');

// Get online users count
const onlineCount = SocketUtils.getOnlineUsersCount();

// Check if user is online
const isOnline = SocketUtils.isUserOnline('user_uid');

// Send message to user
SocketUtils.sendToUser('user_uid', 'custom-event', { data: 'message' });

// Get server statistics
const stats = SocketUtils.getServerStats();
```

## 📋 Event Reference

### Client → Server Events

| Event | Data | Description |
|-------|------|-------------|
| `join` | `{ roomId }` | Join a room |
| `leave` | `{ roomId }` | Leave a room |
| `send-message` | `{ to, message, type, roomId }` | Send message |
| `typing-start` | `{ to, roomId }` | Start typing indicator |
| `typing-stop` | `{ to, roomId }` | Stop typing indicator |
| `call-user` | `{ to, callType, roomId }` | Initiate call |
| `accept-call` | `{ callId }` | Accept incoming call |
| `reject-call` | `{ callId }` | Reject incoming call |
| `end-call` | `{ callId }` | End active call |
| `call-offer` | `{ callId, offer, to }` | Send WebRTC offer |
| `call-answer` | `{ callId, answer, to }` | Send WebRTC answer |
| `ice-candidate` | `{ callId, candidate, to }` | Send ICE candidate |

### Server → Client Events

| Event | Data | Description |
|-------|------|-------------|
| `connected` | `{ message, userId, socketId, timestamp }` | Connection confirmed |
| `joined-room` | `{ roomId, message }` | Room join confirmed |
| `left-room` | `{ roomId, message }` | Room leave confirmed |
| `message-received` | `{ id, from, fromName, to, message, type, timestamp, roomId }` | New message |
| `message-sent` | `{ messageId, timestamp }` | Message sent confirmation |
| `user-typing` | `{ from, fromName, isTyping, timestamp }` | Typing indicator |
| `user-online` | `{ userId, name, timestamp }` | User came online |
| `user-offline` | `{ userId, timestamp }` | User went offline |
| `incoming-call` | `{ callId, from, fromName, to, callType, roomId, timestamp }` | Incoming call |
| `call-initiated` | `{ callId, to, status }` | Call initiated confirmation |
| `call-accepted` | `{ callId, acceptedBy, timestamp }` | Call accepted |
| `call-rejected` | `{ callId, rejectedBy, timestamp }` | Call rejected |
| `call-ended` | `{ callId, endedBy, duration, timestamp }` | Call ended |
| `call-offer` | `{ callId, from, offer, timestamp }` | WebRTC offer |
| `call-answer` | `{ callId, from, answer, timestamp }` | WebRTC answer |
| `ice-candidate` | `{ callId, from, candidate, timestamp }` | ICE candidate |

## 🔒 Security Notes

1. **Authentication**: All socket connections require valid JWT tokens
2. **Rate Limiting**: Consider implementing rate limiting for socket events
3. **Input Validation**: Validate all incoming socket data
4. **CORS**: Configure CORS properly for your frontend domain
5. **HTTPS**: Use HTTPS in production for secure WebRTC connections

## 🚀 Production Considerations

1. **Scaling**: Use Redis adapter for multiple server instances
2. **Monitoring**: Implement proper logging and monitoring
3. **Error Handling**: Add comprehensive error handling
4. **Performance**: Monitor memory usage and connection counts
5. **Security**: Regular security audits and updates

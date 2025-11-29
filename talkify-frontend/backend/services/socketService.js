const { Server } = require('socket.io');
const { authenticateSocket } = require('../middleware/authMiddleware');
const User = require('../models/User');
const Call = require('../models/Call');
const fcmService = require('./fcmService');
const { v4: uuidv4 } = require('uuid');

/**
 * Socket.IO Service for Real-time Chat and WebRTC Signaling
 * Handles chat messages, online presence, and call signaling
 */
class SocketService {
  constructor() {
    this.io = null;
    this.userSockets = new Map(); // Map of uid to socket instance
    this.socketUsers = new Map(); // Map of socketId to uid
    this.roomUsers = new Map(); // Map of roomId to Set of uids
    this.activeCalls = new Map(); // Map of callId to call data
  }

  /**
   * Initialize Socket.IO with HTTP server
   * @param {Object} server - HTTP server instance
   */
  initialize(server) {
    this.io = new Server(server, {
      cors: {
        origin: process.env.CORS_ORIGIN || '*',
        methods: ['GET', 'POST'],
        credentials: true
      },
      transports: ['websocket', 'polling']
    });

    this.setupMiddleware();
    this.setupEventHandlers();
    
    console.log('🔌 Socket.IO service initialized');
  }

  /**
   * Setup Socket.IO middleware for authentication
   */
  setupMiddleware() {
    this.io.use(authenticateSocket);
  }

  /**
   * Setup all Socket.IO event handlers
   */
  setupEventHandlers() {
    this.io.on('connection', (socket) => {
      this.handleConnection(socket);
    });
  }

  /**
   * Handle new socket connection
   * @param {Object} socket - Socket instance
   */
  async handleConnection(socket) {
    const user = socket.user;
    const uid = user.uid;
    
    console.log(`🔗 User connected: ${uid} (${socket.id})`);
    
    // Store socket mappings
    this.userSockets.set(uid, socket);
    this.socketUsers.set(socket.id, uid);
    
    // Update user online status in database
    await this.updateUserOnlineStatus(uid, true);
    
    // Join user to their personal room
    socket.join(`user_${uid}`);
    
    // Emit connection confirmation
    socket.emit('connected', {
      message: 'Connected to Talkify server',
      userId: uid,
      socketId: socket.id,
      timestamp: new Date().toISOString()
    });

    // Notify other users about this user coming online
    socket.broadcast.emit('user-online', {
      userId: uid,
      name: user.name,
      timestamp: new Date().toISOString()
    });

    // Setup event handlers for this socket
    this.setupSocketEventHandlers(socket);
  }

  /**
   * Setup event handlers for a specific socket
   * @param {Object} socket - Socket instance
   */
  setupSocketEventHandlers(socket) {
    const uid = socket.user.uid;

    // Handle disconnect
    socket.on('disconnect', async () => {
      await this.handleDisconnect(socket);
    });

    // Handle join room
    socket.on('join', (data) => {
      this.handleJoinRoom(socket, data);
    });

    // Handle leave room
    socket.on('leave', (data) => {
      this.handleLeaveRoom(socket, data);
    });

    // Handle send message
    socket.on('send-message', (data) => {
      this.handleSendMessage(socket, data);
    });

    // Handle typing indicators
    socket.on('typing-start', (data) => {
      this.handleTypingStart(socket, data);
    });

    socket.on('typing-stop', (data) => {
      this.handleTypingStop(socket, data);
    });

    // WebRTC Call Signaling Events
    socket.on('call-user', (data) => {
      this.handleCallUser(socket, data);
    });

    socket.on('accept-call', (data) => {
      this.handleAcceptCall(socket, data);
    });

    socket.on('reject-call', (data) => {
      this.handleRejectCall(socket, data);
    });

    socket.on('end-call', (data) => {
      this.handleEndCall(socket, data);
    });

    socket.on('call-offer', (data) => {
      this.handleCallOffer(socket, data);
    });

    socket.on('call-answer', (data) => {
      this.handleCallAnswer(socket, data);
    });

    socket.on('ice-candidate', (data) => {
      this.handleIceCandidate(socket, data);
    });

    // Handle call state changes
    socket.on('call-state-change', (data) => {
      this.handleCallStateChange(socket, data);
    });
  }

  /**
   * Handle socket disconnect
   * @param {Object} socket - Socket instance
   */
  async handleDisconnect(socket) {
    const uid = this.socketUsers.get(socket.id);
    
    if (uid) {
      console.log(`🔌 User disconnected: ${uid} (${socket.id})`);
      
      // Remove socket mappings
      this.userSockets.delete(uid);
      this.socketUsers.delete(socket.id);
      
      // Update user offline status
      await this.updateUserOnlineStatus(uid, false);
      
      // Notify other users about this user going offline
      socket.broadcast.emit('user-offline', {
        userId: uid,
        timestamp: new Date().toISOString()
      });

      // Clean up any active calls
      await this.cleanupUserCalls(uid);
    }
  }

  /**
   * Handle join room
   * @param {Object} socket - Socket instance
   * @param {Object} data - Room data
   */
  handleJoinRoom(socket, data) {
    const { roomId } = data;
    const uid = socket.user.uid;
    
    if (roomId) {
      socket.join(roomId);
      
      // Track room membership
      if (!this.roomUsers.has(roomId)) {
        this.roomUsers.set(roomId, new Set());
      }
      this.roomUsers.get(roomId).add(uid);
      
      console.log(`👥 User ${uid} joined room: ${roomId}`);
      
      socket.emit('joined-room', {
        roomId,
        message: `Joined room ${roomId}`
      });
    }
  }

  /**
   * Handle leave room
   * @param {Object} socket - Socket instance
   * @param {Object} data - Room data
   */
  handleLeaveRoom(socket, data) {
    const { roomId } = data;
    const uid = socket.user.uid;
    
    if (roomId) {
      socket.leave(roomId);
      
      // Update room membership
      if (this.roomUsers.has(roomId)) {
        this.roomUsers.get(roomId).delete(uid);
        if (this.roomUsers.get(roomId).size === 0) {
          this.roomUsers.delete(roomId);
        }
      }
      
      console.log(`👥 User ${uid} left room: ${roomId}`);
      
      socket.emit('left-room', {
        roomId,
        message: `Left room ${roomId}`
      });
    }
  }

  /**
   * Handle send message
   * @param {Object} socket - Socket instance
   * @param {Object} data - Message data
   */
  async handleSendMessage(socket, data) {
    try {
      const { to, message, type = 'text', roomId } = data;
      const from = socket.user.uid;
      const fromName = socket.user.name;
      
      const messageData = {
        id: uuidv4(),
        from,
        fromName,
        to,
        message,
        type,
        timestamp: new Date().toISOString(),
        roomId: roomId || null
      };

      if (roomId) {
        // Send to room
        socket.to(roomId).emit('message-received', messageData);
        console.log(`💬 Message sent to room ${roomId}: ${message}`);
      } else if (to) {
        // Send to specific user
        const recipientSocket = this.userSockets.get(to);
        if (recipientSocket) {
          recipientSocket.emit('message-received', messageData);
          console.log(`💬 Message sent to user ${to}: ${message}`);
        } else {
          // User is offline, send push notification
          await this.sendOfflineMessageNotification(to, messageData);
        }
      }

      // Confirm message sent
      socket.emit('message-sent', {
        messageId: messageData.id,
        timestamp: messageData.timestamp
      });

    } catch (error) {
      console.error('Error handling send message:', error);
      socket.emit('message-error', {
        error: 'Failed to send message'
      });
    }
  }

  /**
   * Handle typing start
   * @param {Object} socket - Socket instance
   * @param {Object} data - Typing data
   */
  handleTypingStart(socket, data) {
    const { to, roomId } = data;
    const from = socket.user.uid;
    const fromName = socket.user.name;

    const typingData = {
      from,
      fromName,
      isTyping: true,
      timestamp: new Date().toISOString()
    };

    if (roomId) {
      socket.to(roomId).emit('user-typing', typingData);
    } else if (to) {
      const recipientSocket = this.userSockets.get(to);
      if (recipientSocket) {
        recipientSocket.emit('user-typing', typingData);
      }
    }
  }

  /**
   * Handle typing stop
   * @param {Object} socket - Socket instance
   * @param {Object} data - Typing data
   */
  handleTypingStop(socket, data) {
    const { to, roomId } = data;
    const from = socket.user.uid;
    const fromName = socket.user.name;

    const typingData = {
      from,
      fromName,
      isTyping: false,
      timestamp: new Date().toISOString()
    };

    if (roomId) {
      socket.to(roomId).emit('user-typing', typingData);
    } else if (to) {
      const recipientSocket = this.userSockets.get(to);
      if (recipientSocket) {
        recipientSocket.emit('user-typing', typingData);
      }
    }
  }

  /**
   * Handle call user (initiate call)
   * @param {Object} socket - Socket instance
   * @param {Object} data - Call data
   */
  async handleCallUser(socket, data) {
    try {
      const { to, callType = 'audio', roomId } = data;
      const from = socket.user.uid;
      const fromName = socket.user.name;
      
      const callId = uuidv4();
      
      // Store call data
      this.activeCalls.set(callId, {
        callId,
        from,
        to,
        callType,
        roomId,
        status: 'initiated',
        startTime: new Date(),
        participants: new Set([from])
      });

      // Create call record in database
      const callee = await User.findOne({ uid: to });
      if (callee) {
        const call = new Call({
          callId,
          caller: socket.user._id,
          callee: callee._id,
          callType,
          status: 'initiated'
        });
        await call.save();
      }

      const callData = {
        callId,
        from,
        fromName,
        to,
        callType,
        roomId,
        timestamp: new Date().toISOString()
      };

      // Send call invitation to recipient
      const recipientSocket = this.userSockets.get(to);
      console.log(`🔍 Looking for recipient socket: ${to}`);
      console.log(`🔍 Available sockets: ${Array.from(this.userSockets.keys())}`);
      console.log(`🔍 Recipient socket found: ${recipientSocket ? 'YES' : 'NO'}`);
      
      if (recipientSocket) {
        recipientSocket.emit('incoming-call', callData);
        console.log(`📞 Call initiated: ${from} → ${to} (${callType})`);
        console.log(`📞 Incoming call event sent to socket: ${recipientSocket.id}`);
      } else {
        console.log(`📱 Recipient ${to} is offline, sending push notification`);
        // Send push notification for offline user
        await this.sendCallNotification(to, callData);
      }

      // Confirm call initiated
      socket.emit('call-initiated', {
        callId,
        to,
        status: 'initiated'
      });

    } catch (error) {
      console.error('Error handling call user:', error);
      socket.emit('call-error', {
        error: 'Failed to initiate call'
      });
    }
  }

  /**
   * Handle accept call
   * @param {Object} socket - Socket instance
   * @param {Object} data - Call data
   */
  async handleAcceptCall(socket, data) {
    try {
      const { callId } = data;
      const uid = socket.user.uid;
      
      const call = this.activeCalls.get(callId);
      if (!call) {
        socket.emit('call-error', { error: 'Call not found' });
        return;
      }

      // Update call status
      call.status = 'answered';
      call.participants.add(uid);

      // Update database
      await Call.findOneAndUpdate(
        { callId },
        { status: 'answered' }
      );

      // Notify caller
      const callerSocket = this.userSockets.get(call.from);
      if (callerSocket) {
        callerSocket.emit('call-accepted', {
          callId,
          acceptedBy: uid,
          timestamp: new Date().toISOString()
        });
      }

      // Confirm acceptance
      socket.emit('call-accept-confirmed', {
        callId,
        status: 'answered'
      });

      console.log(`✅ Call accepted: ${callId} by ${uid}`);

    } catch (error) {
      console.error('Error handling accept call:', error);
      socket.emit('call-error', { error: 'Failed to accept call' });
    }
  }

  /**
   * Handle reject call
   * @param {Object} socket - Socket instance
   * @param {Object} data - Call data
   */
  async handleRejectCall(socket, data) {
    try {
      const { callId } = data;
      const uid = socket.user.uid;
      
      const call = this.activeCalls.get(callId);
      if (!call) {
        socket.emit('call-error', { error: 'Call not found' });
        return;
      }

      // Update call status
      call.status = 'rejected';

      // Update database
      await Call.findOneAndUpdate(
        { callId },
        { status: 'rejected' }
      );

      // Notify caller
      const callerSocket = this.userSockets.get(call.from);
      if (callerSocket) {
        callerSocket.emit('call-rejected', {
          callId,
          rejectedBy: uid,
          timestamp: new Date().toISOString()
        });
      }

      // Clean up call
      this.activeCalls.delete(callId);

      console.log(`❌ Call rejected: ${callId} by ${uid}`);

    } catch (error) {
      console.error('Error handling reject call:', error);
      socket.emit('call-error', { error: 'Failed to reject call' });
    }
  }

  /**
   * Handle end call
   * @param {Object} socket - Socket instance
   * @param {Object} data - Call data
   */
  async handleEndCall(socket, data) {
    try {
      const { callId } = data;
      const uid = socket.user.uid;
      
      const call = this.activeCalls.get(callId);
      if (!call) {
        socket.emit('call-error', { error: 'Call not found' });
        return;
      }

      // Update call status
      call.status = 'ended';
      call.endTime = new Date();
      call.duration = Math.floor((call.endTime - call.startTime) / 1000);

      // Update database
      await Call.findOneAndUpdate(
        { callId },
        { 
          status: 'ended',
          endTime: call.endTime,
          duration: call.duration
        }
      );

      // Notify all participants
      const endData = {
        callId,
        endedBy: uid,
        duration: call.duration,
        timestamp: new Date().toISOString()
      };

      call.participants.forEach(participantId => {
        const participantSocket = this.userSockets.get(participantId);
        if (participantSocket) {
          participantSocket.emit('call-ended', endData);
        }
      });

      // Clean up call
      this.activeCalls.delete(callId);

      console.log(`📞 Call ended: ${callId} (${call.duration}s)`);

    } catch (error) {
      console.error('Error handling end call:', error);
      socket.emit('call-error', { error: 'Failed to end call' });
    }
  }

  /**
   * Handle WebRTC call offer
   * @param {Object} socket - Socket instance
   * @param {Object} data - Offer data
   */
  handleCallOffer(socket, data) {
    console.log('========================================');
    console.log('📥 === BACKEND: CALL-OFFER EVENT RECEIVED ===');
    console.log('📥 Raw data keys:', Object.keys(data).join(', '));
    console.log('📥 Full data:', JSON.stringify(data).substring(0, 500));
    
    // Support both 'roomId' and 'callId' field names
    const roomId = data.roomId || data.callId;
    const offer = data.offer;
    const to = data.to;
    const from = socket.user.uid;

    console.log('📥 Parsed values:');
    console.log('📥 - From:', from);
    console.log('📥 - To:', to);
    console.log('📥 - Room ID:', roomId);
    console.log('📥 - Offer present:', offer ? 'YES' : 'NO');

    const offerData = {
      roomId,        // Send back as 'roomId' to match frontend expectations
      callId: roomId, // Also include as 'callId' for compatibility
      from,
      offer,
      timestamp: new Date().toISOString()
    };

    // Forward offer to recipient
    const recipientSocket = this.userSockets.get(to);
    console.log('📥 Recipient socket lookup:', to, '→', recipientSocket ? 'FOUND' : 'NOT FOUND');
    
    if (recipientSocket) {
      console.log('📤 Sending call-offer to recipient');
      console.log('📤 Offer data:', JSON.stringify(offerData).substring(0, 500));
      recipientSocket.emit('call-offer', offerData);
      console.log(`✅ WebRTC offer sent: ${from} → ${to}`);
    } else {
      console.log(`❌ Recipient ${to} not available`);
      socket.emit('call-error', { error: 'Recipient not available' });
    }
    console.log('========================================');
  }

  /**
   * Handle WebRTC call answer
   * @param {Object} socket - Socket instance
   * @param {Object} data - Answer data
   */
  handleCallAnswer(socket, data) {
    console.log('========================================');
    console.log('📥 === BACKEND: CALL-ANSWER EVENT RECEIVED ===');
    console.log('📥 Raw data keys:', Object.keys(data).join(', '));
    console.log('📥 Full data:', JSON.stringify(data).substring(0, 500));
    
    // Support both 'roomId' and 'callId' field names
    const roomId = data.roomId || data.callId;
    const answer = data.answer;
    const to = data.to;
    const from = socket.user.uid;

    console.log('📥 Parsed values:');
    console.log('📥 - From:', from);
    console.log('📥 - To:', to);
    console.log('📥 - Room ID:', roomId);
    console.log('📥 - Answer present:', answer ? 'YES' : 'NO');

    const answerData = {
      roomId,         // Send back as 'roomId' to match frontend expectations
      callId: roomId, // Also include as 'callId' for compatibility
      from,
      answer,
      timestamp: new Date().toISOString()
    };

    // Forward answer to caller
    const callerSocket = this.userSockets.get(to);
    console.log('📥 Caller socket lookup:', to, '→', callerSocket ? 'FOUND' : 'NOT FOUND');
    
    if (callerSocket) {
      console.log('📤 Sending call-answer to caller');
      console.log('📤 Answer data:', JSON.stringify(answerData).substring(0, 500));
      callerSocket.emit('call-answer', answerData);
      console.log(`✅ WebRTC answer sent: ${from} → ${to}`);
    } else {
      console.log(`❌ Caller ${to} not available`);
      socket.emit('call-error', { error: 'Caller not available' });
    }
    console.log('========================================');
  }

  /**
   * Handle WebRTC ICE candidate
   * @param {Object} socket - Socket instance
   * @param {Object} data - ICE candidate data
   */
  handleIceCandidate(socket, data) {
    console.log('========================================');
    console.log('📥 === BACKEND: ICE-CANDIDATE EVENT RECEIVED ===');
    console.log('📥 Raw data keys:', Object.keys(data).join(', '));
    
    // Support both 'roomId'/'callId' field names
    const roomId = data.roomId || data.callId;
    const candidate = data.candidate;
    const to = data.to;
    const from = socket.user.uid;

    console.log('📥 Parsed values:');
    console.log('📥 - From:', from);
    console.log('📥 - To:', to);
    console.log('📥 - Room ID:', roomId);
    console.log('📥 - Candidate present:', candidate ? 'YES' : 'NO');
    if (candidate) {
      console.log('📥 - Candidate:', JSON.stringify(candidate).substring(0, 200));
    }

    const candidateData = {
      roomId,         // Send back as 'roomId' to match frontend expectations
      callId: roomId, // Also include as 'callId' for compatibility
      from,
      senderId: from, // Also include as 'senderId' for compatibility
      candidate,
      timestamp: new Date().toISOString()
    };

    // Forward ICE candidate to peer
    const peerSocket = this.userSockets.get(to);
    console.log('📥 Peer socket lookup:', to, '→', peerSocket ? 'FOUND' : 'NOT FOUND');
    
    if (peerSocket) {
      console.log('📤 Sending ice-candidate to peer');
      console.log('📤 Candidate data:', JSON.stringify(candidateData).substring(0, 300));
      peerSocket.emit('ice-candidate', candidateData);
      console.log(`✅ ICE candidate sent: ${from} → ${to}`);
    } else {
      console.log(`❌ Peer ${to} not available`);
    }
    console.log('========================================');
  }

  /**
   * Handle call state change
   * @param {Object} socket - Socket instance
   * @param {Object} data - State change data
   */
  handleCallStateChange(socket, data) {
    const { callId, state, to } = data;
    const from = socket.user.uid;

    const stateData = {
      callId,
      from,
      state,
      timestamp: new Date().toISOString()
    };

    // Forward state change to peer
    const peerSocket = this.userSockets.get(to);
    if (peerSocket) {
      peerSocket.emit('call-state-change', stateData);
      console.log(`🔄 Call state changed: ${from} → ${state}`);
    }
  }

  /**
   * Update user online status in database
   * @param {String} uid - User ID
   * @param {Boolean} isOnline - Online status
   */
  async updateUserOnlineStatus(uid, isOnline) {
    try {
      await User.findOneAndUpdate(
        { uid },
        { 
          isOnline,
          lastSeen: new Date()
        }
      );
    } catch (error) {
      console.error('Error updating user online status:', error);
    }
  }

  /**
   * Send offline message notification
   * @param {String} to - Recipient UID
   * @param {Object} messageData - Message data
   */
  async sendOfflineMessageNotification(to, messageData) {
    try {
      const user = await User.findOne({ uid: to });
      if (user && user.fcmToken) {
        await fcmService.sendToDevice(user.fcmToken, {
          title: `New message from ${messageData.fromName}`,
          body: messageData.message
        }, {
          type: 'message',
          messageId: messageData.id,
          from: messageData.from
        });
      }
    } catch (error) {
      console.error('Error sending offline message notification:', error);
    }
  }

  /**
   * Send call notification
   * @param {String} to - Recipient UID
   * @param {Object} callData - Call data
   */
  async sendCallNotification(to, callData) {
    try {
      const user = await User.findOne({ uid: to });
      if (user && user.fcmToken) {
        await fcmService.sendCallNotification(user.fcmToken, {
          callId: callData.callId,
          callerId: callData.from,
          callerName: callData.fromName,
          callType: callData.callType,
          timestamp: callData.timestamp
        });
      }
    } catch (error) {
      console.error('Error sending call notification:', error);
    }
  }

  /**
   * Clean up user calls when they disconnect
   * @param {String} uid - User ID
   */
  async cleanupUserCalls(uid) {
    try {
      const userCalls = Array.from(this.activeCalls.values())
        .filter(call => call.participants.has(uid));

      for (const call of userCalls) {
        call.status = 'ended';
        call.endTime = new Date();
        call.duration = Math.floor((call.endTime - call.startTime) / 1000);

        // Update database
        await Call.findOneAndUpdate(
          { callId: call.callId },
          { 
            status: 'ended',
            endTime: call.endTime,
            duration: call.duration
          }
        );

        // Notify other participants
        const endData = {
          callId: call.callId,
          endedBy: uid,
          reason: 'user_disconnected',
          timestamp: new Date().toISOString()
        };

        call.participants.forEach(participantId => {
          if (participantId !== uid) {
            const participantSocket = this.userSockets.get(participantId);
            if (participantSocket) {
              participantSocket.emit('call-ended', endData);
            }
          }
        });

        this.activeCalls.delete(call.callId);
      }
    } catch (error) {
      console.error('Error cleaning up user calls:', error);
    }
  }

  /**
   * Get online users count
   * @returns {Number} Online users count
   */
  getOnlineUsersCount() {
    return this.userSockets.size;
  }

  /**
   * Get online users list
   * @returns {Array} Array of online user IDs
   */
  getOnlineUsers() {
    return Array.from(this.userSockets.keys());
  }

  /**
   * Check if user is online
   * @param {String} uid - User ID
   * @returns {Boolean} Online status
   */
  isUserOnline(uid) {
    return this.userSockets.has(uid);
  }

  /**
   * Get user socket by UID
   * @param {String} uid - User ID
   * @returns {Object|null} Socket instance or null
   */
  getUserSocket(uid) {
    return this.userSockets.get(uid) || null;
  }

  /**
   * Send message to specific user
   * @param {String} uid - User ID
   * @param {String} event - Event name
   * @param {Object} data - Event data
   */
  sendToUser(uid, event, data) {
    const socket = this.userSockets.get(uid);
    if (socket) {
      socket.emit(event, data);
      return true;
    }
    return false;
  }

  /**
   * Send message to room
   * @param {String} roomId - Room ID
   * @param {String} event - Event name
   * @param {Object} data - Event data
   */
  sendToRoom(roomId, event, data) {
    this.io.to(roomId).emit(event, data);
  }

  /**
   * Broadcast message to all connected users
   * @param {String} event - Event name
   * @param {Object} data - Event data
   */
  broadcast(event, data) {
    this.io.emit(event, data);
  }
}

module.exports = new SocketService();

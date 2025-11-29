const { Server } = require('socket.io');
const { authenticateSocket } = require('../middleware/authMiddleware');
const User = require('../models/User');
const Call = require('../models/Call');
const fcmService = require('../services/fcmService');

/**
 * Call Socket Handler
 * Handles Socket.IO events for Talkify call signaling
 */
class CallSocketHandler {
  constructor(io) {
    this.io = io;
    this.userSockets = new Map(); // Map of userId to socketId
    this.setupMiddleware();
    this.setupEventHandlers();
  }

  /**
   * Setup Socket.IO middleware
   */
  setupMiddleware() {
    this.io.use(authenticateSocket);
  }

  /**
   * Setup Socket.IO event handlers
   */
  setupEventHandlers() {
    this.io.on('connection', (socket) => {
      console.log(`User connected: ${socket.user.uid} (${socket.id})`);
      
      // Store user socket mapping
      this.userSockets.set(socket.user.uid, socket.id);
      
      // Update user online status
      this.updateUserStatus(socket.user.uid, true);

      // Handle user joining
      socket.emit('connected', {
        message: 'Connected to call server',
        userId: socket.user.uid
      });

      // Handle call-user event
      socket.on('call-user', (data) => {
        this.handleCallUser(socket, data);
      });

      // Handle answer-call event
      socket.on('answer-call', (data) => {
        this.handleAnswerCall(socket, data);
      });

      // Handle ice-candidate event
      socket.on('ice-candidate', (data) => {
        this.handleIceCandidate(socket, data);
      });

      // Handle end-call event
      socket.on('end-call', (data) => {
        this.handleEndCall(socket, data);
      });

      // Handle reject-call event
      socket.on('reject-call', (data) => {
        this.handleRejectCall(socket, data);
      });

      // Handle user typing/status updates
      socket.on('user-typing', (data) => {
        this.handleUserTyping(socket, data);
      });

      // Handle disconnect
      socket.on('disconnect', () => {
        this.handleDisconnect(socket);
      });
    });
  }

  /**
   * Handle call-user event
   * @param {Object} socket - Socket instance
   * @param {Object} data - Call data
   */
  async handleCallUser(socket, data) {
    try {
      const { calleeId, callId, offer, callType = 'audio' } = data;
      const callerId = socket.user.uid;

      console.log('=== CALL-USER EVENT ===');
      console.log(`Call initiated: ${callerId} -> ${calleeId}`);
      console.log(`Call ID: ${callId}`);
      console.log(`Call type: ${callType}`);
      console.log(`Offer present: ${offer ? 'YES' : 'NO'}`);
      if (offer) {
        console.log(`Offer type: ${offer.type}`);
        console.log(`Offer SDP length: ${offer.sdp ? offer.sdp.length : 0}`);
      }

      // Find callee socket
      const calleeSocketId = this.userSockets.get(calleeId);
      if (!calleeSocketId) {
        socket.emit('call-failed', {
          callId,
          reason: 'User not available'
        });
        return;
      }

      // Get callee socket
      const calleeSocket = this.io.sockets.sockets.get(calleeSocketId);
      if (!calleeSocket) {
        socket.emit('call-failed', {
          callId,
          reason: 'User not connected'
        });
        return;
      }

      // Create call record
      const callee = await User.findOne({ uid: calleeId });
      if (!callee) {
        socket.emit('call-failed', {
          callId,
          reason: 'User not found'
        });
        return;
      }

      const call = new Call({
        callId,
        caller: socket.user._id,
        callee: callee._id,
        callType,
        status: 'ringing'
      });
      await call.save();

      // Send call offer to callee
      const incomingCallData = {
        callId,
        callerId,
        callerName: socket.user.name,
        callerAvatar: socket.user.profilePicture,
        offer,
        callType
      };
      console.log('📤 Sending incoming-call to callee:', calleeId);
      console.log('📤 Incoming call data:', JSON.stringify(incomingCallData, null, 2).substring(0, 500));
      calleeSocket.emit('incoming-call', incomingCallData);

      // Send call initiated confirmation to caller
      socket.emit('call-initiated', {
        callId,
        calleeId,
        calleeName: callee.name,
        status: 'ringing'
      });

      // Send push notification to callee
      if (callee.fcmToken) {
        try {
          await fcmService.sendCallNotification(callee.fcmToken, {
            callId,
            callerId,
            callerName: socket.user.name,
            callerAvatar: socket.user.profilePicture,
            callType,
            timestamp: new Date()
          });
        } catch (error) {
          console.error('FCM notification error:', error);
        }
      }

    } catch (error) {
      console.error('Handle call-user error:', error);
      socket.emit('call-failed', {
        callId: data.callId,
        reason: 'Internal server error'
      });
    }
  }

  /**
   * Handle answer-call event
   * @param {Object} socket - Socket instance
   * @param {Object} data - Answer data
   */
  async handleAnswerCall(socket, data) {
    try {
      const { callId, answer } = data;
      const calleeId = socket.user.uid;

      console.log('=== ANSWER-CALL EVENT ===');
      console.log(`Call answered: ${callId} by ${calleeId}`);
      console.log(`Answer present: ${answer ? 'YES' : 'NO'}`);
      if (answer) {
        console.log(`Answer type: ${answer.type}`);
        console.log(`Answer SDP length: ${answer.sdp ? answer.sdp.length : 0}`);
      }

      // Find call
      const call = await Call.findOne({ callId });
      if (!call) {
        socket.emit('call-error', {
          callId,
          reason: 'Call not found'
        });
        return;
      }

      // Update call status
      call.status = 'answered';
      await call.save();

      // Find caller socket
      const callerSocketId = this.userSockets.get(call.caller.uid);
      console.log(`📤 Looking for caller socket: ${call.caller.uid}`);
      console.log(`📤 Caller socket ID: ${callerSocketId}`);
      if (callerSocketId) {
        const callerSocket = this.io.sockets.sockets.get(callerSocketId);
        if (callerSocket) {
          const answerData = {
            callId,
            calleeId,
            answer
          };
          console.log('📤 Sending call-answered to caller');
          console.log('📤 Answer data:', JSON.stringify(answerData, null, 2).substring(0, 500));
          callerSocket.emit('call-answered', answerData);
        } else {
          console.log('❌ Caller socket not found in io.sockets.sockets');
        }
      } else {
        console.log('❌ Caller socket ID not found in userSockets map');
      }

      // Send confirmation to callee
      socket.emit('call-answer-sent', {
        callId,
        status: 'answered'
      });

    } catch (error) {
      console.error('Handle answer-call error:', error);
      socket.emit('call-error', {
        callId: data.callId,
        reason: 'Failed to answer call'
      });
    }
  }

  /**
   * Handle ice-candidate event
   * @param {Object} socket - Socket instance
   * @param {Object} data - ICE candidate data
   */
//  handleIceCandidate(socket, data) {
//    try {
//      const { callId, candidate, targetUserId } = data;
//      const senderId = socket.user.uid;
//
//      console.log(`ICE candidate: ${senderId} -> ${targetUserId}`);
//
//      // Find target user socket
//      const targetSocketId = this.userSockets.get(targetUserId);
//      if (targetSocketId) {
//        const targetSocket = this.io.sockets.sockets.get(targetSocketId);
//        if (targetSocket) {
//          targetSocket.emit('ice-candidate', {
//            callId,
//            candidate,
//            senderId
//          });
//        }
//      }
//
//    } catch (error) {
//      console.error('Handle ice-candidate error:', error);
//    }
//  }


handleIceCandidate(socket, data) {
  try {
    // Support both field name variations (frontend sends 'to' and 'roomId', backend expects 'targetUserId' and 'callId')
    const callId = data.callId || data.roomId;
    const targetUserId = data.targetUserId || data.to;
    const candidate = data.candidate;
    const senderId = socket.user.uid;

    console.log('=== ICE-CANDIDATE EVENT ===');
    console.log(`ICE candidate: ${senderId} -> ${targetUserId}`);
    console.log(`Call ID: ${callId}`);
    console.log(`Raw data keys: ${Object.keys(data).join(', ')}`);
    console.log(`Candidate present: ${candidate ? 'YES' : 'NO'}`);
    if (candidate) {
      console.log(`Candidate: ${JSON.stringify(candidate).substring(0, 200)}`);
    }

    // Validate required fields
    if (!targetUserId) {
      console.log('❌ CRITICAL: targetUserId is undefined! Raw data:', JSON.stringify(data));
      return;
    }

    // Get the target socket directly
    const targetSocketId = this.userSockets.get(targetUserId);
    console.log(`Target socket ID from map: ${targetSocketId}`);
    
    if (targetSocketId) {
      const targetSocket = this.io.sockets.sockets.get(targetSocketId);
      if (targetSocket) {
        const iceData = {
          callId,
          candidate,
          senderId
        };
        console.log('📤 Sending ice-candidate to target user');
        console.log('📤 ICE data:', JSON.stringify(iceData, null, 2).substring(0, 300));
        targetSocket.emit('ice-candidate', iceData);
        console.log(`✅ ICE candidate sent to ${targetUserId}`);
      } else {
        console.log(`❌ Target socket not found in io.sockets.sockets for ${targetUserId}`);
      }
    } else {
      console.log(`❌ Target socket ID not found in userSockets map for ${targetUserId}`);
    }

  } catch (error) {
    console.error('❌ Handle ice-candidate error:', error);
  }
}


  /**
   * Handle end-call event
   * @param {Object} socket - Socket instance
   * @param {Object} data - End call data
   */
  async handleEndCall(socket, data) {
    try {
      const { callId } = data;
      const userId = socket.user.uid;

      console.log(`Call ended: ${callId} by ${userId}`);

      // Find call
      const call = await Call.findOne({ callId })
        .populate('caller', 'uid name fcmToken')
        .populate('callee', 'uid name fcmToken');

      if (!call) {
        socket.emit('call-error', {
          callId,
          reason: 'Call not found'
        });
        return;
      }

      // Update call status
      call.status = 'ended';
      call.endTime = new Date();
      call.duration = Math.floor((call.endTime - call.startTime) / 1000);
      await call.save();

      // Notify both parties
      const otherPartyId = call.caller.uid === userId ? call.callee.uid : call.caller.uid;
      const otherPartySocketId = this.userSockets.get(otherPartyId);
      
      if (otherPartySocketId) {
        const otherPartySocket = this.io.sockets.sockets.get(otherPartySocketId);
        if (otherPartySocket) {
          otherPartySocket.emit('call-ended', {
            callId,
            duration: call.duration,
            endedBy: userId
          });
        }
      }

      // Send confirmation to caller
      socket.emit('call-end-confirmed', {
        callId,
        duration: call.duration
      });

      // Send push notification
      const otherParty = call.caller.uid === userId ? call.callee : call.caller;
      if (otherParty.fcmToken) {
        try {
          await fcmService.sendCallEndedNotification(otherParty.fcmToken, {
            callId,
            callerId: call.caller.uid,
            callerName: call.caller.name,
            callerAvatar: call.caller.profilePicture,
            duration: call.duration
          });
        } catch (error) {
          console.error('FCM notification error:', error);
        }
      }

    } catch (error) {
      console.error('Handle end-call error:', error);
      socket.emit('call-error', {
        callId: data.callId,
        reason: 'Failed to end call'
      });
    }
  }

  /**
   * Handle reject-call event
   * @param {Object} socket - Socket instance
   * @param {Object} data - Reject call data
   */
  async handleRejectCall(socket, data) {
    try {
      const { callId } = data;
      const calleeId = socket.user.uid;

      console.log(`Call rejected: ${callId} by ${calleeId}`);

      // Find call
      const call = await Call.findOne({ callId })
        .populate('caller', 'uid name fcmToken');
      
      if (!call) {
        socket.emit('call-error', {
          callId,
          reason: 'Call not found'
        });
        return;
      }

      // Update call status
      call.status = 'rejected';
      await call.save();

      // Notify caller
      const callerSocketId = this.userSockets.get(call.caller.uid);
      if (callerSocketId) {
        const callerSocket = this.io.sockets.sockets.get(callerSocketId);
        if (callerSocket) {
          callerSocket.emit('call-rejected', {
            callId,
            calleeId
          });
        }
      }

      // Send confirmation to callee
      socket.emit('call-reject-confirmed', {
        callId
      });

    } catch (error) {
      console.error('Handle reject-call error:', error);
      socket.emit('call-error', {
        callId: data.callId,
        reason: 'Failed to reject call'
      });
    }
  }

  /**
   * Handle user typing event
   * @param {Object} socket - Socket instance
   * @param {Object} data - Typing data
   */
  handleUserTyping(socket, data) {
    try {
      const { callId, isTyping } = data;
      const userId = socket.user.uid;

      // Find call to get other party
      Call.findOne({ callId })
        .then(call => {
          if (!call) return;

          const otherPartyId = call.caller.uid === userId ? call.callee.uid : call.caller.uid;
          const otherPartySocketId = this.userSockets.get(otherPartyId);
          
          if (otherPartySocketId) {
            const otherPartySocket = this.io.sockets.sockets.get(otherPartySocketId);
            if (otherPartySocket) {
              otherPartySocket.emit('user-typing', {
                callId,
                userId,
                isTyping
              });
            }
          }
        })
        .catch(error => {
          console.error('Handle user-typing error:', error);
        });

    } catch (error) {
      console.error('Handle user-typing error:', error);
    }
  }

  /**
   * Handle disconnect event
   * @param {Object} socket - Socket instance
   */
  async handleDisconnect(socket) {
    try {
      const userId = socket.user.uid;
      console.log(`User disconnected: ${userId} (${socket.id})`);

      // Remove user socket mapping
      this.userSockets.delete(userId);
      
      // Update user offline status
      await this.updateUserStatus(userId, false);

    } catch (error) {
      console.error('Handle disconnect error:', error);
    }
  }

  /**
   * Update user online status
   * @param {String} userId - User ID
   * @param {Boolean} isOnline - Online status
   */
  async updateUserStatus(userId, isOnline) {
    try {
      await User.findOneAndUpdate(
        { uid: userId },
        { 
          isOnline,
          lastSeen: new Date()
        }
      );
    } catch (error) {
      console.error('Update user status error:', error);
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
   * Get user socket by ID
   * @param {String} userId - User ID
   * @returns {Object|null} Socket instance or null
   */
  getUserSocket(userId) {
    const socketId = this.userSockets.get(userId);
    return socketId ? this.io.sockets.sockets.get(socketId) : null;
  }
}

module.exports = CallSocketHandler;

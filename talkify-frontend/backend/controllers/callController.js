const Call = require('../models/Call');
const User = require('../models/User');
const fcmService = require('../services/fcmService');
const { v4: uuidv4 } = require('uuid');

/**
 * Call Controller
 * Handles call signaling logic and call management
 */
class CallController {
  /**
   * Initiate a call
   * POST /api/calls/initiate
   */
  async initiateCall(req, res) {
    try {
      const { calleeId, callType = 'audio' } = req.body;
      const caller = req.user;

      // Validate callee
      if (!calleeId) {
        return res.status(400).json({
          success: false,
          message: 'Callee ID is required'
        });
      }

      if (calleeId === caller.uid) {
        return res.status(400).json({
          success: false,
          message: 'Cannot call yourself'
        });
      }

      // Find callee
      const callee = await User.findOne({ uid: calleeId });
      if (!callee) {
        return res.status(404).json({
          success: false,
          message: 'User not found'
        });
      }

      // Generate unique call ID
      const callId = uuidv4();

      // Create call record
      const call = new Call({
        callId,
        caller: caller._id,
        callee: callee._id,
        callType,
        status: 'initiated'
      });
      await call.save();

      // Send push notification to callee
      if (callee.fcmToken) {
        try {
          await fcmService.sendCallNotification(callee.fcmToken, {
            callId,
            callerId: caller.uid,
            callerName: caller.name,
            callerAvatar: caller.profilePicture,
            callType,
            timestamp: new Date()
          });
        } catch (error) {
          console.error('FCM notification error:', error);
          // Don't fail call initiation if FCM fails
        }
      }

      res.status(200).json({
        success: true,
        message: 'Call initiated successfully',
        data: {
          callId,
          callee: {
            uid: callee.uid,
            name: callee.name,
            phone: callee.phone,
            isOnline: callee.isOnline
          },
          callType,
          status: 'initiated'
        }
      });

    } catch (error) {
      console.error('Initiate call error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to initiate call',
        error: error.message
      });
    }
  }

  /**
   * End a call
   * POST /api/calls/end
   */
  async endCall(req, res) {
    try {
      const { callId } = req.body;
      const user = req.user;

      if (!callId) {
        return res.status(400).json({
          success: false,
          message: 'Call ID is required'
        });
      }

      // Find call
      const call = await Call.findOne({ callId })
        .populate('caller', 'uid name fcmToken')
        .populate('callee', 'uid name fcmToken');

      if (!call) {
        return res.status(404).json({
          success: false,
          message: 'Call not found'
        });
      }

      // Check if user is part of this call
      if (call.caller.uid !== user.uid && call.callee.uid !== user.uid) {
        return res.status(403).json({
          success: false,
          message: 'Not authorized to end this call'
        });
      }

      // Update call status
      call.status = 'ended';
      call.endTime = new Date();
      call.duration = Math.floor((call.endTime - call.startTime) / 1000);
      await call.save();

      // Send notification to the other party
      const otherParty = call.caller.uid === user.uid ? call.callee : call.caller;
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

      res.status(200).json({
        success: true,
        message: 'Call ended successfully',
        data: {
          callId,
          duration: call.duration,
          endTime: call.endTime
        }
      });

    } catch (error) {
      console.error('End call error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to end call',
        error: error.message
      });
    }
  }

  /**
   * Get call history
   * GET /api/calls/history
   */
  async getCallHistory(req, res) {
    try {
      const { page = 1, limit = 20, callType } = req.query;
      const user = req.user;

      // Build query
      let query = {
        $or: [
          { caller: user._id },
          { callee: user._id }
        ]
      };

      if (callType) {
        query.callType = callType;
      }

      // Calculate pagination
      const skip = (parseInt(page) - 1) * parseInt(limit);

      // Get call history
      const calls = await Call.find(query)
        .populate('caller', 'uid name phone profilePicture')
        .populate('callee', 'uid name phone profilePicture')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(parseInt(limit));

      // Get total count
      const totalCalls = await Call.countDocuments(query);
      const totalPages = Math.ceil(totalCalls / parseInt(limit));

      res.status(200).json({
        success: true,
        data: {
          calls,
          pagination: {
            currentPage: parseInt(page),
            totalPages,
            totalCalls,
            hasNext: parseInt(page) < totalPages,
            hasPrev: parseInt(page) > 1
          }
        }
      });

    } catch (error) {
      console.error('Get call history error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to fetch call history',
        error: error.message
      });
    }
  }

  /**
   * Get call details
   * GET /api/calls/:callId
   */
  async getCallDetails(req, res) {
    try {
      const { callId } = req.params;
      const user = req.user;

      const call = await Call.findOne({ callId })
        .populate('caller', 'uid name phone profilePicture')
        .populate('callee', 'uid name phone profilePicture');

      if (!call) {
        return res.status(404).json({
          success: false,
          message: 'Call not found'
        });
      }

      // Check if user is part of this call
      if (call.caller.uid !== user.uid && call.callee.uid !== user.uid) {
        return res.status(403).json({
          success: false,
          message: 'Not authorized to view this call'
        });
      }

      res.status(200).json({
        success: true,
        data: { call }
      });

    } catch (error) {
      console.error('Get call details error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to fetch call details',
        error: error.message
      });
    }
  }

  /**
   * Update call status
   * PUT /api/calls/:callId/status
   */
  async updateCallStatus(req, res) {
    try {
      const { callId } = req.params;
      const { status } = req.body;
      const user = req.user;

      const validStatuses = ['ringing', 'answered', 'ended', 'missed', 'rejected'];
      if (!validStatuses.includes(status)) {
        return res.status(400).json({
          success: false,
          message: 'Invalid call status'
        });
      }

      const call = await Call.findOne({ callId })
        .populate('caller', 'uid name fcmToken')
        .populate('callee', 'uid name fcmToken');

      if (!call) {
        return res.status(404).json({
          success: false,
          message: 'Call not found'
        });
      }

      // Check if user is part of this call
      if (call.caller.uid !== user.uid && call.callee.uid !== user.uid) {
        return res.status(403).json({
          success: false,
          message: 'Not authorized to update this call'
        });
      }

      // Update call status
      call.status = status;
      if (status === 'ended') {
        call.endTime = new Date();
        call.duration = Math.floor((call.endTime - call.startTime) / 1000);
      }
      await call.save();

      res.status(200).json({
        success: true,
        message: 'Call status updated successfully',
        data: {
          callId,
          status: call.status,
          duration: call.duration
        }
      });

    } catch (error) {
      console.error('Update call status error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to update call status',
        error: error.message
      });
    }
  }
}

module.exports = new CallController();

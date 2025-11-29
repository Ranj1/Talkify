const admin = require('firebase-admin');

/**
 * FCM Service
 * Handles Firebase Cloud Messaging for push notifications
 */
class FCMService {
  constructor() {
    this.messaging = null;
    this.initialized = false;
  }

  /**
   * Initialize FCM service
   */
  async initialize() {
    try {
      if (this.initialized) {
        return;
      }

      // Ensure Firebase Admin is initialized
      const firebaseAdmin = require('./firebaseAdminService');
      await firebaseAdmin.initialize();

      this.messaging = admin.messaging();
      this.initialized = true;
      
      console.log('FCM Service initialized successfully');
    } catch (error) {
      console.error('FCM Service initialization error:', error);
      throw error;
    }
  }

  /**
   * Send notification to single device
   * @param {String} fcmToken - FCM token
   * @param {Object} notification - Notification payload
   * @param {Object} data - Data payload
   * @returns {String} Message ID
   */
  async sendToDevice(fcmToken, notification, data = {}) {
    try {
      if (!this.initialized) {
        await this.initialize();
      }

      const message = {
        token: fcmToken,
        notification: {
          title: notification.title,
          body: notification.body,
          imageUrl: notification.imageUrl
        },
        data: {
          ...data,
          timestamp: Date.now().toString()
        },
        android: {
          priority: 'high',
          notification: {
            sound: 'default',
            channelId: 'talkify_calls'
          }
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1
            }
          }
        }
      };

      const response = await this.messaging.send(message);
      console.log('FCM message sent successfully:', response);
      return response;
    } catch (error) {
      console.error('FCM send to device error:', error);
      throw error;
    }
  }

  /**
   * Send notification to multiple devices
   * @param {Array} fcmTokens - Array of FCM tokens
   * @param {Object} notification - Notification payload
   * @param {Object} data - Data payload
   * @returns {Object} Batch response
   */
  async sendToMultipleDevices(fcmTokens, notification, data = {}) {
    try {
      if (!this.initialized) {
        await this.initialize();
      }

      const message = {
        tokens: fcmTokens,
        notification: {
          title: notification.title,
          body: notification.body,
          imageUrl: notification.imageUrl
        },
        data: {
          ...data,
          timestamp: Date.now().toString()
        },
        android: {
          priority: 'high',
          notification: {
            sound: 'default',
            channelId: 'talkify_calls'
          }
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1
            }
          }
        }
      };

      const response = await this.messaging.sendMulticast(message);
      console.log('FCM multicast sent successfully:', response);
      return response;
    } catch (error) {
      console.error('FCM send to multiple devices error:', error);
      throw error;
    }
  }

  /**
   * Send call notification
   * @param {String} fcmToken - FCM token
   * @param {Object} callData - Call information
   * @returns {String} Message ID
   */
  async sendCallNotification(fcmToken, callData) {
    const notification = {
      title: `Incoming call from ${callData.callerName}`,
      body: callData.callType === 'video' ? 'Video call' : 'Voice call',
      imageUrl: callData.callerAvatar
    };

    const data = {
      type: 'incoming_call',
      callId: callData.callId,
      callerId: callData.callerId,
      callerName: callData.callerName,
      callType: callData.callType,
      timestamp: callData.timestamp?.toString() || Date.now().toString()
    };

    return await this.sendToDevice(fcmToken, notification, data);
  }

  /**
   * Send call ended notification
   * @param {String} fcmToken - FCM token
   * @param {Object} callData - Call information
   * @returns {String} Message ID
   */
  async sendCallEndedNotification(fcmToken, callData) {
    const notification = {
      title: 'Call ended',
      body: `Call with ${callData.callerName} has ended`,
      imageUrl: callData.callerAvatar
    };

    const data = {
      type: 'call_ended',
      callId: callData.callId,
      callerId: callData.callerId,
      callerName: callData.callerName,
      duration: callData.duration?.toString() || '0',
      timestamp: Date.now().toString()
    };

    return await this.sendToDevice(fcmToken, notification, data);
  }

  /**
   * Send missed call notification
   * @param {String} fcmToken - FCM token
   * @param {Object} callData - Call information
   * @returns {String} Message ID
   */
  async sendMissedCallNotification(fcmToken, callData) {
    const notification = {
      title: 'Missed call',
      body: `Missed call from ${callData.callerName}`,
      imageUrl: callData.callerAvatar
    };

    const data = {
      type: 'missed_call',
      callId: callData.callId,
      callerId: callData.callerId,
      callerName: callData.callerName,
      callType: callData.callType,
      timestamp: callData.timestamp?.toString() || Date.now().toString()
    };

    return await this.sendToDevice(fcmToken, notification, data);
  }

  /**
   * Validate FCM token
   * @param {String} fcmToken - FCM token to validate
   * @returns {Boolean} True if valid
   */
  async validateToken(fcmToken) {
    try {
      if (!this.initialized) {
        await this.initialize();
      }

      // Send a test message to validate token
      const message = {
        token: fcmToken,
        data: {
          test: 'true'
        }
      };

      await this.messaging.send(message);
      return true;
    } catch (error) {
      console.error('FCM token validation error:', error);
      return false;
    }
  }
}

// Export singleton instance
module.exports = new FCMService();

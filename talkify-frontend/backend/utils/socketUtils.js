const socketService = require('../services/socketService');

/**
 * Socket.IO Utility Functions
 * Helper functions for Socket.IO operations
 */
class SocketUtils {
  /**
   * Get online users count
   * @returns {Number} Online users count
   */
  static getOnlineUsersCount() {
    return socketService.getOnlineUsersCount();
  }

  /**
   * Get online users list
   * @returns {Array} Array of online user IDs
   */
  static getOnlineUsers() {
    return socketService.getOnlineUsers();
  }

  /**
   * Check if user is online
   * @param {String} uid - User ID
   * @returns {Boolean} Online status
   */
  static isUserOnline(uid) {
    return socketService.isUserOnline(uid);
  }

  /**
   * Send message to specific user
   * @param {String} uid - User ID
   * @param {String} event - Event name
   * @param {Object} data - Event data
   * @returns {Boolean} Success status
   */
  static sendToUser(uid, event, data) {
    return socketService.sendToUser(uid, event, data);
  }

  /**
   * Send message to room
   * @param {String} roomId - Room ID
   * @param {String} event - Event name
   * @param {Object} data - Event data
   */
  static sendToRoom(roomId, event, data) {
    socketService.sendToRoom(roomId, event, data);
  }

  /**
   * Broadcast message to all connected users
   * @param {String} event - Event name
   * @param {Object} data - Event data
   */
  static broadcast(event, data) {
    socketService.broadcast(event, data);
  }

  /**
   * Get active calls count
   * @returns {Number} Active calls count
   */
  static getActiveCallsCount() {
    return socketService.activeCalls.size;
  }

  /**
   * Get active calls list
   * @returns {Array} Array of active call data
   */
  static getActiveCalls() {
    return Array.from(socketService.activeCalls.values());
  }

  /**
   * Get call by ID
   * @param {String} callId - Call ID
   * @returns {Object|null} Call data or null
   */
  static getCall(callId) {
    return socketService.activeCalls.get(callId) || null;
  }

  /**
   * Get user's active calls
   * @param {String} uid - User ID
   * @returns {Array} Array of user's active calls
   */
  static getUserActiveCalls(uid) {
    return Array.from(socketService.activeCalls.values())
      .filter(call => call.participants.has(uid));
  }

  /**
   * Get room members
   * @param {String} roomId - Room ID
   * @returns {Array} Array of room member UIDs
   */
  static getRoomMembers(roomId) {
    const roomUsers = socketService.roomUsers.get(roomId);
    return roomUsers ? Array.from(roomUsers) : [];
  }

  /**
   * Get server statistics
   * @returns {Object} Server statistics
   */
  static getServerStats() {
    return {
      onlineUsers: socketService.getOnlineUsersCount(),
      activeCalls: socketService.activeCalls.size,
      activeRooms: socketService.roomUsers.size,
      uptime: process.uptime(),
      memoryUsage: process.memoryUsage(),
      timestamp: new Date().toISOString()
    };
  }
}

module.exports = SocketUtils;

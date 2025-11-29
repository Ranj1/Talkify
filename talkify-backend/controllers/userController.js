const User = require('../models/User');
const fcmService = require('../services/fcmService');

/**
 * User Controller
 * Handles user related operations
 */
class UserController {
  /**
   * Get user list
   * GET /api/users
   */
  async getUsers(req, res) {
    try {
      const { page = 1, limit = 20, search = '', onlineOnly = false } = req.query;
      const currentUser = req.user;

      // Build query
      let query = {
        uid: { $ne: currentUser.uid } // Exclude current user
      };

      // Add search filter
      if (search) {
        query.$or = [
          { name: { $regex: search, $options: 'i' } },
          { phone: { $regex: search, $options: 'i' } }
        ];
      }

      // Add online filter
      if (onlineOnly === 'true') {
        query.isOnline = true;
      }

      // Calculate pagination
      const skip = (parseInt(page) - 1) * parseInt(limit);

      // Get users with pagination
      const users = await User.find(query)
        .select('uid name phone isOnline lastSeen profilePicture')
        .sort({ isOnline: -1, lastSeen: -1 })
        .skip(skip)
        .limit(parseInt(limit));

      // Get total count
      const totalUsers = await User.countDocuments(query);
      const totalPages = Math.ceil(totalUsers / parseInt(limit));

      res.status(200).json({
        success: true,
        data: {
          users,
          pagination: {
            currentPage: parseInt(page),
            totalPages,
            totalUsers,
            hasNext: parseInt(page) < totalPages,
            hasPrev: parseInt(page) > 1
          }
        }
      });

    } catch (error) {
      console.error('Get users error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to fetch users',
        error: error.message
      });
    }
  }

  /**
   * Get user by ID
   * GET /api/users/:userId
   */
  async getUserById(req, res) {
    try {
      const { userId } = req.params;
      const currentUser = req.user;

      // Don't allow users to get their own info through this endpoint
      if (userId === currentUser.uid) {
        return res.status(400).json({
          success: false,
          message: 'Use profile endpoint to get your own information'
        });
      }

      const user = await User.findOne({ uid: userId })
        .select('uid name phone isOnline lastSeen profilePicture');

      if (!user) {
        return res.status(404).json({
          success: false,
          message: 'User not found'
        });
      }

      res.status(200).json({
        success: true,
        data: { user }
      });

    } catch (error) {
      console.error('Get user by ID error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to fetch user',
        error: error.message
      });
    }
  }

  /**
   * Update FCM token
   * PUT /api/users/fcm-token
   */
  async updateFCMToken(req, res) {
    try {
      const { fcmToken } = req.body;
      const user = req.user;

      if (!fcmToken) {
        return res.status(400).json({
          success: false,
          message: 'FCM token is required'
        });
      }

      // Validate FCM token
      const isValidToken = await fcmService.validateToken(fcmToken);
      if (!isValidToken) {
        return res.status(400).json({
          success: false,
          message: 'Invalid FCM token'
        });
      }

      // Update user's FCM token
      user.fcmToken = fcmToken;
      await user.save();

      res.status(200).json({
        success: true,
        message: 'FCM token updated successfully'
      });

    } catch (error) {
      console.error('Update FCM token error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to update FCM token',
        error: error.message
      });
    }
  }

  /**
   * Update user profile
   * PUT /api/users/profile
   */
  async updateProfile(req, res) {
    try {
      const { name, profilePicture } = req.body;
      const user = req.user;

      // Update allowed fields
      if (name) user.name = name;
      if (profilePicture) user.profilePicture = profilePicture;

      await user.save();

      res.status(200).json({
        success: true,
        message: 'Profile updated successfully',
        data: {
          user: {
            uid: user.uid,
            name: user.name,
            phone: user.phone,
            isOnline: user.isOnline,
            profilePicture: user.profilePicture
          }
        }
      });

    } catch (error) {
      console.error('Update profile error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to update profile',
        error: error.message
      });
    }
  }

  /**
   * Get current user profile
   * GET /api/users/profile
   */
  async getProfile(req, res) {
    try {
      const user = req.user;

      res.status(200).json({
        success: true,
        data: {
          user: {
            uid: user.uid,
            name: user.name,
            phone: user.phone,
            isOnline: user.isOnline,
            profilePicture: user.profilePicture,
            lastSeen: user.lastSeen,
            createdAt: user.createdAt
          }
        }
      });

    } catch (error) {
      console.error('Get profile error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to fetch profile',
        error: error.message
      });
    }
  }

  /**
   * Update online status
   * PUT /api/users/status
   */
  async updateStatus(req, res) {
    try {
      const { isOnline } = req.body;
      const user = req.user;

      user.isOnline = isOnline;
      user.lastSeen = new Date();
      await user.save();

      res.status(200).json({
        success: true,
        message: 'Status updated successfully',
        data: {
          isOnline: user.isOnline,
          lastSeen: user.lastSeen
        }
      });

    } catch (error) {
      console.error('Update status error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to update status',
        error: error.message
      });
    }
  }
}

module.exports = new UserController();

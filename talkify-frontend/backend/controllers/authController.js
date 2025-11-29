const User = require('../models/User');
const firebaseAdmin = require('../services/firebaseAdminService');
const fcmService = require('../services/fcmService');
const { generateTokenPair } = require('../utils/jwtUtils');

/**
 * Auth Controller
 * Handles authentication related operations
 */
class AuthController {
  /**
   * Verify OTP and login user
   * POST /api/auth/login
   */
  async login(req, res) {
    try {
      const { idToken, uid, fcmToken, phone, name } = req.body;
  
      // ✅ Validate required fields
      if (!idToken || !uid) {
        return res.status(400).json({
          success: false,
          message: 'ID token and UID are required',
        });
      }
  
      // ✅ Verify Firebase ID token
      let firebaseUser;
      try {
        firebaseUser = await firebaseAdmin.verifyIdToken(idToken);
  
        if (!firebaseUser.phone) {
          return res.status(400).json({
            success: false,
            message: 'Phone number not verified with Firebase',
          });
        }
      } catch (error) {
        console.error('Firebase ID token verification error:', error);
        return res.status(401).json({
          success: false,
          message: 'Invalid or expired Firebase ID token',
        });
      }
  
      // ✅ Find or create user in DB
      let user = await User.findOne({ uid });
  
      if (!user) {
        user = new User({
          uid,
          name: name || firebaseUser.name || 'User',
          phone: phone || firebaseUser.phone_number,
          fcmToken: fcmToken || null,
          isOnline: true,
        });
        await user.save();
      } else {
        // ✅ Update existing user
        user.name = name || user.name;
        user.phone = phone || user.phone;
        user.fcmToken = fcmToken || user.fcmToken;
        user.isOnline = true;
        user.lastSeen = new Date();
        await user.save();
      }
  
      // ✅ Generate JWT tokens
      const tokens = generateTokenPair(user);
  
      // ✅ Send FCM notification (optional)
      if (fcmToken) {``
        try {
          await fcmService.sendToDevice(
            fcmToken,
            {
              title: 'Welcome to Talkify App',
              body: 'You have successfully logged in!',
            },
            { type: 'login_success' }
          );
        } catch (error) {
          console.error('⚠️ FCM notification error:', error);
        }
      }
  
      // ✅ Send response
      return res.status(200).json({
        success: true,
        message: 'Login successful',
        data: {
          user: {
            uid: user.uid,
            name: user.name,
            phone: user.phone,
            isOnline: user.isOnline,
            profilePicture: user.profilePicture || null,
          },
          ...tokens,
        },
      });
  
    } catch (error) {
      console.error('Login error:', error);
      return res.status(500).json({
        success: false,
        message: 'Login failed',
        error: error.message,
      });
    }
  }
  

  /**
   * Refresh JWT token
   * POST /api/auth/refresh
   */
  async refreshToken(req, res) {
    try {
      const { refreshToken } = req.body;

      if (!refreshToken) {
        return res.status(400).json({
          success: false,
          message: 'Refresh token is required'
        });
      }

      // Verify refresh token
      const { verifyToken } = require('../utils/jwtUtils');
      const decoded = verifyToken(refreshToken, process.env.JWT_REFRESH_SECRET || process.env.JWT_SECRET);

      if (decoded.type !== 'refresh') {
        return res.status(401).json({
          success: false,
          message: 'Invalid refresh token'
        });
      }

      // Find user
      const user = await User.findOne({ uid: decoded.uid });
      if (!user) {
        return res.status(401).json({
          success: false,
          message: 'User not found'
        });
      }

      // Generate new tokens
      const tokens = generateTokenPair(user);

      res.status(200).json({
        success: true,
        message: 'Token refreshed successfully',
        data: tokens
      });

    } catch (error) {
      console.error('Refresh token error:', error);
      res.status(401).json({
        success: false,
        message: 'Invalid refresh token'
      });
    }
  }

  /**
   * Logout user
   * POST /api/auth/logout
   */
  async logout(req, res) {
    try {
      const user = req.user;

      // Update user status
      user.isOnline = false;
      user.lastSeen = new Date();
      await user.save();

      res.status(200).json({
        success: true,
        message: 'Logout successful'
      });

    } catch (error) {
      console.error('Logout error:', error);
      res.status(500).json({
        success: false,
        message: 'Logout failed'
      });
    }
  }

  /**
   * Verify JWT token
   * GET /api/auth/verify
   */
  async verifyToken(req, res) {
    try {
      const user = req.user;

      res.status(200).json({
        success: true,
        message: 'Token is valid',
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
      console.error('Token verification error:', error);
      res.status(500).json({
        success: false,
        message: 'Token verification failed'
      });
    }
  }
}

module.exports = new AuthController();

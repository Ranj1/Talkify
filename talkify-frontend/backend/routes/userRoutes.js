const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const { authenticateToken } = require('../middleware/authMiddleware');

/**
 * User Routes
 * Handles user related endpoints
 */

// All routes require authentication
router.use(authenticateToken);

// User management routes
router.get('/getUserList', userController.getUsers);
router.get('/profile', userController.getProfile);
router.put('/profile', userController.updateProfile);
router.put('/fcm-token', userController.updateFCMToken);
router.put('/status', userController.updateStatus);
router.get('/:userId', userController.getUserById);

module.exports = router;

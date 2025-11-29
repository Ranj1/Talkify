const express = require('express');
const router = express.Router();
const callController = require('../controllers/callController');
const { authenticateToken } = require('../middleware/authMiddleware');

/**
 * Call Routes
 * Handles call signaling and management endpoints
 */

// All routes require authentication
router.use(authenticateToken);

// Call management routes
router.post('/initiate', callController.initiateCall);
router.post('/end', callController.endCall);
router.get('/history', callController.getCallHistory);
router.get('/:callId', callController.getCallDetails);
router.put('/:callId/status', callController.updateCallStatus);

module.exports = router;

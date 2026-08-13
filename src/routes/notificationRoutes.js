const express = require('express');
const router = express.Router();
const notificationController = require('../controllers/notificationController');
const { authenticateToken } = require('../middleware/auth');

router.use(authenticateToken);

router.get('/notifications', notificationController.getNotifications);
router.get('/notifications/unread', notificationController.getUnreadNotifications);
router.put('/notifications/:id/read', notificationController.markAsRead);
router.put('/notifications/read-all', notificationController.markAllAsRead);
router.delete('/notifications/:id', notificationController.deleteNotification);

// FCM Device Tokens
router.post('/devices/register', notificationController.registerDevice);
router.delete('/devices/:id', notificationController.unregisterDevice);

module.exports = router;

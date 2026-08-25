const express = require('express');
const router = express.Router();
const notificationController = require('../controllers/notificationController');
const { authenticateToken } = require('../middleware/auth');

router.use(authenticateToken);

router.get('/', notificationController.getNotifications);
router.get('/unread', notificationController.getUnreadNotifications);
router.put('/:id/read', notificationController.markAsRead);
router.put('/read-all', notificationController.markAllAsRead);
router.delete('/:id', notificationController.deleteNotification);

// FCM Device Tokens
router.post('/devices/register', notificationController.registerDevice);
router.delete('/devices/:id', notificationController.unregisterDevice);

module.exports = router;

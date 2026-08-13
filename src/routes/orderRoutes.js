const express = require('express');
const router = express.Router();
const orderController = require('../controllers/orderController');
const reviewController = require('../controllers/reviewController');
const { authenticateToken, authorizeRoles } = require('../middleware/auth');
const { ROLES } = require('../constants/enums');

router.use(authenticateToken);

// Core order management
router.post('/', orderController.createOrder);
router.get('/', orderController.getOrders);
router.get('/history', orderController.getCompletedOrders);
router.get('/active', orderController.getActiveOrders);
router.get('/cancelled', orderController.getCancelledOrders);
router.get('/repeat-orders', orderController.getOrders); // Helper route

router.get('/:orderId', orderController.getOrderById);
router.get('/:orderId/status', orderController.getOrderStatus);
router.get('/:orderId/timeline', orderController.getOrderTimeline);
router.get('/:orderId/estimated-time', orderController.getEstimatedTime);
router.get('/:orderId/tracking', orderController.getOrderTracking);
router.get('/:orderId/cancellation-reasons', orderController.getCancellationReasons);

router.post('/:orderId/cancel', orderController.cancelOrder);
router.post('/:orderId/confirm-receipt', orderController.confirmReceipt);
router.post('/:orderId/repeat', orderController.repeatOrder);

// Reviews attached to order
router.post('/:orderId/review', reviewController.submitReview);
router.get('/:orderId/review', reviewController.getOrderReview);

module.exports = router;

const express = require('express');
const router = express.Router();
const deliveryController = require('../controllers/deliveryController');
const { authenticateToken, authorizeRoles } = require('../middleware/auth');
const { ROLES } = require('../constants/enums');

// Public delivery login
router.post('/auth/login', deliveryController.deliveryLogin);

// Protected delivery routes
router.use(authenticateToken);
router.use(authorizeRoles(ROLES.DELIVERY, ROLES.ADMIN, ROLES.SHOPKEEPER));

router.get('/orders', deliveryController.getDeliveryOrders);
router.get('/orders/assigned', deliveryController.getAssignedOrders);
router.get('/orders/:orderId', deliveryController.getDeliveryOrderById);
router.post('/orders/:orderId/accept', deliveryController.acceptDelivery);
router.post('/orders/:orderId/picked-up', deliveryController.markPickedUp);
router.post('/orders/:orderId/out-for-delivery', deliveryController.markOutForDelivery);
router.post('/orders/:orderId/delivered', deliveryController.markDelivered);

router.get('/:deliveryId/tracking', deliveryController.getDeliveryTracking);
router.put('/:deliveryId/status', deliveryController.updateDeliveryStatus);

module.exports = router;

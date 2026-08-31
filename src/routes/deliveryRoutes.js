const express = require('express');
const router = express.Router();
const deliveryController = require('../controllers/deliveryController');
const { authenticateToken, authorizeRoles } = require('../middleware/auth');
const { ROLES } = require('../constants/enums');

// Public Delivery Partner Login
router.post('/auth/login', deliveryController.deliveryLogin);
router.post('/login', deliveryController.deliveryLogin);

// Protected Delivery Routes
router.use(authenticateToken);
router.use(authorizeRoles(ROLES.DELIVERY, ROLES.ADMIN, ROLES.SHOPKEEPER));

// Rider Profile & Status
router.get('/profile', deliveryController.getDeliveryProfile);
router.put('/status', deliveryController.updateOnlineStatus);

// Trip Queues
router.get('/available-trips', deliveryController.getAvailableTrips);
router.get('/assigned', deliveryController.getAssignedOrders);
router.get('/completed', deliveryController.getCompletedTrips);
router.get('/orders', deliveryController.getDeliveryOrders);
router.get('/orders/assigned', deliveryController.getAssignedOrders);
router.get('/orders/:orderId', deliveryController.getDeliveryOrderById);

// Trip Actions
router.post('/group/accept', deliveryController.acceptGroupDelivery);
router.post('/orders/:orderId/accept', deliveryController.acceptDelivery);
router.post('/orders/:orderId/pickup', deliveryController.markPickedUp);
router.post('/orders/:orderId/picked-up', deliveryController.markPickedUp);
router.post('/orders/:orderId/out-for-delivery', deliveryController.markOutForDelivery);
router.post('/orders/:orderId/location', deliveryController.updateLocation);
router.post('/location', deliveryController.updateLocation);
router.post('/orders/:orderId/deliver', deliveryController.markDelivered);
router.post('/orders/:orderId/delivered', deliveryController.markDelivered);

// Live Tracking & Earnings
router.get('/tracking/:deliveryId', deliveryController.getDeliveryTracking);
router.get('/:deliveryId/tracking', deliveryController.getDeliveryTracking);
router.put('/:deliveryId/status', deliveryController.updateDeliveryStatus);
router.get('/earnings', deliveryController.getEarnings);

// Cashout & Wallet
router.post('/cashout', deliveryController.requestCashout);
router.get('/cashouts', deliveryController.getCashouts);

// Shifts & Scheduling
router.get('/shifts', deliveryController.getShiftSlots);
router.post('/shifts/:shiftId/toggle', deliveryController.toggleShiftBooking);

// Emergency & Incidents
router.post('/incident', deliveryController.reportIncident);

// Leaderboard & Community
router.get('/leaderboard', deliveryController.getLeaderboard);

// Rider Expenses
router.get('/expenses', deliveryController.getExpenses);
router.post('/expenses', deliveryController.addExpense);

module.exports = router;

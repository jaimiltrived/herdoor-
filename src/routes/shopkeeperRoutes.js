const express = require('express');
const router = express.Router();
const shopkeeperController = require('../controllers/shopkeeperController');
const { authenticateToken, authorizeRoles } = require('../middleware/auth');
const { ROLES } = require('../constants/enums');

router.use(authenticateToken);
router.use(authorizeRoles(ROLES.SHOPKEEPER, ROLES.ADMIN));

// Profile & Mill Details
router.get('/profile', shopkeeperController.getProfile);
router.put('/profile', shopkeeperController.updateProfile);

// Dashboard & Revenue
router.get('/dashboard', shopkeeperController.getDashboard);
router.get('/orders/today', shopkeeperController.getTodayOrders);
router.get('/orders/pending', shopkeeperController.getPendingOrders);
router.get('/orders/new', shopkeeperController.getNewOrders);
router.get('/orders/active', shopkeeperController.getActiveOrders);
router.get('/orders/completed', shopkeeperController.getCompletedOrders);
router.get('/revenue', shopkeeperController.getRevenue);

// Order Acceptance & Completion
router.post('/orders/:orderId/accept', shopkeeperController.acceptOrder);
router.post('/orders/:orderId/reject', shopkeeperController.rejectOrder);
router.put('/orders/:orderId/completion-time', shopkeeperController.setCompletionTime);

// Processing State Machine Transitions
router.post('/orders/:orderId/start', shopkeeperController.startProcessing);
router.post('/orders/:orderId/processing', shopkeeperController.startProcessing);
router.post('/orders/:orderId/packing', shopkeeperController.startPacking);
router.post('/orders/:orderId/ready', shopkeeperController.markReady);
router.post('/orders/:orderId/handover', shopkeeperController.handoverDelivery);
router.post('/orders/:orderId/complete', shopkeeperController.completeOrder);

// Inventory Management
router.get('/inventory', shopkeeperController.getInventory);
router.get('/inventory/low-stock', shopkeeperController.getLowStock);
router.get('/inventory/:id', shopkeeperController.getInventoryById);
router.post('/inventory', shopkeeperController.createInventory);
router.put('/inventory/:id', shopkeeperController.updateInventory);
router.delete('/inventory/:id', shopkeeperController.deleteInventory);
router.post('/inventory/:id/stock-in', shopkeeperController.stockIn);
router.post('/inventory/:id/stock-out', shopkeeperController.stockOut);

// Service & Mill Availability
router.get('/services', shopkeeperController.getServices);
router.put('/services', shopkeeperController.updateServices);
router.put('/services/:serviceId', shopkeeperController.updateServices);
router.get('/availability', shopkeeperController.getAvailability);
router.put('/availability', shopkeeperController.updateAvailability);
router.put('/working-hours', shopkeeperController.updateWorkingHours);

module.exports = router;

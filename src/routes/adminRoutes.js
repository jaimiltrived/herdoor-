const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');
const { authenticateToken, authorizeRoles } = require('../middleware/auth');
const { ROLES } = require('../constants/enums');

// Admin authentication & authorization
router.use(authenticateToken);
router.use(authorizeRoles(ROLES.ADMIN, ROLES.SHOPKEEPER));

// Platform Dashboard
router.get('/dashboard', adminController.getDashboardMetrics);

// Flour Mills Management
router.get('/mills', adminController.getMills);
router.post('/mills', adminController.createMill);
router.put('/mills/:id', adminController.updateMill);
router.delete('/mills/:id', adminController.deleteMill);

// Merchant Applications & Onboarding Approvals
router.get('/merchant-applications', adminController.getMerchantApplications);
router.put('/merchant-applications/:id/approve', adminController.approveMerchantApplication);
router.put('/merchant-applications/:id/reject', adminController.rejectMerchantApplication);

// Fleet & Delivery Riders
router.get('/riders', adminController.getRiders);
router.put('/riders/:id/status', adminController.updateRiderStatus);

// Wholesalers & Grain Depot
router.get('/wholesalers', adminController.getWholesalers);
router.post('/wholesalers', adminController.createWholesaler);

// Master Orders Ledger
router.get('/orders', adminController.getOrders);
router.put('/orders/:id/status', adminController.updateOrderStatus);

// Citizens / Customers
router.get('/citizens', adminController.getCitizens);
router.post('/citizens', adminController.createCitizen);
router.put('/citizens/:id', adminController.updateCitizen);
router.delete('/citizens/:id', adminController.deleteCitizen);

// Platform Security, Fraud, Analytics & Financial Audits
router.get('/security', adminController.getSecurityAudits);
router.get('/fraud', adminController.getFraudAlerts);
router.get('/analytics', adminController.getAnalytics);
router.get('/withdrawals', adminController.getWithdrawals);
router.get('/refunds', adminController.getRefunds);

module.exports = router;

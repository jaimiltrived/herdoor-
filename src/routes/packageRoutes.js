const express = require('express');
const router = express.Router();
const packageController = require('../controllers/packageController');
const { authenticateToken } = require('../middleware/auth');

// All package routes require authentication
router.use(authenticateToken);

// Scan QR token / Package code
router.post('/scan', packageController.scanPackage);

// Get packages for an order
router.get('/order/:orderId', packageController.getOrderPackages);

module.exports = router;

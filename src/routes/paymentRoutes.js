const express = require('express');
const router = express.Router();
const paymentController = require('../controllers/paymentController');
const { authenticateToken } = require('../middleware/auth');

router.use(authenticateToken);

router.post('/create', paymentController.createPayment);
router.post('/verify', paymentController.verifyPayment);
router.get('/:paymentId', paymentController.getPaymentById);
router.get('/order/:orderId', paymentController.getOrderPayment);
router.post('/:paymentId/refund', paymentController.refundPayment);
router.get('/:paymentId/refund-status', paymentController.getRefundStatus);

module.exports = router;

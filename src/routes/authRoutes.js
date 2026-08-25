const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const { authenticateToken } = require('../middleware/auth');

// Registration & Login
router.post('/register', authController.register);
router.post('/login', authController.login);
router.post('/logout', authController.logout);

// Mobile OTP Login
router.post('/send-otp', authController.sendLoginOtp);
router.post('/login-otp', authController.loginWithOtp);

// Password Management & OTP Flows
router.post('/forgot-password', authController.forgotPassword);
router.post('/verify-otp', authController.verifyOtp);
router.post('/resend-otp', authController.resendOtp);
router.post('/reset-password', authController.resetPassword);

// Protected Session Endpoints
router.get('/me', authenticateToken, authController.getMe);
router.post('/refresh-token', authenticateToken, authController.refreshToken);
router.put('/change-password', authenticateToken, authController.changePassword);

module.exports = router;

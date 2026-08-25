const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const { authenticateToken } = require('../middleware/auth');

router.use(authenticateToken);

router.get('/me', userController.getProfile);
router.put('/me', userController.updateProfile);
router.post('/me/profile-image', userController.uploadProfileImage);

// Favorites Management
router.get('/me/favorites', userController.getFavorites);
router.post('/me/favorites/:millId', userController.addFavorite);
router.delete('/me/favorites/:millId', userController.removeFavorite);

// Address Management
router.get('/me/addresses', userController.getAddresses);
router.post('/me/addresses', userController.addAddress);
router.put('/me/addresses/:id', userController.updateAddress);
router.delete('/me/addresses/:id', userController.deleteAddress);
router.put('/me/addresses/:id/default', userController.setDefaultAddress);

module.exports = router;

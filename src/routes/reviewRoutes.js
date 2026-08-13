const express = require('express');
const router = express.Router();
const reviewController = require('../controllers/reviewController');
const { authenticateToken } = require('../middleware/auth');

router.put('/:reviewId', authenticateToken, reviewController.updateReview);
router.delete('/:reviewId', authenticateToken, reviewController.deleteReview);

module.exports = router;

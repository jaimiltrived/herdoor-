const express = require('express');
const router = express.Router();
const millController = require('../controllers/millController');

router.get('/nearby', millController.getNearbyMills);
router.get('/', millController.getMills);
router.get('/:millId', millController.getMillById);
router.get('/:millId/services', millController.getMillServices);
router.get('/:millId/grains', millController.getMillGrains);
router.get('/:millId/products', millController.getMillProducts);
router.get('/:millId/availability', millController.getMillAvailability);
router.get('/:millId/working-hours', millController.getMillWorkingHours);
router.get('/:millId/ratings', millController.getMillRatings);

module.exports = router;

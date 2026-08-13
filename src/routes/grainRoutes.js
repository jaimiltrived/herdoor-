const express = require('express');
const router = express.Router();
const grainController = require('../controllers/grainController');

// Grain Sources
router.get('/grain-sources', grainController.getGrainSources);
router.get('/grain-sources/:id', grainController.getGrainSourceById);

// Grain Types
router.get('/grain-types', grainController.getGrainTypes);
router.get('/grain-types/:id', grainController.getGrainTypeById);

module.exports = router;

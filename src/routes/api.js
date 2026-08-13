const express = require('express');
const router = express.Router();

const authRoutes = require('./authRoutes');
const userRoutes = require('./userRoutes');
const millRoutes = require('./millRoutes');
const grainRoutes = require('./grainRoutes');
const orderRoutes = require('./orderRoutes');
const paymentRoutes = require('./paymentRoutes');
const deliveryRoutes = require('./deliveryRoutes');
const reviewRoutes = require('./reviewRoutes');
const notificationRoutes = require('./notificationRoutes');
const shopkeeperRoutes = require('./shopkeeperRoutes');

// Health endpoint
router.use('/health', require('./health'));

// Domain Modules
router.use('/auth', authRoutes);
router.use('/users', userRoutes);
router.use('/mills', millRoutes);
router.use('/', grainRoutes); // grain-sources & grain-types
router.use('/orders', orderRoutes);
router.use('/payments', paymentRoutes);
router.use('/delivery', deliveryRoutes);
router.use('/reviews', reviewRoutes);
router.use('/', notificationRoutes); // /notifications & /devices
router.use('/shopkeeper', shopkeeperRoutes);

/**
 * @route   GET /api/v1
 * @desc    API Root Specification
 */
router.get('/', (req, res) => {
  res.json({
    service: 'HerDoor Flour Mill & Grain Processing REST API',
    version: '1.0.0',
    documentation: {
      auth: '/api/v1/auth',
      users: '/api/v1/users',
      mills: '/api/v1/mills',
      grains: '/api/v1/grain-types',
      orders: '/api/v1/orders',
      payments: '/api/v1/payments',
      delivery: '/api/v1/delivery',
      shopkeeper: '/api/v1/shopkeeper'
    }
  });
});

module.exports = router;

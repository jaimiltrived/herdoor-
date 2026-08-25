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
const adminRoutes = require('./adminRoutes');

// Health endpoint
router.use('/health', require('./health'));

/**
 * @route   GET /api/v1
 * @desc    API Root Specification with all 3 user roles + admin domains
 */
router.get('/', (req, res) => {
  res.json({
    service: 'HerDoor Flour Mill & Grain Processing REST API',
    version: '1.0.0',
    roles: {
      customer: 'Consumer ordering flour & grain milling services',
      merchant: 'Mill owner managing grinding jobs & inventory',
      delivery: 'Rider picking up and delivering orders',
      admin: 'Platform administrator monitoring system operations'
    },
    documentation: {
      auth: '/api/v1/auth',
      customer: {
        orders: '/api/v1/orders',
        mills: '/api/v1/mills',
        grainTypes: '/api/v1/grain-types',
        profile: '/api/v1/users/me'
      },
      merchant: '/api/v1/shopkeeper',
      delivery: '/api/v1/delivery',
      admin: '/api/v1/admin',
      swaggerDocs: '/api-docs'
    }
  });
});

// Domain Modules for All 3 Users & Admin
router.use('/auth', authRoutes);
router.use('/users', userRoutes);
router.use('/mills', millRoutes);
router.use('/', grainRoutes); // grain-sources & grain-types
router.use('/orders', orderRoutes);
router.use('/payments', paymentRoutes);
router.use('/delivery', deliveryRoutes);
router.use('/reviews', reviewRoutes);
router.use('/notifications', notificationRoutes);
router.use('/shopkeeper', shopkeeperRoutes);
router.use('/admin', adminRoutes);

// Customer Alias Mounts
router.use('/customer/orders', orderRoutes);
router.use('/customer/mills', millRoutes);
router.use('/customer/notifications', notificationRoutes);

module.exports = router;

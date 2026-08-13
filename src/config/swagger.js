const swaggerJsdoc = require('swagger-jsdoc');

const swaggerDefinition = {
  openapi: '3.0.0',
  info: {
    title: 'HerDoor Flour Mill & Grain Processing REST API',
    version: '1.0.0',
    description: 'Complete API documentation for Customer App, Shopkeeper Mill Dashboard, and Delivery Application.',
    contact: {
      name: 'HerDoor API Support',
      email: 'support@herdoor.com'
    }
  },
  servers: [
    {
      url: 'http://localhost:5000',
      description: 'Local Server'
    }
  ],
  components: {
    securitySchemes: {
      BearerAuth: {
        type: 'http',
        scheme: 'bearer',
        bearerFormat: 'JWT',
        description: 'Enter JWT Token: Bearer <token>'
      }
    }
  },
  tags: [
    { name: 'Auth', description: 'Authentication & Session Management' },
    { name: 'Users', description: 'Customer Profile & Addresses' },
    { name: 'Mills', description: 'Geospatial Nearby Mill Locator & Details' },
    { name: 'Grains', description: 'Grain Catalog & Grain Sources' },
    { name: 'Orders', description: 'Customer Order Management & Tracking' },
    { name: 'Payments', description: 'Payment Processing & Refunds' },
    { name: 'Delivery', description: 'Delivery Agent Workflows' },
    { name: 'Reviews', description: 'Mill Ratings & Reviews' },
    { name: 'Notifications', description: 'User Alerts & Push Device Tokens' },
    { name: 'Shopkeeper', description: 'Mill Dashboard, Inventory & State Machine' }
  ],
  paths: {
    // ---------------- AUTH ----------------
    '/api/v1/auth/register': {
      post: {
        tags: ['Auth'],
        summary: 'Register new user',
        requestBody: {
          required: true,
          content: { 'application/json': { schema: { type: 'object', properties: { name: { type: 'string' }, email: { type: 'string' }, phone: { type: 'string' }, password: { type: 'string' }, role: { type: 'string', example: 'CUSTOMER' } } } } }
        },
        responses: { 201: { description: 'Registered successfully' } }
      }
    },
    '/api/v1/auth/login': {
      post: {
        tags: ['Auth'],
        summary: 'User login',
        requestBody: {
          required: true,
          content: { 'application/json': { schema: { type: 'object', properties: { email: { type: 'string' }, phone: { type: 'string' }, password: { type: 'string' } } } } }
        },
        responses: { 200: { description: 'Login successful' } }
      }
    },
    '/api/v1/auth/logout': {
      post: { tags: ['Auth'], summary: 'User logout', responses: { 200: { description: 'Logged out' } } }
    },
    '/api/v1/auth/refresh-token': {
      post: { tags: ['Auth'], security: [{ BearerAuth: [] }], summary: 'Refresh JWT token', responses: { 200: { description: 'Token refreshed' } } }
    },
    '/api/v1/auth/forgot-password': {
      post: {
        tags: ['Auth'],
        summary: 'Request password reset OTP',
        requestBody: { content: { 'application/json': { schema: { type: 'object', properties: { email: { type: 'string' }, phone: { type: 'string' } } } } } },
        responses: { 200: { description: 'OTP sent' } }
      }
    },
    '/api/v1/auth/reset-password': {
      post: {
        tags: ['Auth'],
        summary: 'Reset password with OTP',
        requestBody: { content: { 'application/json': { schema: { type: 'object', properties: { otp: { type: 'string' }, newPassword: { type: 'string' } } } } } },
        responses: { 200: { description: 'Password reset' } }
      }
    },
    '/api/v1/auth/verify-otp': {
      post: {
        tags: ['Auth'],
        summary: 'Verify OTP',
        requestBody: { content: { 'application/json': { schema: { type: 'object', properties: { otp: { type: 'string' } } } } } },
        responses: { 200: { description: 'OTP verified' } }
      }
    },
    '/api/v1/auth/me': {
      get: { tags: ['Auth'], security: [{ BearerAuth: [] }], summary: 'Get current user profile', responses: { 200: { description: 'User profile data' } } }
    },
    '/api/v1/auth/change-password': {
      put: {
        tags: ['Auth'],
        security: [{ BearerAuth: [] }],
        summary: 'Change user password',
        requestBody: { content: { 'application/json': { schema: { type: 'object', properties: { currentPassword: { type: 'string' }, newPassword: { type: 'string' } } } } } },
        responses: { 200: { description: 'Password changed' } }
      }
    },

    // ---------------- USERS ----------------
    '/api/v1/users/me': {
      get: { tags: ['Users'], security: [{ BearerAuth: [] }], summary: 'Get user details', responses: { 200: { description: 'User data' } } },
      put: { tags: ['Users'], security: [{ BearerAuth: [] }], summary: 'Update profile', responses: { 200: { description: 'Profile updated' } } }
    },
    '/api/v1/users/me/addresses': {
      get: { tags: ['Users'], security: [{ BearerAuth: [] }], summary: 'Get saved addresses', responses: { 200: { description: 'Addresses list' } } },
      post: {
        tags: ['Users'],
        security: [{ BearerAuth: [] }],
        summary: 'Add saved address',
        requestBody: { content: { 'application/json': { schema: { type: 'object', properties: { addressLine1: { type: 'string' }, city: { type: 'string' }, pincode: { type: 'string' }, latitude: { type: 'number' }, longitude: { type: 'number' } } } } } },
        responses: { 201: { description: 'Address added' } }
      }
    },
    '/api/v1/users/me/addresses/{id}': {
      put: { tags: ['Users'], security: [{ BearerAuth: [] }], summary: 'Update address', parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'integer' } }], responses: { 200: { description: 'Address updated' } } },
      delete: { tags: ['Users'], security: [{ BearerAuth: [] }], summary: 'Delete address', parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'integer' } }], responses: { 200: { description: 'Address deleted' } } }
    },
    '/api/v1/users/me/addresses/{id}/default': {
      put: { tags: ['Users'], security: [{ BearerAuth: [] }], summary: 'Set default address', parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'integer' } }], responses: { 200: { description: 'Default address set' } } }
    },

    // ---------------- MILLS ----------------
    '/api/v1/mills/nearby': {
      get: {
        tags: ['Mills'],
        summary: 'Geospatial nearby mill locator',
        parameters: [
          { name: 'latitude', in: 'query', required: true, schema: { type: 'number', example: 23.0225 } },
          { name: 'longitude', in: 'query', required: true, schema: { type: 'number', example: 72.5714 } },
          { name: 'radius', in: 'query', schema: { type: 'number', example: 5 } }
        ],
        responses: { 200: { description: 'Nearby mills list sorted by distance' } }
      }
    },
    '/api/v1/mills': {
      get: { tags: ['Mills'], summary: 'Search and filter mills', parameters: [{ name: 'search', in: 'query', schema: { type: 'string' } }, { name: 'isOpen', in: 'query', schema: { type: 'boolean' } }], responses: { 200: { description: 'Mills list' } } }
    },
    '/api/v1/mills/{millId}': {
      get: { tags: ['Mills'], summary: 'Get mill details', parameters: [{ name: 'millId', in: 'path', required: true, schema: { type: 'integer' } }], responses: { 200: { description: 'Mill details' } } }
    },
    '/api/v1/mills/{millId}/services': {
      get: { tags: ['Mills'], summary: 'Get mill services', parameters: [{ name: 'millId', in: 'path', required: true, schema: { type: 'integer' } }], responses: { 200: { description: 'Mill services list' } } }
    },
    '/api/v1/mills/{millId}/grains': {
      get: { tags: ['Mills'], summary: 'Get mill available grains', parameters: [{ name: 'millId', in: 'path', required: true, schema: { type: 'integer' } }], responses: { 200: { description: 'Mill grains list' } } }
    },
    '/api/v1/mills/{millId}/availability': {
      get: { tags: ['Mills'], summary: 'Get mill availability state', parameters: [{ name: 'millId', in: 'path', required: true, schema: { type: 'integer' } }], responses: { 200: { description: 'Availability details' } } }
    },
    '/api/v1/mills/{millId}/ratings': {
      get: { tags: ['Mills'], summary: 'Get mill ratings & reviews', parameters: [{ name: 'millId', in: 'path', required: true, schema: { type: 'integer' } }], responses: { 200: { description: 'Ratings and reviews' } } }
    },

    // ---------------- GRAINS ----------------
    '/api/v1/grain-sources': {
      get: { tags: ['Grains'], summary: 'Get grain sources list', responses: { 200: { description: 'Grain sources list' } } }
    },
    '/api/v1/grain-types': {
      get: { tags: ['Grains'], summary: 'Get grain types catalog', responses: { 200: { description: 'Grain types list' } } }
    },

    // ---------------- ORDERS ----------------
    '/api/v1/orders': {
      post: {
        tags: ['Orders'],
        security: [{ BearerAuth: [] }],
        summary: 'Place order',
        requestBody: { content: { 'application/json': { schema: { type: 'object', required: ['millId', 'grainTypeId', 'quantityKg'], properties: { millId: { type: 'integer', example: 101 }, grainSource: { type: 'string', example: 'CUSTOMER' }, grainTypeId: { type: 'integer', example: 1 }, quantityKg: { type: 'number', example: 10 }, serviceType: { type: 'string', example: 'GRINDING' }, fulfillmentType: { type: 'string', example: 'DELIVERY' }, addressId: { type: 'integer', example: 25 }, paymentMethod: { type: 'string', example: 'UPI' } } } } } },
        responses: { 201: { description: 'Order created' } }
      },
      get: { tags: ['Orders'], security: [{ BearerAuth: [] }], summary: 'Get customer orders list', responses: { 200: { description: 'Orders list' } } }
    },
    '/api/v1/orders/active': {
      get: { tags: ['Orders'], security: [{ BearerAuth: [] }], summary: 'Get active processing orders', responses: { 200: { description: 'Active orders' } } }
    },
    '/api/v1/orders/history': {
      get: { tags: ['Orders'], security: [{ BearerAuth: [] }], summary: 'Get completed order history', responses: { 200: { description: 'Completed orders' } } }
    },
    '/api/v1/orders/{orderId}': {
      get: { tags: ['Orders'], security: [{ BearerAuth: [] }], summary: 'Get order details', parameters: [{ name: 'orderId', in: 'path', required: true, schema: { type: 'integer' } }], responses: { 200: { description: 'Order details' } } }
    },
    '/api/v1/orders/{orderId}/timeline': {
      get: { tags: ['Orders'], security: [{ BearerAuth: [] }], summary: 'Get order status timeline', parameters: [{ name: 'orderId', in: 'path', required: true, schema: { type: 'integer' } }], responses: { 200: { description: 'Order timeline' } } }
    },
    '/api/v1/orders/{orderId}/cancel': {
      post: { tags: ['Orders'], security: [{ BearerAuth: [] }], summary: 'Cancel order', parameters: [{ name: 'orderId', in: 'path', required: true, schema: { type: 'integer' } }], responses: { 200: { description: 'Order cancelled' } } }
    },
    '/api/v1/orders/{orderId}/repeat': {
      post: { tags: ['Orders'], security: [{ BearerAuth: [] }], summary: 'Repeat previous order', parameters: [{ name: 'orderId', in: 'path', required: true, schema: { type: 'integer' } }], responses: { 201: { description: 'New repeated order created' } } }
    },

    // ---------------- PAYMENTS ----------------
    '/api/v1/payments/create': {
      post: { tags: ['Payments'], security: [{ BearerAuth: [] }], summary: 'Create payment', responses: { 201: { description: 'Payment created' } } }
    },
    '/api/v1/payments/verify': {
      post: { tags: ['Payments'], security: [{ BearerAuth: [] }], summary: 'Verify payment', responses: { 200: { description: 'Payment verified' } } }
    },

    // ---------------- DELIVERY ----------------
    '/api/v1/delivery/auth/login': {
      post: { tags: ['Delivery'], summary: 'Delivery agent login', responses: { 200: { description: 'Delivery agent authenticated' } } }
    },
    '/api/v1/delivery/orders': {
      get: { tags: ['Delivery'], security: [{ BearerAuth: [] }], summary: 'Get delivery orders', responses: { 200: { description: 'Deliveries list' } } }
    },
    '/api/v1/delivery/orders/{orderId}/accept': {
      post: { tags: ['Delivery'], security: [{ BearerAuth: [] }], summary: 'Accept delivery task', parameters: [{ name: 'orderId', in: 'path', required: true, schema: { type: 'integer' } }], responses: { 200: { description: 'Delivery accepted' } } }
    },
    '/api/v1/delivery/orders/{orderId}/delivered': {
      post: { tags: ['Delivery'], security: [{ BearerAuth: [] }], summary: 'Mark order delivered', parameters: [{ name: 'orderId', in: 'path', required: true, schema: { type: 'integer' } }], responses: { 200: { description: 'Order delivered' } } }
    },

    // ---------------- REVIEWS ----------------
    '/api/v1/orders/{orderId}/review': {
      post: { tags: ['Reviews'], security: [{ BearerAuth: [] }], summary: 'Submit review', parameters: [{ name: 'orderId', in: 'path', required: true, schema: { type: 'integer' } }], responses: { 201: { description: 'Review submitted' } } }
    },

    // ---------------- NOTIFICATIONS ----------------
    '/api/v1/notifications': {
      get: { tags: ['Notifications'], security: [{ BearerAuth: [] }], summary: 'Get notifications', responses: { 200: { description: 'Notifications list' } } }
    },
    '/api/v1/devices/register': {
      post: { tags: ['Notifications'], security: [{ BearerAuth: [] }], summary: 'Register FCM device token', responses: { 201: { description: 'Device token registered' } } }
    },

    // ---------------- SHOPKEEPER ----------------
    '/api/v1/shopkeeper/dashboard': {
      get: { tags: ['Shopkeeper'], security: [{ BearerAuth: [] }], summary: 'Get shopkeeper dashboard metrics', responses: { 200: { description: 'Dashboard metrics' } } }
    },
    '/api/v1/shopkeeper/orders/{orderId}/accept': {
      post: { tags: ['Shopkeeper'], security: [{ BearerAuth: [] }], summary: 'Accept order & set completion ETA', parameters: [{ name: 'orderId', in: 'path', required: true, schema: { type: 'integer' } }], responses: { 200: { description: 'Order accepted' } } }
    },
    '/api/v1/shopkeeper/orders/{orderId}/start': {
      post: { tags: ['Shopkeeper'], security: [{ BearerAuth: [] }], summary: 'Start grinding processing', parameters: [{ name: 'orderId', in: 'path', required: true, schema: { type: 'integer' } }], responses: { 200: { description: 'Processing started' } } }
    },
    '/api/v1/shopkeeper/orders/{orderId}/ready': {
      post: { tags: ['Shopkeeper'], security: [{ BearerAuth: [] }], summary: 'Mark order ready', parameters: [{ name: 'orderId', in: 'path', required: true, schema: { type: 'integer' } }], responses: { 200: { description: 'Order ready' } } }
    },
    '/api/v1/shopkeeper/inventory': {
      get: { tags: ['Shopkeeper'], security: [{ BearerAuth: [] }], summary: 'Get mill inventory items', responses: { 200: { description: 'Inventory list' } } }
    },
    '/api/v1/shopkeeper/inventory/{id}/stock-in': {
      post: { tags: ['Shopkeeper'], security: [{ BearerAuth: [] }], summary: 'Add stock (stock-in)', parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'integer' } }], responses: { 200: { description: 'Stock updated' } } }
    },
    '/api/v1/shopkeeper/availability': {
      put: { tags: ['Shopkeeper'], security: [{ BearerAuth: [] }], summary: 'Toggle mill open/close availability', responses: { 200: { description: 'Availability updated' } } }
    }
  }
};

const options = {
  swaggerDefinition,
  apis: ['./src/routes/*.js']
};

module.exports = swaggerJsdoc(options);

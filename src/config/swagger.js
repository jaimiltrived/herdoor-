const swaggerJsdoc = require('swagger-jsdoc');

const swaggerDefinition = {
  openapi: '3.0.0',
  info: {
    title: 'HerDoor Flour Mill & Grain Processing REST API',
    version: '1.0.0',
    description: 'Complete multi-role REST API specification for Customer, Merchant / Mill Owner, Delivery Rider, and Admin Console.',
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
    { name: '1. Auth', description: 'Authentication, Registration & Profile Session' },
    { name: '2. Customer App', description: 'Nearby Mills, Custom Milling Orders & Tracking' },
    { name: '3. Merchant App', description: 'Mill Owner Dashboard, Order Processing State Machine & Inventory' },
    { name: '4. Delivery Partner App', description: 'Driver Available Trips, Pickup, Live GPS Tracking & Delivery' },
    { name: '5. Admin Console', description: 'Platform Wide KPIs, Mill Registrations, Fleet & Security Logs' }
  ],
  paths: {
    // ---------------- 1. AUTH ----------------
    '/api/v1/auth/register': {
      post: {
        tags: ['1. Auth'],
        summary: 'Register new user account (Customer, Merchant, Delivery, Admin)',
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                type: 'object',
                properties: {
                  name: { type: 'string', example: 'Ramesh Patel' },
                  email: { type: 'string', example: 'ramesh@example.com' },
                  phone: { type: 'string', example: '+919876543210' },
                  password: { type: 'string', example: 'Password123!' },
                  role: { type: 'string', enum: ['CUSTOMER', 'SHOPKEEPER', 'DELIVERY', 'ADMIN'], example: 'CUSTOMER' }
                }
              }
            }
          }
        },
        responses: { 201: { description: 'Registered successfully' } }
      }
    },
    '/api/v1/auth/login': {
      post: {
        tags: ['1. Auth'],
        summary: 'User/Admin Login and JWT Token generation',
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                type: 'object',
                properties: {
                  email: { type: 'string', example: 'ramesh@example.com' },
                  phone: { type: 'string', example: '+919876543210' },
                  password: { type: 'string', example: 'Password123!' }
                }
              }
            }
          }
        },
        responses: { 200: { description: 'Login successful' } }
      }
    },
    '/api/v1/auth/me': {
      get: {
        tags: ['1. Auth'],
        security: [{ BearerAuth: [] }],
        summary: 'Get currently authenticated user details',
        responses: { 200: { description: 'Active user profile' } }
      }
    },

    // ---------------- 2. CUSTOMER APP ----------------
    '/api/v1/mills/nearby': {
      get: {
        tags: ['2. Customer App'],
        summary: 'Geospatial nearby flour mills discovery',
        parameters: [
          { name: 'latitude', in: 'query', required: true, schema: { type: 'number', example: 23.0225 } },
          { name: 'longitude', in: 'query', required: true, schema: { type: 'number', example: 72.5714 } },
          { name: 'radius', in: 'query', schema: { type: 'number', example: 10 } }
        ],
        responses: { 200: { description: 'Nearby mills list sorted by distance' } }
      }
    },
    '/api/v1/grain-types': {
      get: {
        tags: ['2. Customer App'],
        summary: 'List available grain types and grinding fees',
        responses: { 200: { description: 'Grain types list' } }
      }
    },
    '/api/v1/orders': {
      post: {
        tags: ['2. Customer App'],
        security: [{ BearerAuth: [] }],
        summary: 'Place customized grain milling / flour order',
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                type: 'object',
                required: ['millId', 'grainTypeId', 'quantityKg'],
                properties: {
                  millId: { type: 'integer', example: 101 },
                  grainSource: { type: 'string', enum: ['CUSTOMER', 'MILL', 'VENDOR'], example: 'CUSTOMER' },
                  grainTypeId: { type: 'integer', example: 1 },
                  quantityKg: { type: 'number', example: 10 },
                  serviceType: { type: 'string', example: 'GRINDING' },
                  fulfillmentType: { type: 'string', enum: ['DELIVERY', 'PICKUP'], example: 'DELIVERY' },
                  addressId: { type: 'integer', example: 25 },
                  paymentMethod: { type: 'string', example: 'UPI' }
                }
              }
            }
          }
        },
        responses: { 201: { description: 'Order placed successfully' } }
      },
      get: {
        tags: ['2. Customer App'],
        security: [{ BearerAuth: [] }],
        summary: 'Get customer orders list with status filtering',
        responses: { 200: { description: 'Orders list' } }
      }
    },
    '/api/v1/orders/{orderId}/tracking': {
      get: {
        tags: ['2. Customer App'],
        security: [{ BearerAuth: [] }],
        summary: 'Live real-time order tracking & delivery location',
        parameters: [{ name: 'orderId', in: 'path', required: true, schema: { type: 'integer' } }],
        responses: { 200: { description: 'Live tracking timeline' } }
      }
    },
    '/api/v1/orders/{orderId}/cancel': {
      post: {
        tags: ['2. Customer App'],
        security: [{ BearerAuth: [] }],
        summary: 'Cancel order before processing/packing',
        parameters: [{ name: 'orderId', in: 'path', required: true, schema: { type: 'integer' } }],
        requestBody: { content: { 'application/json': { schema: { type: 'object', properties: { reason: { type: 'string' } } } } } },
        responses: { 200: { description: 'Order cancelled' } }
      }
    },
    '/api/v1/orders/{orderId}/review': {
      post: {
        tags: ['2. Customer App'],
        security: [{ BearerAuth: [] }],
        summary: 'Submit 5-star rating & review for completed order',
        parameters: [{ name: 'orderId', in: 'path', required: true, schema: { type: 'integer' } }],
        requestBody: { content: { 'application/json': { schema: { type: 'object', properties: { rating: { type: 'integer', example: 5 }, review: { type: 'string', example: 'Fresh and fine!' } } } } } },
        responses: { 201: { description: 'Review posted' } }
      }
    },

    // ---------------- 3. MERCHANT APP ----------------
    '/api/v1/shopkeeper/dashboard': {
      get: {
        tags: ['3. Merchant App'],
        security: [{ BearerAuth: [] }],
        summary: 'Merchant real-time dashboard KPIs, queue counts, and daily revenue',
        responses: { 200: { description: 'Dashboard metrics' } }
      }
    },
    '/api/v1/shopkeeper/orders/pending': {
      get: {
        tags: ['3. Merchant App'],
        security: [{ BearerAuth: [] }],
        summary: 'Incoming pending order requests queue',
        responses: { 200: { description: 'Pending orders list' } }
      }
    },
    '/api/v1/shopkeeper/orders/{orderId}/accept': {
      post: {
        tags: ['3. Merchant App'],
        security: [{ BearerAuth: [] }],
        summary: 'Accept order and set estimated completion time (ETA)',
        parameters: [{ name: 'orderId', in: 'path', required: true, schema: { type: 'integer' } }],
        requestBody: { content: { 'application/json': { schema: { type: 'object', properties: { estimatedCompletionMinutes: { type: 'integer', example: 30 } } } } } },
        responses: { 200: { description: 'Order accepted' } }
      }
    },
    '/api/v1/shopkeeper/orders/{orderId}/start': {
      post: {
        tags: ['3. Merchant App'],
        security: [{ BearerAuth: [] }],
        summary: 'Start grinding / milling process',
        parameters: [{ name: 'orderId', in: 'path', required: true, schema: { type: 'integer' } }],
        responses: { 200: { description: 'Milling started' } }
      }
    },
    '/api/v1/shopkeeper/orders/{orderId}/packing': {
      post: {
        tags: ['3. Merchant App'],
        security: [{ BearerAuth: [] }],
        summary: 'Start flour packing & packaging',
        parameters: [{ name: 'orderId', in: 'path', required: true, schema: { type: 'integer' } }],
        responses: { 200: { description: 'Packing started' } }
      }
    },
    '/api/v1/shopkeeper/orders/{orderId}/ready': {
      post: {
        tags: ['3. Merchant App'],
        security: [{ BearerAuth: [] }],
        summary: 'Mark order ready for customer pickup / driver dispatch',
        parameters: [{ name: 'orderId', in: 'path', required: true, schema: { type: 'integer' } }],
        responses: { 200: { description: 'Order ready' } }
      }
    },
    '/api/v1/shopkeeper/orders/{orderId}/handover': {
      post: {
        tags: ['3. Merchant App'],
        security: [{ BearerAuth: [] }],
        summary: 'Handover order to delivery driver with PIN verification',
        parameters: [{ name: 'orderId', in: 'path', required: true, schema: { type: 'integer' } }],
        requestBody: { content: { 'application/json': { schema: { type: 'object', properties: { pin: { type: 'string', example: '4821' } } } } } },
        responses: { 200: { description: 'Order handed over' } }
      }
    },
    '/api/v1/shopkeeper/inventory': {
      get: {
        tags: ['3. Merchant App'],
        security: [{ BearerAuth: [] }],
        summary: 'Get flour & grain stock inventory',
        responses: { 200: { description: 'Inventory items' } }
      },
      post: {
        tags: ['3. Merchant App'],
        security: [{ BearerAuth: [] }],
        summary: 'Add new inventory product',
        requestBody: { content: { 'application/json': { schema: { type: 'object', properties: { name: { type: 'string' }, productType: { type: 'string' }, stockKg: { type: 'number' }, pricePerKg: { type: 'number' } } } } } },
        responses: { 201: { description: 'Item created' } }
      }
    },
    '/api/v1/shopkeeper/availability': {
      put: {
        tags: ['3. Merchant App'],
        security: [{ BearerAuth: [] }],
        summary: 'Toggle mill open/close operational availability',
        requestBody: { content: { 'application/json': { schema: { type: 'object', properties: { isOpen: { type: 'boolean', example: true } } } } } },
        responses: { 200: { description: 'Availability updated' } }
      }
    },

    // ---------------- 4. DELIVERY PARTNER APP ----------------
    '/api/v1/delivery/auth/login': {
      post: {
        tags: ['4. Delivery Partner App'],
        summary: 'Delivery partner / rider login',
        requestBody: { content: { 'application/json': { schema: { type: 'object', properties: { email: { type: 'string', example: 'delivery@herdoor.com' }, password: { type: 'string', example: 'Password123!' } } } } } },
        responses: { 200: { description: 'Rider authenticated' } }
      }
    },
    '/api/v1/delivery/available-trips': {
      get: {
        tags: ['4. Delivery Partner App'],
        security: [{ BearerAuth: [] }],
        summary: 'List available trips ready for driver pickup',
        responses: { 200: { description: 'Available trips queue' } }
      }
    },
    '/api/v1/delivery/orders/{orderId}/accept': {
      post: {
        tags: ['4. Delivery Partner App'],
        security: [{ BearerAuth: [] }],
        summary: 'Accept delivery trip task',
        parameters: [{ name: 'orderId', in: 'path', required: true, schema: { type: 'integer' } }],
        responses: { 200: { description: 'Trip assigned to rider' } }
      }
    },
    '/api/v1/delivery/orders/{orderId}/pickup': {
      post: {
        tags: ['4. Delivery Partner App'],
        security: [{ BearerAuth: [] }],
        summary: 'Confirm pickup from mill with verification PIN',
        parameters: [{ name: 'orderId', in: 'path', required: true, schema: { type: 'integer' } }],
        requestBody: { content: { 'application/json': { schema: { type: 'object', properties: { pin: { type: 'string', example: '4821' } } } } } },
        responses: { 200: { description: 'Picked up from mill' } }
      }
    },
    '/api/v1/delivery/orders/{orderId}/location': {
      post: {
        tags: ['4. Delivery Partner App'],
        security: [{ BearerAuth: [] }],
        summary: 'Stream live GPS location coordinates',
        parameters: [{ name: 'orderId', in: 'path', required: true, schema: { type: 'integer' } }],
        requestBody: { content: { 'application/json': { schema: { type: 'object', properties: { latitude: { type: 'number', example: 23.0245 }, longitude: { type: 'number', example: 72.5708 } } } } } },
        responses: { 200: { description: 'Location updated' } }
      }
    },
    '/api/v1/delivery/orders/{orderId}/deliver': {
      post: {
        tags: ['4. Delivery Partner App'],
        security: [{ BearerAuth: [] }],
        summary: 'Complete delivery to customer with delivery OTP',
        parameters: [{ name: 'orderId', in: 'path', required: true, schema: { type: 'integer' } }],
        requestBody: { content: { 'application/json': { schema: { type: 'object', properties: { otp: { type: 'string', example: '7391' } } } } } },
        responses: { 200: { description: 'Delivery completed' } }
      }
    },
    '/api/v1/delivery/earnings': {
      get: {
        tags: ['4. Delivery Partner App'],
        security: [{ BearerAuth: [] }],
        summary: 'Get rider daily and weekly earnings payout summary',
        responses: { 200: { description: 'Earnings breakdown' } }
      }
    },

    // ---------------- 5. ADMIN CONSOLE ----------------
    '/api/v1/admin/dashboard': {
      get: {
        tags: ['5. Admin Console'],
        security: [{ BearerAuth: [] }],
        summary: 'Platform-wide operational analytics & KPIs',
        responses: { 200: { description: 'Platform metrics' } }
      }
    },
    '/api/v1/admin/mills': {
      get: {
        tags: ['5. Admin Console'],
        security: [{ BearerAuth: [] }],
        summary: 'List all registered flour mills',
        responses: { 200: { description: 'Mills master list' } }
      },
      post: {
        tags: ['5. Admin Console'],
        security: [{ BearerAuth: [] }],
        summary: 'Register new flour mill on platform',
        requestBody: { content: { 'application/json': { schema: { type: 'object', properties: { name: { type: 'string' }, address: { type: 'string' }, phone: { type: 'string' } } } } } },
        responses: { 201: { description: 'Mill registered' } }
      }
    },
    '/api/v1/admin/riders': {
      get: {
        tags: ['5. Admin Console'],
        security: [{ BearerAuth: [] }],
        summary: 'List active delivery fleet partners',
        responses: { 200: { description: 'Riders fleet list' } }
      }
    },
    '/api/v1/admin/wholesalers': {
      get: {
        tags: ['5. Admin Console'],
        security: [{ BearerAuth: [] }],
        summary: 'List wholesale grain depots & stock tonnage',
        responses: { 200: { description: 'Wholesalers list' } }
      }
    },
    '/api/v1/admin/security': {
      get: {
        tags: ['5. Admin Console'],
        security: [{ BearerAuth: [] }],
        summary: 'Platform security logs & access audits',
        responses: { 200: { description: 'Security audit logs' } }
      }
    }
  }
};

const options = {
  swaggerDefinition,
  apis: ['./src/routes/*.js']
};

module.exports = swaggerJsdoc(options);

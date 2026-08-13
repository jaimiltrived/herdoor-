const request = require('supertest');
const app = require('../src/app');

describe('Order Lifecycle & State Machine Integration Tests', () => {
  let customerToken;
  let shopkeeperToken;
  let deliveryToken;
  let createdOrderId;

  beforeAll(async () => {
    // 1. Acquire Customer Token
    const custRes = await request(app)
      .post('/api/v1/auth/login')
      .send({ email: 'ramesh@example.com', password: 'Password123!' });
    customerToken = custRes.body.data.token;

    // 2. Acquire Shopkeeper Token
    const shopRes = await request(app)
      .post('/api/v1/auth/login')
      .send({ email: 'shop@shreeganesh.com', password: 'Password123!' });
    shopkeeperToken = shopRes.body.data.token;

    // 3. Acquire Delivery Agent Token
    const delivRes = await request(app)
      .post('/api/v1/delivery/auth/login')
      .send({ email: 'delivery@herdoor.com', password: 'Password123!' });
    deliveryToken = delivRes.body.data.token;
  });

  test('POST /api/v1/orders - Customer places a new grinding & delivery order', async () => {
    const res = await request(app)
      .post('/api/v1/orders')
      .set('Authorization', `Bearer ${customerToken}`)
      .send({
        millId: 101,
        grainSource: 'CUSTOMER',
        grainTypeId: 1,
        quantityKg: 15,
        serviceType: 'GRINDING',
        fulfillmentType: 'DELIVERY',
        addressId: 25,
        paymentMethod: 'UPI'
      });

    expect(res.statusCode).toBe(201);
    expect(res.body.status).toBe('success');
    expect(res.body.data.order).toHaveProperty('id');
    expect(res.body.data.order.status).toBe('PLACED');
    createdOrderId = res.body.data.order.id;
  });

  test('GET /api/v1/shopkeeper/dashboard - Shopkeeper dashboard metrics', async () => {
    const res = await request(app)
      .get('/api/v1/shopkeeper/dashboard')
      .set('Authorization', `Bearer ${shopkeeperToken}`);

    expect(res.statusCode).toBe(200);
    expect(res.body.status).toBe('success');
    expect(res.body.data).toHaveProperty('metrics');
  });

  test('POST /api/v1/shopkeeper/orders/:id/accept - Shopkeeper accepts order', async () => {
    const res = await request(app)
      .post(`/api/v1/shopkeeper/orders/${createdOrderId}/accept`)
      .set('Authorization', `Bearer ${shopkeeperToken}`)
      .send({ estimatedCompletionMinutes: 35 });

    expect(res.statusCode).toBe(200);
    expect(res.body.status).toBe('success');
    expect(res.body.data.order.status).toBe('ACCEPTED');
  });

  test('POST /api/v1/shopkeeper/orders/:id/start - Shopkeeper starts grinding', async () => {
    const res = await request(app)
      .post(`/api/v1/shopkeeper/orders/${createdOrderId}/start`)
      .set('Authorization', `Bearer ${shopkeeperToken}`);

    expect(res.statusCode).toBe(200);
    expect(res.body.status).toBe('success');
    expect(res.body.data.order.status).toBe('PROCESSING');
  });

  test('POST /api/v1/shopkeeper/orders/:id/packing - Shopkeeper packs flour', async () => {
    const res = await request(app)
      .post(`/api/v1/shopkeeper/orders/${createdOrderId}/packing`)
      .set('Authorization', `Bearer ${shopkeeperToken}`);

    expect(res.statusCode).toBe(200);
    expect(res.body.status).toBe('success');
    expect(res.body.data.order.status).toBe('PACKING');
  });

  test('POST /api/v1/shopkeeper/orders/:id/ready - Shopkeeper marks order ready', async () => {
    const res = await request(app)
      .post(`/api/v1/shopkeeper/orders/${createdOrderId}/ready`)
      .set('Authorization', `Bearer ${shopkeeperToken}`);

    expect(res.statusCode).toBe(200);
    expect(res.body.status).toBe('success');
    expect(res.body.data.order.status).toBe('READY');
  });

  test('POST /api/v1/delivery/orders/:id/accept - Delivery agent accepts delivery', async () => {
    const res = await request(app)
      .post(`/api/v1/delivery/orders/${createdOrderId}/accept`)
      .set('Authorization', `Bearer ${deliveryToken}`);

    expect(res.statusCode).toBe(200);
    expect(res.body.status).toBe('success');
    expect(res.body.data.delivery).toHaveProperty('status');
  });

  test('POST /api/v1/delivery/orders/:id/delivered - Delivery agent completes delivery', async () => {
    const res = await request(app)
      .post(`/api/v1/delivery/orders/${createdOrderId}/delivered`)
      .set('Authorization', `Bearer ${deliveryToken}`);

    expect(res.statusCode).toBe(200);
    expect(res.body.status).toBe('success');
    expect(res.body.data.delivery.status).toBe('DELIVERED');
  });

  test('POST /api/v1/orders/:id/review - Customer submits rating & review', async () => {
    const res = await request(app)
      .post(`/api/v1/orders/${createdOrderId}/review`)
      .set('Authorization', `Bearer ${customerToken}`)
      .send({
        rating: 5,
        review: 'Excellent flour grinding service and fast delivery!'
      });

    expect(res.statusCode).toBe(201);
    expect(res.body.status).toBe('success');
    expect(res.body.data.review.rating).toBe(5);
  });
});

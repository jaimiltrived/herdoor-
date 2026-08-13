const request = require('supertest');
const app = require('../src/app');

describe('Authentication API Endpoints', () => {
  test('POST /api/v1/auth/login - Customer Login Success', async () => {
    const res = await request(app)
      .post('/api/v1/auth/login')
      .send({
        email: 'ramesh@example.com',
        password: 'Password123!'
      });

    expect(res.statusCode).toBe(200);
    expect(res.body.status).toBe('success');
    expect(res.body.data).toHaveProperty('token');
    expect(res.body.data.user).toHaveProperty('role', 'CUSTOMER');
  });

  test('POST /api/v1/auth/login - Shopkeeper Login Success', async () => {
    const res = await request(app)
      .post('/api/v1/auth/login')
      .send({
        email: 'shop@shreeganesh.com',
        password: 'Password123!'
      });

    expect(res.statusCode).toBe(200);
    expect(res.body.status).toBe('success');
    expect(res.body.data).toHaveProperty('token');
    expect(res.body.data.user).toHaveProperty('role', 'SHOPKEEPER');
  });

  test('POST /api/v1/delivery/auth/login - Delivery Agent Login Success', async () => {
    const res = await request(app)
      .post('/api/v1/delivery/auth/login')
      .send({
        email: 'delivery@herdoor.com',
        password: 'Password123!'
      });

    expect(res.statusCode).toBe(200);
    expect(res.body.status).toBe('success');
    expect(res.body.data).toHaveProperty('token');
    expect(res.body.data.user).toHaveProperty('role', 'DELIVERY');
  });

  test('POST /api/v1/auth/login - Invalid Credentials Error', async () => {
    const res = await request(app)
      .post('/api/v1/auth/login')
      .send({
        email: 'ramesh@example.com',
        password: 'WrongPassword!'
      });

    expect(res.statusCode).toBe(401);
    expect(res.body.status).toBe('error');
  });

  test('POST /api/v1/auth/register - New Customer Registration', async () => {
    const uniqueEmail = `testuser_${Date.now()}@example.com`;
    const res = await request(app)
      .post('/api/v1/auth/register')
      .send({
        name: 'New Test User',
        email: uniqueEmail,
        phone: `+91${Math.floor(1000000000 + Math.random() * 9000000000)}`,
        password: 'Password123!',
        role: 'CUSTOMER'
      });

    expect(res.statusCode).toBe(201);
    expect(res.body.status).toBe('success');
    expect(res.body.data.user.email).toBe(uniqueEmail);
  });
});

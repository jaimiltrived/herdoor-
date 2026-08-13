const request = require('supertest');
const app = require('../src/app');

describe('Health & Documentation Endpoints', () => {
  test('GET / - should return root API metadata', async () => {
    const res = await request(app).get('/');
    expect(res.statusCode).toBe(200);
    expect(res.body).toHaveProperty('name', 'HerDoor Node.js API Service');
    expect(res.body).toHaveProperty('status', 'Running');
    expect(res.body).toHaveProperty('swaggerDocs', '/api-docs');
  });

  test('GET /api/v1/health - should return status ok', async () => {
    const res = await request(app).get('/api/v1/health');
    expect(res.statusCode).toBe(200);
    expect(res.body.status).toBe('ok');
    expect(res.body.message).toBe('Server is healthy');
    expect(res.body).toHaveProperty('timestamp');
  });

  test('GET /api-docs.json - should return OpenAPI spec JSON', async () => {
    const res = await request(app).get('/api-docs.json');
    expect(res.statusCode).toBe(200);
    expect(res.headers['content-type']).toMatch(/json/);
    expect(res.body).toHaveProperty('openapi');
    expect(res.body.info).toHaveProperty('title', 'HerDoor Flour Mill & Grain Processing REST API');
  });

  test('GET /api-docs/ - should render Swagger UI HTML', async () => {
    const res = await request(app).get('/api-docs/');
    expect(res.statusCode).toBe(200);
    expect(res.headers['content-type']).toMatch(/html/);
  });
});

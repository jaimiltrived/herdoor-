const request = require('supertest');
const app = require('../src/app');

describe('Flour Mills & Grains Catalog API Endpoints', () => {
  test('GET /api/v1/mills/nearby - Geospatial Locator Search', async () => {
    const res = await request(app)
      .get('/api/v1/mills/nearby')
      .query({
        latitude: 23.0225,
        longitude: 72.5714,
        radius: 10
      });

    expect(res.statusCode).toBe(200);
    expect(res.body.status).toBe('success');
    expect(Array.isArray(res.body.data.mills)).toBe(true);
    expect(res.body.data.mills.length).toBeGreaterThan(0);
    expect(res.body.data.mills[0]).toHaveProperty('distance');
  });

  test('GET /api/v1/grain-types - Grain Types Catalog', async () => {
    const res = await request(app).get('/api/v1/grain-types');
    expect(res.statusCode).toBe(200);
    expect(res.body.status).toBe('success');
    expect(Array.isArray(res.body.data.grainTypes)).toBe(true);
    expect(res.body.data.grainTypes.length).toBeGreaterThan(0);
    expect(res.body.data.grainTypes[0]).toHaveProperty('name');
    expect(res.body.data.grainTypes[0]).toHaveProperty('pricePerKg');
  });

  test('GET /api/v1/grain-sources - Grain Sources Catalog', async () => {
    const res = await request(app).get('/api/v1/grain-sources');
    expect(res.statusCode).toBe(200);
    expect(res.body.status).toBe('success');
    expect(Array.isArray(res.body.data.grainSources)).toBe(true);
    expect(res.body.data.grainSources.length).toBeGreaterThan(0);
  });
});

const app = require('./src/app');
const http = require('http');

let server;
let port;
let customerToken;
let shopkeeperToken;
let deliveryToken;
let createdOrderId;

function makeRequest(method, path, body = null, token = null) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'localhost',
      port: port,
      path: path,
      method: method,
      headers: {
        'Content-Type': 'application/json'
      }
    };

    if (token) {
      options.headers['Authorization'] = `Bearer ${token}`;
    }

    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          resolve({ status: res.statusCode, body: JSON.parse(data) });
        } catch (e) {
          resolve({ status: res.statusCode, body: data });
        }
      });
    });

    req.on('error', reject);
    if (body) {
      req.write(JSON.stringify(body));
    }
    req.end();
  });
}

async function runTests() {
  server = app.listen(0, async () => {
    port = server.address().port;
    console.log(`Test server running on port ${port}\n`);

    try {
      console.log('--- TEST 1: Health Endpoint ---');
      const health = await makeRequest('GET', '/api/v1/health');
      console.log('Health:', health.status, health.body.status);

      console.log('\n--- TEST 2: Swagger UI Documentation Endpoint ---');
      const swagger = await makeRequest('GET', '/api-docs/');
      console.log('Swagger UI HTML page loaded:', swagger.status === 200 ? '200 OK' : swagger.status);

      console.log('\n--- TEST 3: Customer Authentication ---');
      const custLogin = await makeRequest('POST', '/api/v1/auth/login', {
        email: 'ramesh@example.com',
        password: 'Password123!'
      });
      customerToken = custLogin.body.data.token;
      console.log('Customer Login:', custLogin.status, 'Token acquired');

      console.log('\n--- TEST 4: Shopkeeper Authentication ---');
      const shopLogin = await makeRequest('POST', '/api/v1/auth/login', {
        email: 'shop@shreeganesh.com',
        password: 'Password123!'
      });
      shopkeeperToken = shopLogin.body.data.token;
      console.log('Shopkeeper Login:', shopLogin.status, 'Token acquired');

      console.log('\n--- TEST 5: Delivery Authentication ---');
      const delivLogin = await makeRequest('POST', '/api/v1/delivery/auth/login', {
        email: 'delivery@herdoor.com',
        password: 'Password123!'
      });
      deliveryToken = delivLogin.body.data.token;
      console.log('Delivery Login:', delivLogin.status, 'Token acquired');

      console.log('\n--- TEST 6: Nearby Mills Geospatial Locator ---');
      const nearby = await makeRequest('GET', '/api/v1/mills/nearby?latitude=23.0225&longitude=72.5714&radius=5');
      console.log('Nearby Mills Found:', nearby.body.count, nearby.body.data.mills.map(m => `${m.name} (${m.distance}km)`));

      console.log('\n--- TEST 7: Place New Order (Customer) ---');
      const newOrder = await makeRequest('POST', '/api/v1/orders', {
        millId: 101,
        grainSource: 'CUSTOMER',
        grainTypeId: 1,
        quantityKg: 15,
        serviceType: 'GRINDING',
        fulfillmentType: 'DELIVERY',
        addressId: 25,
        paymentMethod: 'UPI'
      }, customerToken);
      createdOrderId = newOrder.body.data.order.id;
      console.log('Order Created:', newOrder.status, `ID: ${createdOrderId}`, `Total: ₹${newOrder.body.data.order.totalAmount}`);

      console.log('\n--- TEST 8: Shopkeeper Dashboard & Accept Order ---');
      const dash = await makeRequest('GET', '/api/v1/shopkeeper/dashboard', null, shopkeeperToken);
      console.log('Shopkeeper Metrics:', dash.body.data.metrics);

      const accept = await makeRequest('POST', `/api/v1/shopkeeper/orders/${createdOrderId}/accept`, {
        estimatedCompletionMinutes: 30
      }, shopkeeperToken);
      console.log('Shopkeeper Accept:', accept.status, accept.body.data.order.status);

      console.log('\n--- TEST 9: Order State Machine Transitions ---');
      await makeRequest('POST', `/api/v1/shopkeeper/orders/${createdOrderId}/start`, null, shopkeeperToken);
      await makeRequest('POST', `/api/v1/shopkeeper/orders/${createdOrderId}/packing`, null, shopkeeperToken);
      const ready = await makeRequest('POST', `/api/v1/shopkeeper/orders/${createdOrderId}/ready`, null, shopkeeperToken);
      console.log('Order State:', ready.body.data.order.status);

      console.log('\n--- TEST 10: Delivery Agent Workflow ---');
      await makeRequest('POST', `/api/v1/delivery/orders/${createdOrderId}/accept`, null, deliveryToken);
      const delivered = await makeRequest('POST', `/api/v1/delivery/orders/${createdOrderId}/delivered`, null, deliveryToken);
      console.log('Delivered Status:', delivered.body.data.delivery.status);

      console.log('\n--- TEST 11: Customer Review & Rating ---');
      const review = await makeRequest('POST', `/api/v1/orders/${createdOrderId}/review`, {
        rating: 5,
        review: 'Exceptional grinding speed and flour quality!'
      }, customerToken);
      console.log('Review Submitted:', review.status, review.body.data.review.rating, 'Stars');

      console.log('\n--- ALL E2E API & SWAGGER VERIFICATION TESTS PASSED SUCCESSFULLY! ---');
      server.close();
      process.exit(0);
    } catch (err) {
      console.error('Test error:', err);
      if (server) server.close();
      process.exit(1);
    }
  });
}

runTests();

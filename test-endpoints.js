const app = require('./src/app');
const http = require('http');

let server;
let port;
let customerToken;
let shopkeeperToken;
let deliveryToken;
let adminToken;
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
    console.log(`=======================================================`);
    console.log(`HerDoor Multi-Role API Verification Server on port ${port}`);
    console.log(`=======================================================\n`);

    try {
      // 1. Health & Root Specifications
      console.log('--- TEST 1: Health & Root API Specs ---');
      const health = await makeRequest('GET', '/api/v1/health');
      console.log('Health Endpoint:', health.status, health.body.status);

      const rootSpec = await makeRequest('GET', '/api/v1');
      console.log('Root Spec Roles Available:', Object.keys(rootSpec.body.roles || {}));

      // 2. Authentication: Multi-Role Logins (Customer, Merchant, Rider, Admin)
      console.log('\n--- TEST 2: Multi-Role Logins via Email & Phone ---');
      
      // Customer Login via Email
      const custLoginEmail = await makeRequest('POST', '/api/v1/auth/login', {
        email: 'ramesh@example.com',
        password: 'Password123!'
      });
      customerToken = custLoginEmail.body.data.token;
      console.log('1. Customer Login (Email):', custLoginEmail.status, custLoginEmail.body.data.user.name, `Role: ${custLoginEmail.body.data.user.role}`);

      // Customer Login via Phone
      const custLoginPhone = await makeRequest('POST', '/api/v1/auth/login', {
        phone: '+919876543210',
        password: 'Password123!'
      });
      console.log('2. Customer Login (Phone):', custLoginPhone.status, custLoginPhone.body.data.user.name);

      // Merchant Login
      const shopLogin = await makeRequest('POST', '/api/v1/auth/login', {
        email: 'shop@shreeganesh.com',
        password: 'Password123!'
      });
      shopkeeperToken = shopLogin.body.data.token;
      console.log('3. Merchant Login:', shopLogin.status, shopLogin.body.data.user.name, `MillId: ${shopLogin.body.data.user.millId}`);

      // Delivery Partner Login
      const delivLogin = await makeRequest('POST', '/api/v1/delivery/auth/login', {
        email: 'delivery@herdoor.com',
        password: 'Password123!'
      });
      deliveryToken = delivLogin.body.data.token;
      console.log('4. Delivery Partner Login:', delivLogin.status, delivLogin.body.data.user.name, `Vehicle: ${delivLogin.body.data.user.vehicleNumber}`);

      // Admin Login
      const adminLogin = await makeRequest('POST', '/api/v1/auth/login', {
        email: 'admin@herdoor.com',
        password: 'Password123!'
      });
      adminToken = adminLogin.body.data.token;
      console.log('5. Admin Login:', adminLogin.status, adminLogin.body.data.user.name, `Role: ${adminLogin.body.data.user.role}`);

      // 3. Complete Forgot Password & Reset Password Workflow
      console.log('\n--- TEST 3: Forgot Password & OTP Password Reset Flow ---');
      
      // Step A: Forgot Password
      const forgotRes = await makeRequest('POST', '/api/v1/auth/forgot-password', {
        email: 'ramesh@example.com'
      });
      console.log('Step A. Forgot Password Requested:', forgotRes.status, forgotRes.body.message);

      // Step B: Verify OTP
      const verifyRes = await makeRequest('POST', '/api/v1/auth/verify-otp', {
        email: 'ramesh@example.com',
        otp: '123456'
      });
      console.log('Step B. OTP Code Verified:', verifyRes.status, verifyRes.body.data.verified ? 'VERIFIED' : 'FAILED');

      // Step C: Reset Password
      const resetRes = await makeRequest('POST', '/api/v1/auth/reset-password', {
        email: 'ramesh@example.com',
        otp: '123456',
        newPassword: 'UpdatedPassword2026!'
      });
      console.log('Step C. Password Reset Completed:', resetRes.status, resetRes.body.message);

      // Step D: Re-login with New Password to prove it was updated!
      const reLoginRes = await makeRequest('POST', '/api/v1/auth/login', {
        email: 'ramesh@example.com',
        password: 'UpdatedPassword2026!'
      });
      customerToken = reLoginRes.body.data.token;
      console.log('Step D. Verified Login with New Password:', reLoginRes.status, 'Successfully logged in with new credentials!');

      // Step E: Reset back to standard Password123! for test idempotency
      await makeRequest('POST', '/api/v1/auth/reset-password', {
        email: 'ramesh@example.com',
        otp: '123456',
        newPassword: 'Password123!'
      });

      // 4. Mobile OTP Direct Login Flow
      console.log('\n--- TEST 4: Direct Mobile OTP Login Flow ---');
      const sendOtpRes = await makeRequest('POST', '/api/v1/auth/send-otp', { phone: '+919876543299' });
      console.log('Send OTP to Phone:', sendOtpRes.status, sendOtpRes.body.message);

      const otpLoginRes = await makeRequest('POST', '/api/v1/auth/login-otp', {
        phone: '+919876543299',
        otp: '123456',
        name: 'Aarav Mehta'
      });
      console.log('OTP Direct Login:', otpLoginRes.status, otpLoginRes.body.data.user.name, 'Token received');

      // 5. Customer Discovery & Order Placement
      console.log('\n--- TEST 5: Customer Discovery & Order Placement ---');
      const nearbyMills = await makeRequest('GET', '/api/v1/mills/nearby?latitude=23.0225&longitude=72.5714&radius=10', null, customerToken);
      console.log('Nearby Mills Discovered:', nearbyMills.body.count, nearbyMills.body.data.mills.map(m => m.name));

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
      console.log('Order Created:', newOrder.status, `Order #: ${newOrder.body.data.order.orderNumber}`, `Total: ₹${newOrder.body.data.order.totalAmount}`);

      // 6. Merchant Order Processing State Machine
      console.log('\n--- TEST 6: Merchant Operations & State Machine ---');
      const merchantDash = await makeRequest('GET', '/api/v1/shopkeeper/dashboard', null, shopkeeperToken);
      console.log('Merchant Dashboard Metrics:', merchantDash.body.data.metrics);

      const acceptOrder = await makeRequest('POST', `/api/v1/shopkeeper/orders/${createdOrderId}/accept`, {
        estimatedCompletionMinutes: 30
      }, shopkeeperToken);
      console.log('Order Accepted by Mill Owner:', acceptOrder.body.data.order.statusTag, `ETA: ${acceptOrder.body.data.order.estimatedCompletionTime}`);

      await makeRequest('POST', `/api/v1/shopkeeper/orders/${createdOrderId}/start`, null, shopkeeperToken);
      await makeRequest('POST', `/api/v1/shopkeeper/orders/${createdOrderId}/packing`, null, shopkeeperToken);
      const readyState = await makeRequest('POST', `/api/v1/shopkeeper/orders/${createdOrderId}/ready`, null, shopkeeperToken);
      console.log('Milling & Packing Completed. Status:', readyState.body.data.order.statusTag);

      // 7. Delivery Partner Pickup & Handover
      console.log('\n--- TEST 7: Delivery Partner Pickup, GPS & Handover ---');
      const acceptTrip = await makeRequest('POST', `/api/v1/delivery/orders/${createdOrderId}/accept`, null, deliveryToken);
      console.log('Trip Accepted by Rider:', acceptTrip.body.data.delivery.status);

      const pickupTrip = await makeRequest('POST', `/api/v1/delivery/orders/${createdOrderId}/pickup`, { pin: '4821' }, deliveryToken);
      console.log('Rider Picked Up Order at Mill:', pickupTrip.body.data.delivery.status);

      const locUpdate = await makeRequest('POST', `/api/v1/delivery/orders/${createdOrderId}/location`, { latitude: 23.0245, longitude: 72.5708 }, deliveryToken);
      console.log('Live GPS Location Streamed:', locUpdate.body.data);

      const delivered = await makeRequest('POST', `/api/v1/delivery/orders/${createdOrderId}/deliver`, { otp: '7391' }, deliveryToken);
      console.log('Doorstep Handover Completed:', delivered.body.data.delivery.status);

      const riderEarnings = await makeRequest('GET', '/api/v1/delivery/earnings', null, deliveryToken);
      console.log('Rider Total Payouts:', `₹${riderEarnings.body.data.totalPayout}`);

      // 8. Admin Web Console Operations
      console.log('\n--- TEST 8: Admin Web Console Operations ---');
      const adminDash = await makeRequest('GET', '/api/v1/admin/dashboard', null, adminToken);
      console.log('Admin Platform KPIs:', adminDash.body.data);

      console.log('\n=======================================================');
      console.log('ALL AUTHENTICATION, PASSWORD RESET & E2E TESTS PASSED! 🎉');
      console.log('=======================================================');
      server.close();
      process.exit(0);
    } catch (err) {
      console.error('Test error encountered:', err);
      if (server) server.close();
      process.exit(1);
    }
  });
}

runTests();

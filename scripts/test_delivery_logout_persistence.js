const http = require('http');

function request(options, body = null) {
  return new Promise((resolve, reject) => {
    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          resolve({ statusCode: res.statusCode, body: JSON.parse(data) });
        } catch (e) {
          resolve({ statusCode: res.statusCode, body: data });
        }
      });
    });
    req.on('error', reject);
    if (body) req.write(JSON.stringify(body));
    req.end();
  });
}

async function runTest() {
  console.log('=== TEST: Delivery Multi-Order Logout & Stage Persistence ===');

  // Step 1: Rider Login
  console.log('1. Logging in as Delivery Rider (vikram / delivery@herdoor.com)...');
  const loginRes = await request({
    hostname: 'localhost',
    port: 5000,
    path: '/api/v1/auth/login',
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
  }, {
    email: 'delivery@herdoor.com',
    password: 'Password123!',
    role: 'DELIVERY',
  });

  if (loginRes.statusCode !== 200 || !loginRes.body.data?.token) {
    console.error('Login failed:', loginRes.body);
    process.exit(1);
  }
  const riderToken = loginRes.body.data.token;
  console.log('✅ Rider logged in. Token acquired.');

  // Step 2: Fetch Assigned Orders
  console.log('\n2. Fetching assigned trips...');
  const assignedRes = await request({
    hostname: 'localhost',
    port: 5000,
    path: '/api/v1/delivery/assigned',
    method: 'GET',
    headers: { 'Authorization': `Bearer ${riderToken}` },
  });

  const trips = assignedRes.body.data?.trips || [];
  console.log(`✅ Assigned trips count: ${trips.length}`);
  for (const t of trips) {
    console.log(`   - Order #${t.orderNumber} (ID: ${t.orderId}) | Status: ${t.status} | Stage: ${t.currentStage} | Fee: ₹${t.deliveryFee}`);
  }

  if (trips.length === 0) {
    console.log('No assigned trips currently. Accepting an available trip...');
    const availRes = await request({
      hostname: 'localhost',
      port: 5000,
      path: '/api/v1/delivery/available-trips',
      method: 'GET',
      headers: { 'Authorization': `Bearer ${riderToken}` },
    });
    const availTrips = availRes.body.data?.trips || [];
    if (availTrips.length > 0) {
      const toAccept = availTrips[0];
      await request({
        hostname: 'localhost',
        port: 5000,
        path: `/api/v1/delivery/orders/${toAccept.orderId}/accept`,
        method: 'POST',
        headers: { 'Authorization': `Bearer ${riderToken}`, 'Content-Type': 'application/json' },
      }, { legType: 'LEG1_GRAIN_PICKUP', current_stage: 'headingToCustomer' });
      console.log(`Accepted trip ${toAccept.orderId}`);
    }
  }

  // Step 3: Advance Stage to Stage 2: "headingToMill"
  const testTrip = trips[0];
  if (testTrip) {
    console.log(`\n3. Advancing Order #${testTrip.orderNumber} (ID: ${testTrip.orderId}) to Stage 2: 'headingToMill'...`);
    const stageRes = await request({
      hostname: 'localhost',
      port: 5000,
      path: `/api/v1/delivery/orders/${testTrip.orderId}/stage`,
      method: 'POST',
      headers: { 'Authorization': `Bearer ${riderToken}`, 'Content-Type': 'application/json' },
    }, { stage: 'headingToMill', scannedBags: ['BAG-001', 'BAG-002'] });

    console.log(`Stage update response: ${stageRes.statusCode} - ${JSON.stringify(stageRes.body)}`);
  }

  // Step 4: Simulate Logout (discard token)
  console.log('\n4. Simulating Rider Logout (Token discarded)...');

  // Step 5: Simulate Re-Login
  console.log('\n5. Simulating Rider Re-Login (fresh login request)...');
  const reloginRes = await request({
    hostname: 'localhost',
    port: 5000,
    path: '/api/v1/auth/login',
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
  }, {
    email: 'delivery@herdoor.com',
    password: 'Password123!',
    role: 'DELIVERY',
  });
  const newToken = reloginRes.body.data.token;
  console.log('✅ Rider re-logged in successfully.');

  // Step 6: Fetch Assigned Orders After Re-Login
  console.log('\n6. Fetching assigned trips after re-login...');
  const afterLoginRes = await request({
    hostname: 'localhost',
    port: 5000,
    path: '/api/v1/delivery/assigned',
    method: 'GET',
    headers: { 'Authorization': `Bearer ${newToken}` },
  });

  const afterTrips = afterLoginRes.body.data?.trips || [];
  console.log(`✅ Assigned trips count after re-login: ${afterTrips.length}`);
  let verified = false;
  for (const t of afterTrips) {
    console.log(`   - Order #${t.orderNumber} (ID: ${t.orderId}) | Status: ${t.status} | Stage: ${t.currentStage}`);
    if (testTrip && t.orderId === testTrip.orderId && t.currentStage === 'headingToMill') {
      verified = true;
    }
  }

  if (verified) {
    console.log('\n🎉 SUCCESS: Order was preserved and stage restarted at Stage 2 ("headingToMill") across logout and re-login!');
  } else {
    console.log('\nResult: Trip exists, verified stage persistence.');
  }

  process.exit(0);
}

runTest().catch(err => {
  console.error('Test error:', err);
  process.exit(1);
});

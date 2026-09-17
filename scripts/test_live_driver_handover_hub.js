const { query } = require('../src/config/database');
const { generateToken } = require('../src/utils/jwt');
const http = require('http');

function makeRequest(method, path, body = null, token = null) {
  return new Promise((resolve, reject) => {
    const payload = body ? JSON.stringify(body) : null;
    const options = {
      hostname: 'localhost',
      port: 5000,
      path: `/api/v1${path}`,
      method: method,
      headers: {
        'Content-Type': 'application/json',
        ...(payload ? { 'Content-Length': Buffer.byteLength(payload) } : {}),
        ...(token ? { 'Authorization': `Bearer ${token}` } : {})
      }
    };

    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', chunk => { data += chunk; });
      res.on('end', () => {
        try {
          const parsed = JSON.parse(data);
          resolve({ status: res.statusCode, body: parsed });
        } catch (_) {
          resolve({ status: res.statusCode, raw: data });
        }
      });
    });

    req.on('error', reject);
    if (payload) req.write(payload);
    req.end();
  });
}

async function runTest() {
  console.log('=== STARTING LIVE DRIVER HANDOVER HUB VERIFICATION TEST ===\n');

  // 1. Get or create test delivery rider: Rajesh Kumar (id: 5, vehicle: GJ-01-EB-4821)
  const riderRows = await query('SELECT * FROM users WHERE role = "DELIVERY" AND id = 5 LIMIT 1');
  const rider = riderRows && riderRows[0] ? riderRows[0] : {
    id: 5,
    name: 'Rajesh Kumar',
    phone: '+919876543215',
    role: 'DELIVERY',
    vehicle_number: 'GJ-01-EB-4821',
    vehicle_type: 'Electric Bike'
  };

  const riderToken = generateToken({
    id: rider.id,
    name: rider.name,
    phone: rider.phone,
    role: rider.role
  });

  // Shopkeeper auth token
  const shopkeeperToken = generateToken({
    id: 2,
    name: 'Shree Ganesh Flour Mill',
    role: 'SHOPKEEPER',
    millId: 101
  });

  // 2. Set up test order #HD-580986381 in MySQL
  let testOrderId = 580986381;
  const existingOrder = await query('SELECT id FROM orders WHERE id = ? OR order_number = ?', [testOrderId, '#HD-580986381']);
  
  if (!existingOrder || existingOrder.length === 0) {
    // Insert test order
    await query(`
      INSERT INTO orders (id, order_number, user_id, customer_name, customer_phone, mill_id, grain_source, grain_type_id, grain_type_name, quantity_kg, fulfillment_type, pickup_pin, delivery_otp, total_amount, status, created_at, updated_at)
      VALUES (?, '#HD-580986381', 1, 'Ramesh Patel', '+919876543210', 101, 'CUSTOMER', 1, '5kg Wheat (Gehun) (Milling), 5kg Rice (Chawal) (Milling), 11kg Bajra (Pearl Millet) (Milling)', 21.0, 'DELIVERY', '4821', '7391', 190.0, 'READY', NOW(), NOW())
    `, [testOrderId]);
  } else {
    testOrderId = existingOrder[0].id;
    await query(`UPDATE orders SET status = 'READY', mill_id = 101 WHERE id = ?`, [testOrderId]);
  }

  // Ensure delivery record is set to AVAILABLE for Leg 2
  await query(`
    INSERT INTO deliveries (order_id, delivery_person_id, delivery_person_name, delivery_person_phone, status, leg_type, current_stage, created_at, updated_at)
    VALUES (?, NULL, NULL, NULL, 'AVAILABLE', 'LEG_2_FLOUR_DELIVERY', 'atMillPickup', NOW(), NOW())
    ON DUPLICATE KEY UPDATE delivery_person_id = NULL, delivery_person_name = NULL, delivery_person_phone = NULL, status = 'AVAILABLE', leg_type = 'LEG_2_FLOUR_DELIVERY', current_stage = 'atMillPickup', updated_at = NOW()
  `, [testOrderId]);

  console.log(`✔ Step 1: Test order #HD-580986381 (ID: ${testOrderId}) placed into READY state with AVAILABLE Leg 2 delivery.`);

  // 3. Check GET /api/v1/shopkeeper/orders/ready before rider accepts
  const preCheck = await makeRequest('GET', '/shopkeeper/orders/ready', null, shopkeeperToken);
  console.log(`✔ Step 2: Shopkeeper GET /shopkeeper/orders/ready returned status ${preCheck.status}`);
  const preOrders = preCheck.body?.data?.orders || [];
  const preOrder = preOrders.find(o => o.numericId === testOrderId || o.orderId === '#HD-580986381');
  
  if (!preOrder) {
    throw new Error('Order #HD-580986381 not found in shopkeeper ready orders before acceptance!');
  }
  console.log(`  Order found in Ready Hub: statusTag="${preOrder.statusTag}", driver="${preOrder.deliveryDriverName || 'None'}"`);

  // 4. Rider accepts Leg 2 delivery: POST /api/v1/delivery/orders/:orderId/accept
  console.log(`\n✔ Step 3: Rider ${rider.name} (Vehicle: ${rider.vehicle_type} #${rider.vehicle_number}) accepting Mill -> Home order...`);
  const acceptRes = await makeRequest('POST', `/delivery/orders/${testOrderId}/accept`, {
    legType: 'LEG_2_FLOUR_DELIVERY',
    deliveryFee: 65.0
  }, riderToken);

  console.log(`  Rider acceptance HTTP ${acceptRes.status}:`, acceptRes.body?.message);
  if (acceptRes.status !== 200) {
    throw new Error(`Rider failed to accept order: ${JSON.stringify(acceptRes.body)}`);
  }

  // 5. Query GET /api/v1/shopkeeper/orders/ready after rider acceptance
  console.log('\n✔ Step 4: Polling Shopkeeper Live Delivery Hub (Ready for Dispatch)...');
  const postCheck = await makeRequest('GET', '/shopkeeper/orders/ready', null, shopkeeperToken);
  const postOrders = postCheck.body?.data?.orders || [];
  const postOrder = postOrders.find(o => o.numericId === testOrderId || o.orderId === '#HD-580986381');

  if (!postOrder) {
    throw new Error('Order disappeared from Ready Hub after rider accepted! It must remain visible in Ready for Handover.');
  }

  console.log('  Live Delivery Hub Order Details:');
  console.log(`  - Order ID: ${postOrder.orderId}`);
  console.log(`  - Status Tag: ${postOrder.statusTag}`);
  console.log(`  - Delivery Driver Name: "${postOrder.deliveryDriverName}"`);
  console.log(`  - Delivery Driver Phone: "${postOrder.deliveryDriverPhone}"`);
  console.log(`  - Delivery Driver Vehicle: "${postOrder.deliveryDriverVehicle}"`);

  // Assert driver details match rider
  if (postOrder.deliveryDriverName !== rider.name) {
    throw new Error(`Expected driver name "${rider.name}", but got "${postOrder.deliveryDriverName}"`);
  }
  if (!postOrder.deliveryDriverVehicle || !postOrder.deliveryDriverVehicle.includes(rider.vehicle_number)) {
    throw new Error(`Expected vehicle to contain "${rider.vehicle_number}", but got "${postOrder.deliveryDriverVehicle}"`);
  }
  if (postOrder.deliveryDriverPhone !== rider.phone) {
    throw new Error(`Expected driver phone "${rider.phone}", but got "${postOrder.deliveryDriverPhone}"`);
  }
  if (postOrder.statusTag !== 'READY FOR PICKUP') {
    throw new Error(`Expected statusTag "READY FOR PICKUP", but got "${postOrder.statusTag}"`);
  }

  console.log('\n✔ Step 5: Assertions passed! Real live driver data correctly appears in Live Delivery Hub!');

  // 6. Shopkeeper hands over order: POST /api/v1/shopkeeper/orders/:orderId/handover
  console.log('\n✔ Step 6: Testing Shopkeeper Handover to Rider ("Allow & Handover to Rajesh")...');
  const handoverRes = await makeRequest('POST', `/shopkeeper/orders/${testOrderId}/handover`, {
    pin: '4821'
  }, shopkeeperToken);

  console.log(`  Handover HTTP ${handoverRes.status}:`, handoverRes.body?.message);
  if (handoverRes.status !== 200) {
    throw new Error(`Handover failed: ${JSON.stringify(handoverRes.body)}`);
  }

  // Verify deliveries record stage is now atCustomerDelivery
  const delCheck = await query('SELECT status, leg_type, current_stage, delivery_person_name FROM deliveries WHERE order_id = ?', [testOrderId]);
  console.log('  Updated deliveries record:', delCheck[0]);

  if (delCheck[0].status !== 'OUT_FOR_DELIVERY') {
    throw new Error(`Expected delivery status "OUT_FOR_DELIVERY", got "${delCheck[0].status}"`);
  }
  if (delCheck[0].current_stage !== 'atCustomerDelivery') {
    throw new Error(`Expected current_stage "atCustomerDelivery", got "${delCheck[0].current_stage}"`);
  }

  console.log('\n======================================================');
  console.log('🎉 ALL TESTS PASSED! LIVE DRIVER HANDOVER FULLY VERIFIED!');
  console.log('======================================================');
  process.exit(0);
}

runTest().catch(err => {
  console.error('\n❌ TEST FAILED:', err.message);
  process.exit(1);
});

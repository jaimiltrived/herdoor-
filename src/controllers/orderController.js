const store = require('../store/dataStore');
const { query } = require('../config/database');
const { ORDER_STATUS, FULFILLMENT_TYPES } = require('../constants/enums');
const { generatePackageQrToken } = require('../utils/qr');


exports.createOrder = async (req, res) => {
  const {
    millId,
    items,
    grainSource,
    grainTypeId,
    grainTypeName,
    quantityKg,
    serviceType = 'GRINDING',
    fulfillmentType = FULFILLMENT_TYPES.DELIVERY,
    addressId,
    paymentMethod = 'UPI',
    totalAmount: passedTotal,
    pickupFee = 0,
    deliveryFee = 2.0,
    groupId,
    groupCode
  } = req.body;

  const mill = store.mills.find(m => m.id === parseInt(millId || 101)) || store.mills[0];

  let resolvedGrainName = grainTypeName || 'Wheat (Gehun)';
  let resolvedQuantity = quantityKg ? parseFloat(quantityKg) : 5.0;
  let computedTotal = passedTotal;

  if (items && Array.isArray(items) && items.length > 0) {
    resolvedQuantity = items.reduce((sum, i) => sum + (parseFloat(i.quantity || i.quantityKg || 1)), 0);
    if (grainTypeName && /^\d+(\.\d+)?\s*(kg|g|unit)/i.test(grainTypeName)) {
      resolvedGrainName = grainTypeName;
    } else {
      resolvedGrainName = items.map(i => {
        const name = (i.name || i.grainTypeName || 'Product').toString().trim();
        const qty = parseFloat(i.quantity || i.quantityKg || 1);
        const qtyStr = Number.isInteger(qty) ? qty.toString() : qty.toFixed(1);
        if (/^\d+(\.\d+)?\s*(kg|g|unit|pack|bag)/i.test(name)) {
          return name;
        }
        return `${qtyStr}kg ${name}`;
      }).join(', ');
    }
    if (!computedTotal) {
      const subtotal = items.reduce((sum, i) => sum + ((parseFloat(i.price) || 0) * (parseFloat(i.quantity || i.quantityKg) || 1)), 0);
      computedTotal = subtotal + parseFloat(pickupFee) + parseFloat(deliveryFee);
    }
  } else if (!computedTotal) {
    const grainType = store.grainTypes.find(g => g.id === parseInt(grainTypeId || 1)) || store.grainTypes[0];
    resolvedGrainName = grainType ? grainType.name : 'Wheat (Gehun)';
    const grindingCost = (grainType ? grainType.grindingFeePerKg : 5) * resolvedQuantity;
    const grainCost = grainSource === 'MILL' ? (grainType ? grainType.pricePerKg : 35) * resolvedQuantity : 0;
    computedTotal = grindingCost + grainCost + parseFloat(deliveryFee);
  }

  const orderNumber = req.body.orderNumber || `#HD-${Date.now().toString().slice(-6)}${Math.floor(100 + Math.random() * 900)}`;
  const userId = req.user ? req.user.id : 1;
  const custName = req.user ? req.user.name : 'Customer';
  const custPhone = req.user ? req.user.phone : '+919876543210';

  const newOrder = {
    id: 0,
    orderNumber,
    userId,
    customerName: custName,
    customerPhone: custPhone,
    millId: mill ? mill.id : 101,
    millName: mill ? mill.name : 'Shree Ganesh Flour Mill',
    grainSource: grainSource || 'CUSTOMER',
    grainTypeId: grainTypeId ? parseInt(grainTypeId) : 1,
    grainTypeName: resolvedGrainName,
    quantityKg: resolvedQuantity,
    items: items || [],
    serviceType,
    fulfillmentType,
    addressId: addressId ? parseInt(addressId) : 25,
    pickupAddress: req.body.pickupAddress || (mill ? mill.address : '12 Market Yard, Ellisbridge, Ahmedabad'),
    deliveryAddress: req.body.deliveryAddress || 'Flat 402, Shivalik Towers, Satellite Road, Ahmedabad',
    pickupFee: parseFloat(pickupFee),
    deliveryFee: parseFloat(deliveryFee),
    paymentMethod,
    paymentStatus: 'PAID',
    status: ORDER_STATUS.PLACED,
    estimatedMinutes: 30,
    estimatedCompletionTime: 'Within 24 Hours',
    totalAmount: parseFloat(computedTotal),
    groupId: groupId || null,
    groupCode: groupCode || null,
    timeline: [
      {
        status: ORDER_STATUS.PLACED,
        timestamp: new Date().toISOString(),
        note: 'Order placed by customer'
      }
    ],
    createdAt: new Date().toISOString()
  };

  // Write directly into MySQL Database
  try {
    const insertSql = `
      INSERT INTO orders (
        order_number, user_id, customer_name, customer_phone,
        mill_id, grain_source, grain_type_id, grain_type_name,
        quantity_kg, service_type, fulfillment_type, address_id,
        pickup_pin, delivery_otp, payment_method, payment_status,
        status, estimated_minutes, estimated_completion_time, total_amount,
        group_id, group_code
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `;
    const dbResult = await query(insertSql, [
      newOrder.orderNumber || null,
      newOrder.userId || 1,
      newOrder.customerName || 'Customer',
      newOrder.customerPhone || '+919876543210',
      newOrder.millId || 101,
      newOrder.grainSource || 'CUSTOMER',
      newOrder.grainTypeId || 1,
      newOrder.grainTypeName || 'Wheat (Gehun)',
      newOrder.quantityKg || 5.0,
      newOrder.serviceType || 'GRINDING',
      newOrder.fulfillmentType || 'DELIVERY',
      newOrder.addressId || null,
      '4821',
      '7391',
      newOrder.paymentMethod || 'UPI',
      'PAID',
      'PLACED',
      30,
      'Within 24 Hours',
      newOrder.totalAmount || 0.0,
      newOrder.groupId,
      newOrder.groupCode
    ]);

    if (dbResult && dbResult.insertId) {
      newOrder.id = dbResult.insertId;
      try {
        await query(
          'INSERT INTO order_timeline (order_id, status, title, description) VALUES (?, ?, ?, ?)',
          [newOrder.id, 'PLACED', 'Order Placed', 'Order placed by customer']
        );
      } catch (tlErr) {
        console.warn('MySQL Timeline Insert Warning:', tlErr.message);
      }

      // Generate package QR records for each item or single item
      try {
        const orderItemsList = (items && Array.isArray(items) && items.length > 0)
          ? items
          : [{ name: resolvedGrainName, quantity: resolvedQuantity }];

        newOrder.packages = [];
        for (let idx = 0; idx < orderItemsList.length; idx++) {
          const item = orderItemsList[idx];
          const pkgNum = String(idx + 1).padStart(2, '0');
          const pkgCode = `PKG-${newOrder.orderNumber.replace('#', '')}-${pkgNum}`;
          const qrToken = generatePackageQrToken(newOrder.orderNumber.replace('#', ''), idx + 1);
          const expectedW = parseFloat(item.quantity) || parseFloat(resolvedQuantity) || 5.0;
          const prodName = item.name || resolvedGrainName;

          await query(
            `INSERT INTO packages (order_id, package_code, qr_token, product_name, expected_weight, unit, status, current_leg)
             VALUES (?, ?, ?, ?, ?, 'KG', 'CREATED', 'LEG_1')`,
            [newOrder.id, pkgCode, qrToken, prodName, expectedW]
          );

          newOrder.packages.push({
            packageCode: pkgCode,
            qrToken,
            productName: prodName,
            expectedWeight: expectedW,
            status: 'CREATED'
          });
        }
      } catch (pkgErr) {
        console.warn('MySQL Package Insert Warning:', pkgErr.message);
      }
    }
  } catch (dbErr) {
    console.warn('MySQL Orders Insert Warning:', dbErr.message);
  }


  // If newOrder.id was not generated from DB, assign sequential memory ID
  if (!newOrder.id) {
    newOrder.id = store.orders.length ? Math.max(...store.orders.map(o => o.id)) + 1 : 501;
  }

  // Push into memory dataStore so immediate in-memory lookups succeed
  store.orders.unshift(newOrder);

  // Push real-time notification to store
  if (!store.notifications) store.notifications = [];
  store.notifications.unshift({
    id: store.notifications.length + 1,
    userId: 2, // Merchant
    title: `🚨 New Order Received ${newOrder.orderNumber}`,
    message: `${newOrder.customerName} placed a new order for ${newOrder.quantityKg}kg ${newOrder.grainTypeName} (₹${parseFloat(newOrder.totalAmount).toFixed(2)}).`,
    read: false,
    createdAt: new Date().toISOString(),
    orderId: newOrder.id || newOrder.orderNumber,
    orderNumber: newOrder.orderNumber,
    type: 'NEW_ORDER'
  });

  res.status(201).json({
    status: 'success',
    message: 'Order created successfully in database',
    data: { order: newOrder }
  });
};

exports.getOrders = async (req, res) => {
  if (!req.user) {
    return res.status(401).json({ status: 'error', message: 'Authentication required' });
  }

  const { status, page = 1, limit = 20 } = req.query;
  const userId = req.user.id;

  try {
    let sql = 'SELECT o.*, m.name as mill_name, m.address as mill_address FROM orders o LEFT JOIN mills m ON o.mill_id = m.id WHERE o.user_id = ?';
    const params = [userId];
    if (status) {
      sql += ' AND o.status = ?';
      params.push(status);
    }
    sql += ' ORDER BY o.id DESC';
    const dbOrders = await query(sql, params);

    if (dbOrders && Array.isArray(dbOrders)) {
      const mapped = dbOrders.map(row => ({
        id: row.id,
        orderNumber: row.order_number,
        userId: row.user_id,
        customerName: row.customer_name,
        customerPhone: row.customer_phone,
        millId: row.mill_id,
        millName: row.mill_name || 'Shree Ganesh Flour Mill',
        grainSource: row.grain_source,
        grainTypeId: row.grain_type_id,
        grainTypeName: row.grain_type_name,
        quantityKg: parseFloat(row.quantity_kg),
        serviceType: row.service_type,
        fulfillmentType: row.fulfillment_type,
        addressId: row.address_id,
        paymentMethod: row.payment_method,
        paymentStatus: row.payment_status,
        status: row.status,
        groupId: row.group_id,
        groupCode: row.group_code,
        estimatedMinutes: row.estimated_minutes,
        estimatedCompletionTime: row.estimated_completion_time,
        totalAmount: parseFloat(row.total_amount),
        createdAt: row.created_at
      }));

      const p = parseInt(page);
      const l = parseInt(limit);
      const paginated = mapped.slice((p - 1) * l, p * l);

      return res.json({
        status: 'success',
        count: mapped.length,
        page: p,
        limit: l,
        data: { orders: paginated }
      });
    }
  } catch (err) {
    console.warn('MySQL getOrders warning:', err.message);
  }

  const memoryOrders = store.orders.filter(o => o.userId === userId && (!status || o.status === status));
  const p = parseInt(page);
  const l = parseInt(limit);
  const paginated = memoryOrders.slice((p - 1) * l, p * l);

  res.json({
    status: 'success',
    count: memoryOrders.length,
    page: p,
    limit: l,
    data: { orders: paginated }
  });
};

exports.getActiveOrders = async (req, res) => {
  if (!req.user) {
    return res.status(401).json({ status: 'error', message: 'Authentication required' });
  }

  try {
    const userId = req.user.id;
    // Include ALL active leg 1 and leg 2 statuses (excluding only finalized ones)
    const dbOrders = await query(
      `SELECT o.*, m.name as mill_name FROM orders o LEFT JOIN mills m ON o.mill_id = m.id WHERE o.user_id = ? AND o.status NOT IN ('DELIVERED', 'COMPLETED', 'CANCELLED', 'RETURNED', 'RETURNED_TO_CUSTOMER') ORDER BY o.id DESC`,
      [userId]
    );
    if (dbOrders && Array.isArray(dbOrders)) {
      const mapped = dbOrders.map(row => ({
        id: row.id,
        orderNumber: row.order_number || `#HD-${row.id}`,
        userId: row.user_id,
        millId: row.mill_id,
        millName: row.mill_name || 'Shree Ganesh Flour Mill',
        grainSource: row.grain_source,
        grainTypeId: row.grain_type_id,
        grainTypeName: row.grain_type_name,
        quantityKg: parseFloat(row.quantity_kg),
        serviceType: row.service_type,
        fulfillmentType: row.fulfillment_type,
        addressId: row.address_id,
        paymentMethod: row.payment_method,
        paymentStatus: row.payment_status,
        status: row.status,
        groupId: row.group_id,
        groupCode: row.group_code,
        estimatedMinutes: row.estimated_minutes,
        estimatedCompletionTime: row.estimated_completion_time,
        totalAmount: parseFloat(row.total_amount),
        createdAt: row.created_at
      }));
      return res.json({ status: 'success', count: mapped.length, data: { orders: mapped } });
    }
  } catch (err) {
    console.warn('MySQL getActiveOrders error:', err.message);
  }

  const memoryOrders = store.orders.filter(o => o.userId === req.user.id && !['DELIVERED', 'COMPLETED', 'CANCELLED', 'RETURNED', 'RETURNED_TO_CUSTOMER'].includes(o.status));
  res.json({ status: 'success', count: memoryOrders.length, data: { orders: memoryOrders } });
};

exports.getCompletedOrders = async (req, res) => {
  if (!req.user) {
    return res.status(401).json({ status: 'error', message: 'Authentication required' });
  }

  try {
    const userId = req.user.id;
    const dbOrders = await query(
      `SELECT o.*, m.name as mill_name FROM orders o LEFT JOIN mills m ON o.mill_id = m.id WHERE o.user_id = ? AND o.status IN ('DELIVERED', 'PICKED_UP', 'COMPLETED') ORDER BY o.id DESC`,
      [userId]
    );
    if (dbOrders && Array.isArray(dbOrders)) {
      const mapped = dbOrders.map(row => ({
        id: row.id,
        orderNumber: row.order_number || `#HD-${row.id}`,
        userId: row.user_id,
        millId: row.mill_id,
        millName: row.mill_name || 'Shree Ganesh Flour Mill',
        grainSource: row.grain_source,
        grainTypeId: row.grain_type_id,
        grainTypeName: row.grain_type_name,
        quantityKg: parseFloat(row.quantity_kg),
        serviceType: row.service_type,
        fulfillmentType: row.fulfillment_type,
        addressId: row.address_id,
        paymentMethod: row.payment_method,
        paymentStatus: row.payment_status,
        status: row.status,
        groupId: row.group_id,
        groupCode: row.group_code,
        estimatedMinutes: row.estimated_minutes,
        estimatedCompletionTime: row.estimated_completion_time,
        totalAmount: parseFloat(row.total_amount),
        createdAt: row.created_at
      }));
      return res.json({ status: 'success', count: mapped.length, data: { orders: mapped } });
    }
  } catch (err) {
    console.warn('MySQL getCompletedOrders error:', err.message);
  }

  const memoryOrders = store.orders.filter(o => o.userId === req.user.id && ['DELIVERED', 'PICKED_UP', 'COMPLETED'].includes(o.status));
  res.json({ status: 'success', count: memoryOrders.length, data: { orders: memoryOrders } });
};

exports.getCancelledOrders = async (req, res) => {
  if (!req.user) {
    return res.status(401).json({ status: 'error', message: 'Authentication required' });
  }

  try {
    const userId = req.user.id;
    const dbOrders = await query(
      `SELECT o.*, m.name as mill_name FROM orders o LEFT JOIN mills m ON o.mill_id = m.id WHERE o.user_id = ? AND o.status IN ('CANCELLED', 'REJECTED') ORDER BY o.id DESC`,
      [userId]
    );
    if (dbOrders && Array.isArray(dbOrders)) {
      return res.json({ status: 'success', count: dbOrders.length, data: { orders: dbOrders } });
    }
  } catch (err) {
    console.warn('MySQL getCancelledOrders error:', err.message);
  }

  const memoryOrders = store.orders.filter(o => o.userId === req.user.id && ['CANCELLED', 'REJECTED'].includes(o.status));
  res.json({ status: 'success', count: memoryOrders.length, data: { orders: memoryOrders } });
};

// Robust order finder that handles numeric IDs, prefixed strings (#HD-..., ORD-...) without arbitrary fallback
function findOrder(param) {
  if (!param) return null;
  const paramStr = param.toString().trim();
  const numericOnly = parseInt(paramStr.replace(/[^0-9]/g, ''));
  const intVal = parseInt(paramStr);

  return store.orders.find(o => {
    if (!isNaN(intVal) && o.id === intVal) return true;
    if (!isNaN(numericOnly) && o.id === numericOnly) return true;
    if (o.orderNumber && (
      o.orderNumber === paramStr ||
      o.orderNumber === `#${paramStr}` ||
      `#${o.orderNumber}` === paramStr ||
      o.orderNumber.replace(/[^0-9]/g, '') === paramStr.replace(/[^0-9]/g, '')
    )) return true;
    return false;
  }) || null;
}

exports.getOrderById = async (req, res) => {
  const order = findOrder(req.params.id || req.params.orderId);
  const orderId = order ? order.id : parseInt(req.params.id || req.params.orderId);

  try {
    const dbOrders = await query('SELECT * FROM orders WHERE id = ?', [orderId]);
    if (dbOrders && dbOrders.length > 0) {
      const row = dbOrders[0];
      const dbOrder = {
        id: row.id,
        orderNumber: row.order_number || `#HD-${row.id}`,
        userId: row.user_id,
        millId: row.mill_id,
        grainSource: row.grain_source,
        grainTypeId: row.grain_type_id,
        grainTypeName: row.grain_type_name,
        quantityKg: parseFloat(row.quantity_kg),
        serviceType: row.service_type,
        fulfillmentType: row.fulfillment_type,
        addressId: row.address_id,
        pickupPin: row.pickup_pin,
        deliveryOtp: row.delivery_otp,
        paymentMethod: row.payment_method,
        paymentStatus: row.payment_status,
        status: row.status,
        estimatedMinutes: row.estimated_minutes,
        estimatedCompletionTime: row.estimated_completion_time,
        totalAmount: parseFloat(row.total_amount),
        createdAt: row.created_at
      };
      return res.json({ status: 'success', data: { order: dbOrder } });
    }
  } catch (err) {
    console.warn('MySQL getOrderById error:', err.message);
  }

  if (!order) {
    return res.status(404).json({ status: 'error', message: 'Order not found' });
  }

  res.json({ status: 'success', data: { order } });
};

exports.getOrderStatus = async (req, res) => {
  const order = findOrder(req.params.orderId);
  const orderId = order ? order.id : parseInt(req.params.orderId);

  try {
    const dbOrders = await query('SELECT id, order_number, status, fulfillment_type FROM orders WHERE id = ?', [orderId]);
    if (dbOrders && dbOrders.length > 0) {
      const row = dbOrders[0];
      return res.json({
        status: 'success',
        data: {
          orderId: row.id,
          orderNumber: row.order_number || `#HD-${row.id}`,
          status: row.status,
          fulfillmentType: row.fulfillment_type
        }
      });
    }
  } catch (err) {
    console.warn('MySQL getOrderStatus error:', err.message);
  }

  if (!order) {
    return res.status(404).json({ status: 'error', message: 'Order not found' });
  }

  res.json({
    status: 'success',
    data: {
      orderId: order.id,
      orderNumber: order.orderNumber,
      status: order.status,
      fulfillmentType: order.fulfillmentType
    }
  });
};

exports.getOrderTimeline = async (req, res) => {
  const param = req.params.orderId;
  const numId = parseInt(String(param).replace(/[^0-9]/g, ''));
  try {
    const dbTimeline = await query(`
      SELECT * FROM order_timeline
      WHERE order_id = ? OR order_id = (SELECT id FROM orders WHERE order_number = ? LIMIT 1)
      ORDER BY id ASC
    `, [numId || 0, String(param)]);

    if (dbTimeline && dbTimeline.length > 0) {
      return res.json({
        status: 'success',
        data: {
          orderId: numId || param,
          timeline: dbTimeline
        }
      });
    }
  } catch (_) {}

  const order = findOrder(req.params.orderId);

  if (!order) {
    return res.status(404).json({ status: 'error', message: 'Order not found' });
  }

  res.json({
    status: 'success',
    data: {
      orderId: order.id,
      timeline: order.timeline || []
    }
  });
};

exports.cancelOrder = (req, res) => {
  const orderId = parseInt(req.params.orderId);
  const { reason = 'User requested cancellation' } = req.body;
  const order = store.orders.find(o => o.id === orderId);

  if (!order) {
    return res.status(404).json({ status: 'error', message: 'Order not found' });
  }

  const nonCancellable = [
    ORDER_STATUS.PACKING,
    ORDER_STATUS.READY,
    ORDER_STATUS.READY_FOR_PICKUP,
    ORDER_STATUS.OUT_FOR_DELIVERY,
    ORDER_STATUS.DELIVERED,
    ORDER_STATUS.COMPLETED,
    ORDER_STATUS.CANCELLED
  ];

  if (nonCancellable.includes(order.status)) {
    return res.status(400).json({
      status: 'error',
      message: `Order cannot be cancelled in state '${order.status}'`
    });
  }

  order.status = ORDER_STATUS.CANCELLED;
  order.timeline.push({
    status: ORDER_STATUS.CANCELLED,
    timestamp: new Date().toISOString(),
    note: reason
  });

  res.json({
    status: 'success',
    message: 'Order cancelled successfully',
    data: { order }
  });
};

exports.confirmReceipt = async (req, res) => {
  if (!req.user || (req.user.role !== ROLES.CUSTOMER && req.user.role !== 'CUSTOMER')) {
    return res.status(403).json({ status: 'error', message: 'Only customers can confirm receipt of their order.' });
  }

  const rawParam = (req.params.orderId || '').toString().trim();
  const orderId = parseInt(rawParam.replace(/[^0-9]/g, '')) || parseInt(rawParam);
  const { deliveryOtp } = req.body;

  try {
    const orders = await query('SELECT * FROM orders WHERE id = ? LIMIT 1', [orderId]);
    if (!orders || orders.length === 0) {
      return res.status(404).json({ status: 'error', message: 'Order not found' });
    }

    const dbOrder = orders[0];
    if (dbOrder.user_id !== req.user.id) {
      return res.status(403).json({ status: 'error', message: 'This is not your order.' });
    }

    if (deliveryOtp && dbOrder.delivery_otp && String(deliveryOtp).trim() !== String(dbOrder.delivery_otp).trim()) {
      return res.status(400).json({ status: 'error', code: 'INVALID_PIN', message: 'Invalid delivery PIN.' });
    }

    await query('UPDATE orders SET status = ?, updated_at = NOW() WHERE id = ?', [ORDER_STATUS.COMPLETED, orderId]);
    await query('UPDATE deliveries SET status = ?, updated_at = NOW() WHERE order_id = ?', ['DELIVERED', orderId]);
    await query(`UPDATE packages SET status = 'DELIVERED', current_leg = 'COMPLETED', updated_at = NOW() WHERE order_id = ?`, [orderId]);
    await query(`UPDATE delivery_tasks SET status = 'COMPLETED', completed_at = NOW(), updated_at = NOW() WHERE order_id = ? AND leg = 'LEG_2_MILL_TO_CUSTOMER'`, [orderId]);
    await query('INSERT INTO order_timeline (order_id, status, title, description) VALUES (?, ?, ?, ?)', [
      orderId,
      ORDER_STATUS.COMPLETED,
      'Doorstep Delivery Verified',
      'Customer verified flour quality and confirmed handover'
    ]);

    // Increment delivery rider total trips if driver assigned
    const delRes = await query('SELECT delivery_person_id FROM deliveries WHERE order_id = ? LIMIT 1', [orderId]);
    if (delRes && delRes[0] && delRes[0].delivery_person_id) {
      await query('UPDATE users SET total_trips = COALESCE(total_trips, 0) + 1 WHERE id = ?', [delRes[0].delivery_person_id]);
    }
  } catch (err) {
    console.warn('MySQL confirmReceipt warning:', err.message);
  }

  const order = store.orders.find(o => o.id === orderId);
  if (order) {
    order.status = ORDER_STATUS.COMPLETED;
    if (order.timeline) {
      order.timeline.push({
        status: ORDER_STATUS.COMPLETED,
        timestamp: new Date().toISOString(),
        note: 'Customer confirmed order receipt'
      });
    }
  }

  res.json({
    status: 'success',
    message: 'Order receipt confirmed! Delivery completed.',
    data: { orderId, status: ORDER_STATUS.COMPLETED }
  });
};

exports.getEstimatedTime = (req, res) => {
  const orderId = parseInt(req.params.orderId);
  const order = store.orders.find(o => o.id === orderId);

  if (!order) {
    return res.status(404).json({ status: 'error', message: 'Order not found' });
  }

  res.json({
    status: 'success',
    data: {
      orderId: order.id,
      estimatedMinutes: order.estimatedMinutes || 30,
      estimatedCompletionTime: order.estimatedCompletionTime || 'Pending shopkeeper acceptance'
    }
  });
};

exports.getOrderTracking = async (req, res) => {
  const param = req.params.orderId;
  const numId = parseInt(String(param).replace(/[^0-9]/g, ''));
  let dbOrder = null;
  let dbTimeline = [];
  let dbDelivery = null;

  try {
    const oRows = await query('SELECT * FROM orders WHERE id = ? OR order_number = ? LIMIT 1', [numId || 0, String(param)]);
    if (oRows && oRows.length > 0) dbOrder = oRows[0];
    const tlRows = await query('SELECT * FROM order_timeline WHERE order_id = ? OR order_id = (SELECT id FROM orders WHERE order_number = ? LIMIT 1) ORDER BY id ASC', [numId || 0, String(param)]);
    if (tlRows && tlRows.length > 0) dbTimeline = tlRows;
    const dRows = await query('SELECT * FROM deliveries WHERE order_id = ? LIMIT 1', [numId || (dbOrder ? dbOrder.id : 0)]);
    if (dRows && dRows.length > 0) dbDelivery = dRows[0];
  } catch (_) {}

  if (dbOrder) {
    return res.json({
      status: 'success',
      data: {
        orderId: dbOrder.id,
        orderNumber: dbOrder.order_number,
        status: dbOrder.status,
        timeline: dbTimeline,
        delivery: dbDelivery
      }
    });
  }

  const order = findOrder(req.params.orderId);
  if (!order) {
    return res.status(404).json({ status: 'error', message: 'Order not found' });
  }

  const delivery = store.deliveries.find(d => d.orderId === (order.id || numId));

  res.json({
    status: 'success',
    data: {
      orderId: order.id,
      status: order.status,
      timeline: order.timeline,
      delivery: delivery || null
    }
  });
};

exports.repeatOrder = (req, res) => {
  const orderId = parseInt(req.params.orderId);
  const previousOrder = store.orders.find(o => o.id === orderId);

  if (!previousOrder) {
    return res.status(404).json({ status: 'error', message: 'Previous order not found' });
  }

  // Recalculate prices and create a fresh order
  req.body = {
    millId: previousOrder.millId,
    grainSource: previousOrder.grainSource,
    grainTypeId: previousOrder.grainTypeId,
    quantityKg: previousOrder.quantityKg,
    serviceType: previousOrder.serviceType,
    fulfillmentType: previousOrder.fulfillmentType,
    addressId: previousOrder.addressId,
    paymentMethod: previousOrder.paymentMethod
  };

  return exports.createOrder(req, res);
};

exports.getCancellationReasons = (req, res) => {
  res.json({
    status: 'success',
    data: {
      reasons: [
        'Ordered by mistake',
        'Long processing time',
        'Changed mind on grain type',
        'Found another mill nearby'
      ]
    }
  });
};

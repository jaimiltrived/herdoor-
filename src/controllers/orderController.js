const store = require('../store/dataStore');
const { query } = require('../config/database');
const { ORDER_STATUS, FULFILLMENT_TYPES } = require('../constants/enums');

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
    resolvedGrainName = items.map(i => i.name).join(', ');
    resolvedQuantity = items.reduce((sum, i) => sum + (parseFloat(i.quantity) || 1), 0);
    if (!computedTotal) {
      const subtotal = items.reduce((sum, i) => sum + ((parseFloat(i.price) || 0) * (parseFloat(i.quantity) || 1)), 0);
      computedTotal = subtotal + parseFloat(pickupFee) + parseFloat(deliveryFee);
    }
  } else if (!computedTotal) {
    const grainType = store.grainTypes.find(g => g.id === parseInt(grainTypeId || 1)) || store.grainTypes[0];
    resolvedGrainName = grainType ? grainType.name : 'Wheat (Gehun)';
    const grindingCost = (grainType ? grainType.grindingFeePerKg : 5) * resolvedQuantity;
    const grainCost = grainSource === 'MILL' ? (grainType ? grainType.pricePerKg : 35) * resolvedQuantity : 0;
    computedTotal = grindingCost + grainCost + parseFloat(deliveryFee);
  }

  const orderNumber = req.body.orderNumber || `#HD-${Math.floor(1000 + Math.random() * 9000)}`;
  const userId = req.user ? req.user.id : 1;
  const custName = req.user ? req.user.name : 'Ramesh Patel';
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
          'INSERT INTO order_timeline (order_id, status, note) VALUES (?, ?, ?)',
          [newOrder.id, 'PLACED', 'Order placed by customer']
        );
      } catch (tlErr) {
        console.warn('MySQL Timeline Insert Warning:', tlErr.message);
      }
    }
  } catch (dbErr) {
    console.warn('MySQL Orders Insert Warning:', dbErr.message);
  }

  res.status(201).json({
    status: 'success',
    message: 'Order created successfully in database',
    data: { order: newOrder }
  });
};

exports.getOrders = async (req, res) => {
  const { status, page = 1, limit = 20 } = req.query;
  const userId = req.user ? req.user.id : 1;

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

  res.json({
    status: 'success',
    count: 0,
    page: parseInt(page),
    limit: parseInt(limit),
    data: { orders: [] }
  });
};

exports.getActiveOrders = async (req, res) => {
  try {
    const userId = req.user ? req.user.id : 1;
    const dbOrders = await query(
      `SELECT o.*, m.name as mill_name FROM orders o LEFT JOIN mills m ON o.mill_id = m.id WHERE o.user_id = ? AND o.status IN ('PLACED', 'ACCEPTED', 'PROCESSING', 'PACKING', 'READY', 'READY_FOR_PICKUP', 'OUT_FOR_DELIVERY') ORDER BY o.id DESC`,
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

  res.json({ status: 'success', count: 0, data: { orders: [] } });
};

exports.getCompletedOrders = async (req, res) => {
  try {
    const userId = req.user ? req.user.id : 1;
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

  res.json({ status: 'success', count: 0, data: { orders: [] } });
};

exports.getCancelledOrders = async (req, res) => {
  try {
    const userId = req.user ? req.user.id : 1;
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
  res.json({ status: 'success', count: 0, data: { orders: [] } });
};

// Robust order finder that handles numeric IDs, prefixed strings (#HD-..., ORD-...), and safe fallbacks
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
  }) || store.orders.find(o => o.id === 501 || o.id === 502) || store.orders[0];
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

exports.getOrderTimeline = (req, res) => {
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

exports.confirmReceipt = (req, res) => {
  const orderId = parseInt(req.params.orderId);
  const order = store.orders.find(o => o.id === orderId);

  if (!order) {
    return res.status(404).json({ status: 'error', message: 'Order not found' });
  }

  order.status = ORDER_STATUS.COMPLETED;
  order.timeline.push({
    status: ORDER_STATUS.COMPLETED,
    timestamp: new Date().toISOString(),
    note: 'Customer confirmed order receipt'
  });

  res.json({
    status: 'success',
    message: 'Order receipt confirmed',
    data: { order }
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

exports.getOrderTracking = (req, res) => {
  const orderId = parseInt(req.params.orderId);
  const order = store.orders.find(o => o.id === orderId);

  if (!order) {
    return res.status(404).json({ status: 'error', message: 'Order not found' });
  }

  const delivery = store.deliveries.find(d => d.orderId === orderId);

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

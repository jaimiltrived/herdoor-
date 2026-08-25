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
    deliveryFee = 2.0
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

  const orderId = 500 + store.orders.length + 1;
  const orderNumber = req.body.orderNumber || `#HD-${Math.floor(1000 + Math.random() * 9000)}`;
  const userId = req.user ? req.user.id : 1;
  const custName = req.user ? req.user.name : 'Ramesh Patel';
  const custPhone = req.user ? req.user.phone : '+919876543210';

  const newOrder = {
    id: orderId,
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
    deliveryAddress: req.body.deliveryAddress || '456 Heritage Block, District 9, NY',
    pickupFee: parseFloat(pickupFee),
    deliveryFee: parseFloat(deliveryFee),
    paymentMethod,
    paymentStatus: 'PAID',
    status: ORDER_STATUS.PLACED,
    estimatedMinutes: 30,
    estimatedCompletionTime: 'Within 24 Hours',
    totalAmount: parseFloat(computedTotal),
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
        status, estimated_minutes, estimated_completion_time, total_amount
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
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
      newOrder.totalAmount || 0.0
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

  store.orders.unshift(newOrder);

  // Send notification to user
  store.notifications.push({
    id: store.notifications.length + 1,
    userId: newOrder.userId,
    title: 'Order Placed',
    message: `Your order #${newOrder.orderNumber} has been placed successfully.`,
    read: false,
    createdAt: new Date().toISOString()
  });

  res.status(201).json({
    status: 'success',
    message: 'Order created successfully',
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

    if (dbOrders && dbOrders.length > 0) {
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
        estimatedMinutes: row.estimated_minutes,
        estimatedCompletionTime: row.estimated_completion_time,
        totalAmount: parseFloat(row.total_amount),
        createdAt: row.created_at
      }));

      return res.json({
        status: 'success',
        count: mapped.length,
        data: { orders: mapped }
      });
    }
  } catch (err) {
    console.warn('MySQL getOrders fallback:', err.message);
  }

  let userOrders = store.orders.filter(o => o.userId === userId);
  if (status) {
    userOrders = userOrders.filter(o => o.status === status);
  }

  const p = parseInt(page);
  const l = parseInt(limit);
  const paginated = userOrders.slice((p - 1) * l, p * l);

  res.json({
    status: 'success',
    count: userOrders.length,
    page: p,
    limit: l,
    data: { orders: paginated }
  });
};

exports.getActiveOrders = (req, res) => {
  const activeStatuses = [
    ORDER_STATUS.PLACED,
    ORDER_STATUS.ACCEPTED,
    ORDER_STATUS.PROCESSING,
    ORDER_STATUS.PACKING,
    ORDER_STATUS.READY,
    ORDER_STATUS.READY_FOR_PICKUP,
    ORDER_STATUS.OUT_FOR_DELIVERY
  ];

  const activeOrders = store.orders.filter(o => o.userId === req.user.id && activeStatuses.includes(o.status));
  res.json({ status: 'success', count: activeOrders.length, data: { orders: activeOrders } });
};

exports.getCompletedOrders = (req, res) => {
  const completedStatuses = [ORDER_STATUS.DELIVERED, ORDER_STATUS.PICKED_UP, ORDER_STATUS.COMPLETED];
  const history = store.orders.filter(o => o.userId === req.user.id && completedStatuses.includes(o.status));
  res.json({ status: 'success', count: history.length, data: { orders: history } });
};

exports.getCancelledOrders = (req, res) => {
  const cancelled = store.orders.filter(o => o.userId === req.user.id && (o.status === ORDER_STATUS.CANCELLED || o.status === ORDER_STATUS.REJECTED));
  res.json({ status: 'success', count: cancelled.length, data: { orders: cancelled } });
};

exports.getOrderById = (req, res) => {
  const orderId = parseInt(req.params.orderId);
  const order = store.orders.find(o => o.id === orderId);

  if (!order) {
    return res.status(404).json({ status: 'error', message: 'Order not found' });
  }

  res.json({ status: 'success', data: { order } });
};

exports.getOrderStatus = (req, res) => {
  const orderId = parseInt(req.params.orderId);
  const order = store.orders.find(o => o.id === orderId);

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
  const orderId = parseInt(req.params.orderId);
  const order = store.orders.find(o => o.id === orderId);

  if (!order) {
    return res.status(404).json({ status: 'error', message: 'Order not found' });
  }

  res.json({
    status: 'success',
    data: {
      orderId: order.id,
      timeline: order.timeline
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

const store = require('../store/dataStore');
const { ORDER_STATUS, FULFILLMENT_TYPES } = require('../constants/enums');

exports.createOrder = (req, res) => {
  const {
    millId,
    grainSource,
    grainTypeId,
    quantityKg,
    serviceType = 'GRINDING',
    fulfillmentType = FULFILLMENT_TYPES.DELIVERY,
    addressId,
    paymentMethod = 'UPI'
  } = req.body;

  if (!millId || !grainTypeId || !quantityKg) {
    return res.status(400).json({
      status: 'error',
      message: 'millId, grainTypeId, and quantityKg are required'
    });
  }

  const mill = store.mills.find(m => m.id === parseInt(millId));
  if (!mill) {
    return res.status(404).json({ status: 'error', message: 'Mill not found' });
  }

  const grainType = store.grainTypes.find(g => g.id === parseInt(grainTypeId));
  if (!grainType) {
    return res.status(404).json({ status: 'error', message: 'Grain type not found' });
  }

  const grindingCost = grainType.grindingFeePerKg * quantityKg;
  const grainCost = grainSource === 'MILL' ? grainType.pricePerKg * quantityKg : 0;
  const deliveryCost = fulfillmentType === FULFILLMENT_TYPES.DELIVERY ? 30 : 0;
  const totalAmount = grindingCost + grainCost + deliveryCost;

  const orderId = 500 + store.orders.length + 1;
  const newOrder = {
    id: orderId,
    orderNumber: `ORD-2026-${1000 + store.orders.length + 1}`,
    userId: req.user.id,
    millId: parseInt(millId),
    grainSource: grainSource || 'CUSTOMER',
    grainTypeId: parseInt(grainTypeId),
    grainTypeName: grainType.name,
    quantityKg: parseFloat(quantityKg),
    serviceType,
    fulfillmentType,
    addressId: addressId ? parseInt(addressId) : null,
    paymentMethod,
    paymentStatus: 'PENDING',
    status: ORDER_STATUS.PLACED,
    estimatedMinutes: 30,
    estimatedCompletionTime: null,
    totalAmount,
    timeline: [
      {
        status: ORDER_STATUS.PLACED,
        timestamp: new Date().toISOString(),
        note: 'Order placed by customer'
      }
    ],
    createdAt: new Date().toISOString()
  };

  store.orders.push(newOrder);

  // Send notification to customer
  store.notifications.push({
    id: store.notifications.length + 1,
    userId: req.user.id,
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

exports.getOrders = (req, res) => {
  const { status, page = 1, limit = 20 } = req.query;
  let userOrders = store.orders.filter(o => o.userId === req.user.id);

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

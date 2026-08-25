const bcrypt = require('bcryptjs');
const store = require('../store/dataStore');
const { generateToken } = require('../utils/jwt');
const { ROLES, ORDER_STATUS, DELIVERY_STATUS } = require('../constants/enums');

/**
 * @desc Delivery Rider Login
 * @route POST /api/v1/delivery/auth/login or /api/v1/delivery/login
 */
exports.deliveryLogin = (req, res) => {
  const { phone, email, password } = req.body;
  const user = store.users.find(
    u => (u.phone === phone || u.email === email || (email && u.email.toLowerCase() === email.toLowerCase())) &&
         u.role === ROLES.DELIVERY
  );

  if (!user || !bcrypt.compareSync(password, user.password)) {
    return res.status(401).json({ status: 'error', message: 'Invalid delivery partner credentials' });
  }

  const token = generateToken({
    id: user.id,
    name: user.name,
    role: user.role
  });

  res.json({
    status: 'success',
    data: {
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        role: user.role,
        vehicleNumber: user.vehicleNumber,
        vehicleType: user.vehicleType,
        rating: user.rating || 4.8,
        isOnline: user.isOnline ?? true
      },
      token
    }
  });
};

/**
 * @desc Get Delivery Partner Profile
 * @route GET /api/v1/delivery/profile
 */
exports.getDeliveryProfile = (req, res) => {
  const user = store.users.find(u => u.id === req.user.id);
  if (!user) {
    return res.status(404).json({ status: 'error', message: 'Rider profile not found' });
  }

  res.json({
    status: 'success',
    data: {
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        role: user.role,
        vehicleNumber: user.vehicleNumber,
        vehicleType: user.vehicleType,
        rating: user.rating || 4.8,
        totalTrips: user.totalTrips || 0,
        isOnline: user.isOnline ?? true
      }
    }
  });
};

/**
 * @desc Toggle Online / Offline Status
 * @route PUT /api/v1/delivery/status
 */
exports.updateOnlineStatus = (req, res) => {
  const user = store.users.find(u => u.id === req.user.id);
  if (!user) {
    return res.status(404).json({ status: 'error', message: 'Rider not found' });
  }

  const { isOnline } = req.body;
  if (isOnline !== undefined) {
    user.isOnline = !!isOnline;
  }

  res.json({
    status: 'success',
    message: `Rider is now ${user.isOnline ? 'ONLINE' : 'OFFLINE'}`,
    data: { isOnline: user.isOnline }
  });
};

/**
 * @desc Get Available Trips Queue (Orders ready for driver pickup)
 * @route GET /api/v1/delivery/available-trips
 */
exports.getAvailableTrips = (req, res) => {
  // Find orders that are ready for delivery and not yet assigned to an active delivery trip
  const assignedOrderIds = store.deliveries
    .filter(d => [DELIVERY_STATUS.ASSIGNED, DELIVERY_STATUS.PICKED_UP_FROM_MILL, DELIVERY_STATUS.OUT_FOR_DELIVERY].includes(d.status))
    .map(d => d.orderId);

  const availableOrders = store.orders.filter(o =>
    o.fulfillmentType === 'DELIVERY' &&
    [ORDER_STATUS.ACCEPTED, ORDER_STATUS.PROCESSING, ORDER_STATUS.PACKING, ORDER_STATUS.READY].includes(o.status) &&
    !assignedOrderIds.includes(o.id)
  ).map(o => {
    const mill = store.mills.find(m => m.id === o.millId);
    const addr = store.addresses.find(a => a.id === o.addressId);
    return {
      orderId: o.id,
      orderNumber: o.orderNumber,
      customerName: o.customerName,
      customerPhone: o.customerPhone,
      millName: mill ? mill.name : 'Flour Mill',
      millAddress: mill ? mill.address : 'Market Yard',
      deliveryAddress: addr ? `${addr.addressLine1}, ${addr.addressLine2}, ${addr.city}` : 'Ahmedabad',
      quantityKg: o.quantityKg,
      grainTypeName: o.grainTypeName,
      estimatedDeliveryFee: 40.0,
      distanceKm: 2.8,
      status: o.status
    };
  });

  res.json({
    status: 'success',
    count: availableOrders.length,
    data: { trips: availableOrders }
  });
};

/**
 * @desc Get All Deliveries / Trips
 * @route GET /api/v1/delivery/orders
 */
exports.getDeliveryOrders = (req, res) => {
  res.json({ status: 'success', count: store.deliveries.length, data: { deliveries: store.deliveries } });
};

/**
 * @desc Get Assigned Trips for Logged-In Rider
 * @route GET /api/v1/delivery/assigned
 */
exports.getAssignedOrders = (req, res) => {
  const assigned = store.deliveries.filter(
    d => d.deliveryPersonId === req.user.id &&
         [DELIVERY_STATUS.ASSIGNED, DELIVERY_STATUS.PICKED_UP_FROM_MILL, DELIVERY_STATUS.OUT_FOR_DELIVERY].includes(d.status)
  );
  res.json({ status: 'success', count: assigned.length, data: { deliveries: assigned } });
};

/**
 * @desc Get Completed Delivery Trips for Rider
 * @route GET /api/v1/delivery/completed
 */
exports.getCompletedTrips = (req, res) => {
  const completed = store.deliveries.filter(
    d => d.deliveryPersonId === req.user.id && d.status === DELIVERY_STATUS.DELIVERED
  );
  res.json({ status: 'success', count: completed.length, data: { deliveries: completed } });
};

/**
 * @desc Get Delivery Order Details by Order ID
 * @route GET /api/v1/delivery/orders/:orderId
 */
exports.getDeliveryOrderById = (req, res) => {
  const orderId = parseInt(req.params.orderId);
  const delivery = store.deliveries.find(d => d.orderId === orderId);
  const order = store.orders.find(o => o.id === orderId);

  if (!delivery && !order) {
    return res.status(404).json({ status: 'error', message: 'Delivery record not found' });
  }

  res.json({ status: 'success', data: { delivery, order } });
};

/**
 * @desc Accept Delivery Task
 * @route POST /api/v1/delivery/orders/:orderId/accept
 */
exports.acceptDelivery = (req, res) => {
  const orderId = parseInt(req.params.orderId);
  const order = store.orders.find(o => o.id === orderId);

  if (!order) {
    return res.status(404).json({ status: 'error', message: 'Order not found' });
  }

  const mill = store.mills.find(m => m.id === order.millId);
  const addr = store.addresses.find(a => a.id === order.addressId);

  let delivery = store.deliveries.find(d => d.orderId === orderId);

  if (!delivery) {
    delivery = {
      id: 800 + store.deliveries.length + 1,
      orderId,
      deliveryPersonId: req.user.id,
      deliveryPersonName: req.user.name || 'Vikram Delivery Agent',
      deliveryPersonPhone: req.user.phone || '+919876543212',
      status: DELIVERY_STATUS.ASSIGNED,
      pickupAddress: mill ? `${mill.name}, ${mill.address}` : 'Flour Mill',
      deliveryAddress: addr ? `${addr.addressLine1}, ${addr.addressLine2}, ${addr.city}` : 'Customer Address',
      currentLatitude: 23.0225,
      currentLongitude: 72.5714,
      pickupPin: order.pickupPin || '4821',
      deliveryOtp: order.deliveryOtp || '7391',
      deliveryFee: 40.0,
      estimatedMinutes: 20,
      updatedAt: new Date().toISOString()
    };
    store.deliveries.push(delivery);
  } else {
    delivery.deliveryPersonId = req.user.id;
    delivery.deliveryPersonName = req.user.name;
    delivery.status = DELIVERY_STATUS.ASSIGNED;
    delivery.updatedAt = new Date().toISOString();
  }

  res.json({ status: 'success', message: 'Delivery task accepted', data: { delivery } });
};

/**
 * @desc Confirm Pickup at Mill (with optional PIN validation)
 * @route POST /api/v1/delivery/orders/:orderId/pickup
 */
exports.markPickedUp = (req, res) => {
  const orderId = parseInt(req.params.orderId);
  const { pin } = req.body;
  const delivery = store.deliveries.find(d => d.orderId === orderId);
  const order = store.orders.find(o => o.id === orderId);

  if (!order) {
    return res.status(404).json({ status: 'error', message: 'Order not found' });
  }

  // Validate PIN if provided
  if (pin && order.pickupPin && pin !== order.pickupPin) {
    return res.status(400).json({ status: 'error', message: 'Invalid mill handover PIN' });
  }

  if (delivery) {
    delivery.status = DELIVERY_STATUS.PICKED_UP_FROM_MILL;
    delivery.updatedAt = new Date().toISOString();
  }

  order.status = ORDER_STATUS.OUT_FOR_DELIVERY;
  order.timeline.push({
    status: ORDER_STATUS.OUT_FOR_DELIVERY,
    timestamp: new Date().toISOString(),
    note: 'Picked up from mill by delivery partner'
  });

  res.json({ status: 'success', message: 'Order picked up from mill', data: { delivery, order } });
};

/**
 * @desc Mark Out for Delivery
 * @route POST /api/v1/delivery/orders/:orderId/out-for-delivery
 */
exports.markOutForDelivery = (req, res) => {
  const orderId = parseInt(req.params.orderId);
  const delivery = store.deliveries.find(d => d.orderId === orderId);
  const order = store.orders.find(o => o.id === orderId);

  if (delivery) {
    delivery.status = DELIVERY_STATUS.OUT_FOR_DELIVERY;
    delivery.updatedAt = new Date().toISOString();
  }

  if (order) {
    order.status = ORDER_STATUS.OUT_FOR_DELIVERY;
  }

  res.json({ status: 'success', message: 'Order marked out for delivery', data: { delivery } });
};

/**
 * @desc Update Live Rider Location
 * @route POST /api/v1/delivery/orders/:orderId/location or /api/v1/delivery/location
 */
exports.updateLocation = (req, res) => {
  const orderId = req.params.orderId ? parseInt(req.params.orderId) : null;
  const { latitude, longitude } = req.body;

  if (latitude === undefined || longitude === undefined) {
    return res.status(400).json({ status: 'error', message: 'latitude and longitude are required' });
  }

  if (orderId) {
    const delivery = store.deliveries.find(d => d.orderId === orderId);
    if (delivery) {
      delivery.currentLatitude = parseFloat(latitude);
      delivery.currentLongitude = parseFloat(longitude);
      delivery.updatedAt = new Date().toISOString();
    }
  }

  res.json({
    status: 'success',
    message: 'Location updated',
    data: { latitude: parseFloat(latitude), longitude: parseFloat(longitude) }
  });
};

/**
 * @desc Confirm Delivery to Customer (with optional OTP validation)
 * @route POST /api/v1/delivery/orders/:orderId/deliver
 */
exports.markDelivered = (req, res) => {
  const orderId = parseInt(req.params.orderId);
  const { otp } = req.body;
  const delivery = store.deliveries.find(d => d.orderId === orderId);
  const order = store.orders.find(o => o.id === orderId);

  if (!order) {
    return res.status(404).json({ status: 'error', message: 'Order not found' });
  }

  // Validate OTP if provided
  if (otp && order.deliveryOtp && otp !== order.deliveryOtp) {
    return res.status(400).json({ status: 'error', message: 'Invalid customer delivery OTP' });
  }

  if (delivery) {
    delivery.status = DELIVERY_STATUS.DELIVERED;
    delivery.updatedAt = new Date().toISOString();
  }

  order.status = ORDER_STATUS.DELIVERED;
  order.paymentStatus = 'PAID';
  order.timeline.push({
    status: ORDER_STATUS.DELIVERED,
    timestamp: new Date().toISOString(),
    note: 'Delivered to customer successfully'
  });

  // Increment rider trips
  const rider = store.users.find(u => u.id === req.user.id);
  if (rider) {
    rider.totalTrips = (rider.totalTrips || 0) + 1;
  }

  res.json({ status: 'success', message: 'Order delivered successfully', data: { delivery, order } });
};

/**
 * @desc Get Live Tracking for Delivery ID
 * @route GET /api/v1/delivery/tracking/:deliveryId
 */
exports.getDeliveryTracking = (req, res) => {
  const deliveryId = parseInt(req.params.deliveryId);
  const delivery = store.deliveries.find(d => d.id === deliveryId);

  if (!delivery) {
    return res.status(404).json({ status: 'error', message: 'Delivery record not found' });
  }

  res.json({ status: 'success', data: { delivery } });
};

/**
 * @desc Update Delivery Status Manually
 * @route PUT /api/v1/delivery/:deliveryId/status
 */
exports.updateDeliveryStatus = (req, res) => {
  const deliveryId = parseInt(req.params.deliveryId);
  const { status } = req.body;
  const delivery = store.deliveries.find(d => d.id === deliveryId);

  if (!delivery) {
    return res.status(404).json({ status: 'error', message: 'Delivery record not found' });
  }

  delivery.status = status;
  delivery.updatedAt = new Date().toISOString();

  res.json({ status: 'success', message: 'Delivery status updated', data: { delivery } });
};

/**
 * @desc Get Delivery Partner Earnings
 * @route GET /api/v1/delivery/earnings
 */
exports.getEarnings = (req, res) => {
  const completedDeliveries = store.deliveries.filter(
    d => d.deliveryPersonId === req.user.id && d.status === DELIVERY_STATUS.DELIVERED
  );

  const totalEarnings = completedDeliveries.reduce((sum, d) => sum + (d.deliveryFee || 40.0), 0);
  const tips = 25.0;

  res.json({
    status: 'success',
    data: {
      totalTrips: completedDeliveries.length,
      tripEarnings: parseFloat(totalEarnings.toFixed(2)),
      tips,
      totalPayout: parseFloat((totalEarnings + tips).toFixed(2)),
      todayTrips: completedDeliveries.length,
      todayEarnings: parseFloat(totalEarnings.toFixed(2))
    }
  });
};

const store = require('../store/dataStore');
const { ROLES, ORDER_STATUS, DELIVERY_STATUS } = require('../constants/enums');

/**
 * @desc Get Admin Platform Dashboard Metrics
 * @route GET /api/v1/admin/dashboard
 */
exports.getDashboardMetrics = (req, res) => {
  const totalOrders = store.orders.length;
  const totalRevenue = store.orders
    .filter(o => o.paymentStatus === 'PAID')
    .reduce((sum, o) => sum + o.totalAmount, 0);

  const activeMills = store.mills.filter(m => m.isOpen).length;
  const activeFleet = store.users.filter(u => u.role === ROLES.DELIVERY && u.isOnline).length;
  const completedToday = store.orders.filter(o => o.status === ORDER_STATUS.DELIVERED || o.status === ORDER_STATUS.COMPLETED).length;

  res.json({
    status: 'success',
    data: {
      totalOrders,
      totalRevenue: parseFloat(totalRevenue.toFixed(2)),
      activeMills,
      totalMills: store.mills.length,
      activeFleet,
      totalRiders: store.users.filter(u => u.role === ROLES.DELIVERY).length,
      completedToday,
      activeOrders: store.orders.filter(o => [ORDER_STATUS.PLACED, ORDER_STATUS.ACCEPTED, ORDER_STATUS.PROCESSING, ORDER_STATUS.PACKING, ORDER_STATUS.READY, ORDER_STATUS.OUT_FOR_DELIVERY].includes(o.status)).length
    }
  });
};

/**
 * @desc Flour Mills Master List
 * @route GET /api/v1/admin/mills
 */
exports.getMills = (req, res) => {
  res.json({
    status: 'success',
    count: store.mills.length,
    data: { mills: store.mills }
  });
};

/**
 * @desc Create / Register Flour Mill
 * @route POST /api/v1/admin/mills
 */
exports.createMill = (req, res) => {
  const { name, address, phone, capacityKgPerDay = 500, specialty, services = ['Flour Grinding', 'Home Delivery'] } = req.body;

  if (!name || !address) {
    return res.status(400).json({ status: 'error', message: 'Mill name and address are required' });
  }

  const newMill = {
    id: 100 + store.mills.length + 1,
    name,
    address,
    phone: phone || '+919876543299',
    latitude: 23.0250,
    longitude: 72.5700,
    rating: 5.0,
    totalRatings: 1,
    isOpen: true,
    estimatedTime: '30 min',
    capacityKgPerDay: parseFloat(capacityKgPerDay),
    currentLoadKg: 0,
    services,
    workingHours: '08:00 AM - 08:00 PM',
    specialty: specialty || 'Fresh Stone Ground Flour'
  };

  store.mills.push(newMill);
  res.status(201).json({ status: 'success', message: 'Mill registered successfully', data: { mill: newMill } });
};

/**
 * @desc Update Mill Details
 * @route PUT /api/v1/admin/mills/:id
 */
exports.updateMill = (req, res) => {
  const id = parseInt(req.params.id);
  const mill = store.mills.find(m => m.id === id);

  if (!mill) {
    return res.status(404).json({ status: 'error', message: 'Mill not found' });
  }

  Object.assign(mill, req.body);
  res.json({ status: 'success', message: 'Mill updated successfully', data: { mill } });
};

/**
 * @desc Delete / Deactivate Mill
 * @route DELETE /api/v1/admin/mills/:id
 */
exports.deleteMill = (req, res) => {
  const id = parseInt(req.params.id);
  const index = store.mills.findIndex(m => m.id === id);

  if (index === -1) {
    return res.status(404).json({ status: 'error', message: 'Mill not found' });
  }

  store.mills.splice(index, 1);
  res.json({ status: 'success', message: 'Mill deleted successfully' });
};

/**
 * @desc Delivery Fleet / Riders List
 * @route GET /api/v1/admin/riders
 */
exports.getRiders = (req, res) => {
  const riders = store.users.filter(u => u.role === ROLES.DELIVERY).map(r => ({
    id: r.id,
    name: r.name,
    email: r.email,
    phone: r.phone,
    vehicleNumber: r.vehicleNumber,
    vehicleType: r.vehicleType || 'Electric Bike',
    isOnline: r.isOnline ?? true,
    rating: r.rating || 4.8,
    totalTrips: r.totalTrips || 0,
    status: r.isOnline ? 'ACTIVE' : 'OFFLINE'
  }));

  res.json({ status: 'success', count: riders.length, data: { riders } });
};

/**
 * @desc Update Rider Status
 * @route PUT /api/v1/admin/riders/:id/status
 */
exports.updateRiderStatus = (req, res) => {
  const id = parseInt(req.params.id);
  const rider = store.users.find(u => u.id === id && u.role === ROLES.DELIVERY);

  if (!rider) {
    return res.status(404).json({ status: 'error', message: 'Rider not found' });
  }

  const { isOnline, status } = req.body;
  if (isOnline !== undefined) rider.isOnline = !!isOnline;
  if (status === 'INACTIVE') rider.isOnline = false;

  res.json({ status: 'success', message: 'Rider status updated', data: { rider } });
};

/**
 * @desc Wholesalers Master List
 * @route GET /api/v1/admin/wholesalers
 */
exports.getWholesalers = (req, res) => {
  res.json({
    status: 'success',
    count: store.wholesalers.length,
    data: { wholesalers: store.wholesalers }
  });
};

/**
 * @desc Register Wholesaler
 * @route POST /api/v1/admin/wholesalers
 */
exports.createWholesaler = (req, res) => {
  const { name, contactPerson, phone, city = 'Ahmedabad', grainsSupplied = ['Wheat'], stockAvailableTons = 50.0 } = req.body;

  if (!name || !phone) {
    return res.status(400).json({ status: 'error', message: 'Wholesaler name and phone are required' });
  }

  const newWholesaler = {
    id: store.wholesalers.length + 1,
    name,
    contactPerson: contactPerson || 'Authorized Dealer',
    phone,
    city,
    grainsSupplied,
    rating: 4.8,
    stockAvailableTons: parseFloat(stockAvailableTons),
    status: 'ACTIVE'
  };

  store.wholesalers.push(newWholesaler);
  res.status(201).json({ status: 'success', message: 'Wholesaler registered', data: { wholesaler: newWholesaler } });
};

/**
 * @desc Master Orders Ledger
 * @route GET /api/v1/admin/orders
 */
exports.getOrders = (req, res) => {
  const { status, millId } = req.query;
  let list = [...store.orders];

  if (status) {
    list = list.filter(o => o.status === status);
  }
  if (millId) {
    list = list.filter(o => o.millId === parseInt(millId));
  }

  res.json({
    status: 'success',
    count: list.length,
    data: { orders: list }
  });
};

/**
 * @desc Superadmin Override Order Status
 * @route PUT /api/v1/admin/orders/:id/status
 */
exports.updateOrderStatus = (req, res) => {
  const id = parseInt(req.params.id);
  const { status, note = 'Admin manual status override' } = req.body;
  const order = store.orders.find(o => o.id === id);

  if (!order) {
    return res.status(404).json({ status: 'error', message: 'Order not found' });
  }

  order.status = status;
  order.timeline.push({
    status,
    timestamp: new Date().toISOString(),
    note
  });

  res.json({ status: 'success', message: `Order status updated to ${status}`, data: { order } });
};

/**
 * @desc Security Audits & Activity Logs
 * @route GET /api/v1/admin/security
 */
exports.getSecurityAudits = (req, res) => {
  res.json({
    status: 'success',
    data: {
      logs: [
        { id: 1, event: 'ADMIN_LOGIN', user: 'admin@herdoor.com', ip: '127.0.0.1', status: 'SUCCESS', timestamp: new Date().toISOString() },
        { id: 2, event: 'PAYOUT_REQUEST', user: 'shop@shreeganesh.com', amount: '₹12,450', status: 'VERIFIED', timestamp: new Date().toISOString() },
        { id: 3, event: 'SECURITY_AUDIT', system: 'SSL/TLS & API Gateway', score: '99.9%', status: 'HEALTHY', timestamp: new Date().toISOString() }
      ]
    }
  });
};

/**
 * @desc Fraud Detection Alerts
 * @route GET /api/v1/admin/fraud
 */
exports.getFraudAlerts = (req, res) => {
  res.json({
    status: 'success',
    data: {
      alerts: [
        { id: 1, type: 'VELOCITY_CHECK', desc: 'High frequency order placement detected from single IP', severity: 'LOW', resolved: true },
        { id: 2, type: 'REFUND_THRESHOLD', desc: 'No abnormal refund threshold spikes detected', severity: 'NORMAL', resolved: true }
      ]
    }
  });
};

/**
 * @desc Merchant & Rider Withdrawals
 * @route GET /api/v1/admin/withdrawals
 */
exports.getWithdrawals = (req, res) => {
  res.json({
    status: 'success',
    data: {
      withdrawals: [
        { id: 'WTH-901', recipient: 'Shree Ganesh Flour Mill', amount: 12450.0, method: 'Bank Transfer (NEFT)', status: 'SETTLED', date: '2026-08-24' },
        { id: 'WTH-902', recipient: 'Vikram Delivery Agent', amount: 3200.0, method: 'UPI Direct', status: 'SETTLED', date: '2026-08-24' }
      ]
    }
  });
};

/**
 * @desc Customer Refunds
 * @route GET /api/v1/admin/refunds
 */
exports.getRefunds = (req, res) => {
  res.json({
    status: 'success',
    data: {
      refunds: [
        { id: 'REF-401', orderId: '#ORD-2026-0988', customerName: 'Neha Verma', amount: 95.0, reason: 'Machine breakdown cancellation', status: 'PROCESSED' }
      ]
    }
  });
};

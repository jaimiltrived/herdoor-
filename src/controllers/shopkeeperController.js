const store = require('../store/dataStore');
const { ORDER_STATUS, FULFILLMENT_TYPES, DELIVERY_STATUS } = require('../constants/enums');

// Helper to get Mill ID associated with logged-in Shopkeeper
function getShopkeeperMillId(user) {
  if (user && user.millId) return user.millId;
  return 101; // Default to mill 101
}

function enrichOrder(o) {
  const u = store.users.find(usr => usr.id === o.userId);
  const addr = store.addresses.find(a => a.id === o.addressId);
  const delivery = store.deliveries.find(d => d.orderId === o.id);

  return {
    ...o,
    numericId: o.id,
    orderId: `#HD-${o.id}`,
    customerName: o.customerName || (u ? u.name : 'Ramesh Patel'),
    customerPhone: o.customerPhone || (u ? u.phone : '+919876543210'),
    itemsSummary: `${o.quantityKg}kg ${o.grainTypeName}`,
    grainType: o.grainTypeName,
    quantityText: `${o.quantityKg} kg`,
    timeAgo: 'Just now',
    statusTag: o.status,
    deliveryAddress: addr ? `${addr.addressLine1}, ${addr.city}` : 'Store Pickup',
    driverAssigned: delivery ? {
      name: delivery.deliveryPersonName,
      phone: delivery.deliveryPersonPhone,
      status: delivery.status,
      pin: delivery.pickupPin
    } : null
  };
}

/**
 * @desc Get Shopkeeper Dashboard KPIs
 * @route GET /api/v1/shopkeeper/dashboard
 */
exports.getDashboard = (req, res) => {
  const millId = getShopkeeperMillId(req.user);
  const millOrders = store.orders.filter(o => o.millId === millId);

  const pendingCount = millOrders.filter(o => o.status === ORDER_STATUS.PLACED).length;
  const activeCount = millOrders.filter(o => [ORDER_STATUS.ACCEPTED, ORDER_STATUS.PROCESSING, ORDER_STATUS.PACKING, ORDER_STATUS.READY, ORDER_STATUS.READY_FOR_PICKUP].includes(o.status)).length;
  const completedCount = millOrders.filter(o => [ORDER_STATUS.DELIVERED, ORDER_STATUS.PICKED_UP, ORDER_STATUS.COMPLETED].includes(o.status)).length;
  const totalRevenue = millOrders
    .filter(o => o.paymentStatus === 'PAID')
    .reduce((sum, o) => sum + o.totalAmount, 0);

  const activeOrders = millOrders
    .filter(o => [ORDER_STATUS.PLACED, ORDER_STATUS.ACCEPTED, ORDER_STATUS.PROCESSING, ORDER_STATUS.PACKING, ORDER_STATUS.READY].includes(o.status))
    .map(enrichOrder);

  res.json({
    status: 'success',
    data: {
      millId,
      metrics: {
        pendingOrders: pendingCount,
        activeOrders: activeCount,
        completedOrders: completedCount,
        totalRevenue: parseFloat(totalRevenue.toFixed(2))
      },
      revenueToday: parseFloat(totalRevenue.toFixed(2)),
      totalOrders: millOrders.length,
      pendingOrdersCount: pendingCount,
      newOrdersCount: pendingCount,
      activeOrders
    }
  });
};

/**
 * @desc Get Mill / Shop Profile
 * @route GET /api/v1/shopkeeper/profile
 */
exports.getProfile = (req, res) => {
  const millId = getShopkeeperMillId(req.user);
  const mill = store.mills.find(m => m.id === millId);
  const user = store.users.find(u => u.id === req.user.id);

  res.json({
    status: 'success',
    data: {
      user: {
        id: user ? user.id : 2,
        name: user ? user.name : 'Suresh Mill Owner',
        email: user ? user.email : 'shop@shreeganesh.com',
        phone: user ? user.phone : '+919876543211'
      },
      mill: mill || {
        id: 101,
        name: 'Shree Ganesh Flour Mill',
        address: '12 Market Yard, Ellisbridge, Ahmedabad',
        phone: '+919876543211',
        isOpen: true,
        services: ['Flour Grinding', 'Packing', 'Home Delivery', 'Cleaning'],
        workingHours: '08:00 AM - 08:00 PM'
      }
    }
  });
};

/**
 * @desc Update Mill / Shop Profile
 * @route PUT /api/v1/shopkeeper/profile
 */
exports.updateProfile = (req, res) => {
  const millId = getShopkeeperMillId(req.user);
  const mill = store.mills.find(m => m.id === millId);
  const user = store.users.find(u => u.id === req.user.id);

  const { name, phone, address, workingHours, services, specialty } = req.body;

  if (user && name) user.name = name;
  if (user && phone) user.phone = phone;

  if (mill) {
    if (name) mill.name = name;
    if (phone) mill.phone = phone;
    if (address) mill.address = address;
    if (workingHours) mill.workingHours = workingHours;
    if (Array.isArray(services)) mill.services = services;
    if (specialty) mill.specialty = specialty;
  }

  res.json({
    status: 'success',
    message: 'Profile updated successfully',
    data: { user, mill }
  });
};

/**
 * @desc Get Orders Queues
 */
exports.getTodayOrders = (req, res) => {
  const millId = getShopkeeperMillId(req.user);
  const millOrders = store.orders.filter(o => o.millId === millId).map(enrichOrder);
  res.json({ status: 'success', count: millOrders.length, data: { orders: millOrders } });
};

exports.getPendingOrders = (req, res) => {
  const millId = getShopkeeperMillId(req.user);
  const pending = store.orders.filter(o => o.millId === millId && o.status === ORDER_STATUS.PLACED).map(enrichOrder);
  res.json({ status: 'success', count: pending.length, data: { orders: pending } });
};

exports.getNewOrders = (req, res) => {
  return exports.getPendingOrders(req, res);
};

exports.getActiveOrders = (req, res) => {
  const millId = getShopkeeperMillId(req.user);
  const activeStatuses = [ORDER_STATUS.ACCEPTED, ORDER_STATUS.PROCESSING, ORDER_STATUS.PACKING, ORDER_STATUS.READY, ORDER_STATUS.READY_FOR_PICKUP, ORDER_STATUS.OUT_FOR_DELIVERY];
  const active = store.orders.filter(o => o.millId === millId && activeStatuses.includes(o.status)).map(enrichOrder);
  res.json({ status: 'success', count: active.length, data: { orders: active } });
};

exports.getCompletedOrders = (req, res) => {
  const millId = getShopkeeperMillId(req.user);
  const completedStatuses = [ORDER_STATUS.DELIVERED, ORDER_STATUS.PICKED_UP, ORDER_STATUS.COMPLETED];
  const completed = store.orders.filter(o => o.millId === millId && completedStatuses.includes(o.status)).map(enrichOrder);
  res.json({ status: 'success', count: completed.length, data: { orders: completed } });
};

exports.getRevenue = (req, res) => {
  const millId = getShopkeeperMillId(req.user);
  const millOrders = store.orders.filter(o => o.millId === millId && o.paymentStatus === 'PAID');
  const revenue = millOrders.reduce((sum, o) => sum + o.totalAmount, 0);

  res.json({
    status: 'success',
    data: {
      millId,
      totalRevenue: parseFloat(revenue.toFixed(2)),
      paidOrdersCount: millOrders.length
    }
  });
};

/**
 * @desc Accept Order & Set ETA
 * @route POST /api/v1/shopkeeper/orders/:orderId/accept
 */
exports.acceptOrder = (req, res) => {
  const orderId = parseInt(req.params.orderId);
  const { estimatedCompletionMinutes = 30, estimatedCompletionTime } = req.body;
  const order = store.orders.find(o => o.id === orderId);

  if (!order) {
    return res.status(404).json({ status: 'error', message: 'Order not found' });
  }

  order.status = ORDER_STATUS.ACCEPTED;
  order.estimatedMinutes = estimatedCompletionMinutes;
  order.estimatedCompletionTime = estimatedCompletionTime || new Date(Date.now() + estimatedCompletionMinutes * 60000).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
  order.timeline.push({
    status: ORDER_STATUS.ACCEPTED,
    timestamp: new Date().toISOString(),
    note: `Accepted by mill owner (ETA: ${order.estimatedCompletionTime})`
  });

  res.json({ status: 'success', message: 'Order accepted', data: { order: enrichOrder(order) } });
};

/**
 * @desc Reject Order
 * @route POST /api/v1/shopkeeper/orders/:orderId/reject
 */
exports.rejectOrder = (req, res) => {
  const orderId = parseInt(req.params.orderId);
  const { reason = 'Capacity exceeded' } = req.body;
  const order = store.orders.find(o => o.id === orderId);

  if (!order) {
    return res.status(404).json({ status: 'error', message: 'Order not found' });
  }

  order.status = ORDER_STATUS.REJECTED;
  order.timeline.push({
    status: ORDER_STATUS.REJECTED,
    timestamp: new Date().toISOString(),
    note: `Rejected by mill owner: ${reason}`
  });

  res.json({ status: 'success', message: 'Order rejected', data: { order: enrichOrder(order) } });
};

/**
 * @desc Set / Update Completion Time
 * @route PUT /api/v1/shopkeeper/orders/:orderId/completion-time
 */
exports.setCompletionTime = (req, res) => {
  const orderId = parseInt(req.params.orderId);
  const { estimatedCompletionMinutes, estimatedCompletionTime } = req.body;
  const order = store.orders.find(o => o.id === orderId);

  if (!order) {
    return res.status(404).json({ status: 'error', message: 'Order not found' });
  }

  if (estimatedCompletionMinutes) order.estimatedMinutes = estimatedCompletionMinutes;
  if (estimatedCompletionTime) order.estimatedCompletionTime = estimatedCompletionTime;

  res.json({ status: 'success', message: 'Completion time updated', data: { order: enrichOrder(order) } });
};

/**
 * @desc Start Milling / Grinding Process
 * @route POST /api/v1/shopkeeper/orders/:orderId/start or /processing
 */
exports.startProcessing = (req, res) => {
  const orderId = parseInt(req.params.orderId);
  const order = store.orders.find(o => o.id === orderId);

  if (!order) {
    return res.status(404).json({ status: 'error', message: 'Order not found' });
  }

  order.status = ORDER_STATUS.PROCESSING;
  order.timeline.push({
    status: ORDER_STATUS.PROCESSING,
    timestamp: new Date().toISOString(),
    note: 'Chakki grinding started'
  });

  res.json({ status: 'success', message: 'Milling process started', data: { order: enrichOrder(order) } });
};

/**
 * @desc Start Packing
 * @route POST /api/v1/shopkeeper/orders/:orderId/packing
 */
exports.startPacking = (req, res) => {
  const orderId = parseInt(req.params.orderId);
  const order = store.orders.find(o => o.id === orderId);

  if (!order) {
    return res.status(404).json({ status: 'error', message: 'Order not found' });
  }

  order.status = ORDER_STATUS.PACKING;
  order.timeline.push({
    status: ORDER_STATUS.PACKING,
    timestamp: new Date().toISOString(),
    note: 'Flour packing & bagging started'
  });

  res.json({ status: 'success', message: 'Packing started', data: { order: enrichOrder(order) } });
};

/**
 * @desc Mark Order Ready (Ready for Pickup / Driver Dispatch)
 * @route POST /api/v1/shopkeeper/orders/:orderId/ready
 */
exports.markReady = (req, res) => {
  const orderId = parseInt(req.params.orderId);
  const order = store.orders.find(o => o.id === orderId);

  if (!order) {
    return res.status(404).json({ status: 'error', message: 'Order not found' });
  }

  const nextStatus = order.fulfillmentType === FULFILLMENT_TYPES.PICKUP
    ? ORDER_STATUS.READY_FOR_PICKUP
    : ORDER_STATUS.READY;

  order.status = nextStatus;
  order.timeline.push({
    status: nextStatus,
    timestamp: new Date().toISOString(),
    note: `Order packed and ready for ${order.fulfillmentType.toLowerCase()}`
  });

  res.json({ status: 'success', message: `Order marked ${nextStatus}`, data: { order: enrichOrder(order) } });
};

/**
 * @desc Handover Order to Delivery Rider with Verification PIN / QR
 * @route POST /api/v1/shopkeeper/orders/:orderId/handover
 */
exports.handoverDelivery = (req, res) => {
  const orderId = parseInt(req.params.orderId);
  const { pin } = req.body;
  const order = store.orders.find(o => o.id === orderId);

  if (!order) {
    return res.status(404).json({ status: 'error', message: 'Order not found' });
  }

  // Check PIN if provided
  if (pin && order.pickupPin && pin !== order.pickupPin) {
    return res.status(400).json({ status: 'error', message: 'Invalid driver handover verification PIN' });
  }

  order.status = ORDER_STATUS.OUT_FOR_DELIVERY;
  order.timeline.push({
    status: ORDER_STATUS.OUT_FOR_DELIVERY,
    timestamp: new Date().toISOString(),
    note: 'Handed over to delivery partner for doorstep delivery'
  });

  // Update associated delivery record if exists
  const delivery = store.deliveries.find(d => d.orderId === orderId);
  if (delivery) {
    delivery.status = DELIVERY_STATUS.OUT_FOR_DELIVERY;
    delivery.updatedAt = new Date().toISOString();
  }

  res.json({ status: 'success', message: 'Order handed over to delivery rider', data: { order: enrichOrder(order) } });
};

/**
 * @desc Complete Order
 * @route POST /api/v1/shopkeeper/orders/:orderId/complete
 */
exports.completeOrder = (req, res) => {
  const orderId = parseInt(req.params.orderId);
  const order = store.orders.find(o => o.id === orderId);

  if (!order) {
    return res.status(404).json({ status: 'error', message: 'Order not found' });
  }

  const statusVal = order.fulfillmentType === FULFILLMENT_TYPES.PICKUP ? ORDER_STATUS.PICKED_UP : ORDER_STATUS.COMPLETED;
  order.status = statusVal;
  order.paymentStatus = 'PAID';
  order.timeline.push({
    status: statusVal,
    timestamp: new Date().toISOString(),
    note: 'Order successfully completed'
  });

  res.json({ status: 'success', message: 'Order completed', data: { order: enrichOrder(order) } });
};

/**
 * @desc Flour & Grain Inventory Management
 */
exports.getInventory = (req, res) => {
  const millId = getShopkeeperMillId(req.user);
  const items = store.inventory.filter(i => i.millId === millId);
  res.json({ status: 'success', count: items.length, data: { inventory: items } });
};

exports.getLowStock = (req, res) => {
  const millId = getShopkeeperMillId(req.user);
  const lowStock = store.inventory.filter(i => i.millId === millId && i.stockKg <= i.minimumStockKg);
  res.json({ status: 'success', count: lowStock.length, data: { inventory: lowStock } });
};

exports.getInventoryById = (req, res) => {
  const id = parseInt(req.params.id);
  const item = store.inventory.find(i => i.id === id);

  if (!item) {
    return res.status(404).json({ status: 'error', message: 'Inventory item not found' });
  }

  res.json({ status: 'success', data: { item } });
};

exports.createInventory = (req, res) => {
  const millId = getShopkeeperMillId(req.user);
  const { productType = 'FLOUR', name, stockKg = 0, minimumStockKg = 20, pricePerKg = 0 } = req.body;

  if (!name) {
    return res.status(400).json({ status: 'error', message: 'Item name is required' });
  }

  const newItem = {
    id: store.inventory.length + 1,
    millId,
    productType,
    name,
    stockKg: parseFloat(stockKg),
    minimumStockKg: parseFloat(minimumStockKg),
    pricePerKg: parseFloat(pricePerKg),
    updatedAt: new Date().toISOString()
  };

  store.inventory.push(newItem);
  res.status(201).json({ status: 'success', message: 'Inventory item added', data: { item: newItem } });
};

exports.updateInventory = (req, res) => {
  const id = parseInt(req.params.id);
  const item = store.inventory.find(i => i.id === id);

  if (!item) {
    return res.status(404).json({ status: 'error', message: 'Inventory item not found' });
  }

  Object.assign(item, req.body);
  item.updatedAt = new Date().toISOString();

  res.json({ status: 'success', message: 'Inventory item updated', data: { item } });
};

exports.deleteInventory = (req, res) => {
  const id = parseInt(req.params.id);
  const index = store.inventory.findIndex(i => i.id === id);

  if (index === -1) {
    return res.status(404).json({ status: 'error', message: 'Inventory item not found' });
  }

  store.inventory.splice(index, 1);
  res.json({ status: 'success', message: 'Inventory item deleted' });
};

exports.stockIn = (req, res) => {
  const id = parseInt(req.params.id);
  const { kg } = req.body;
  const item = store.inventory.find(i => i.id === id);

  if (!item) {
    return res.status(404).json({ status: 'error', message: 'Inventory item not found' });
  }

  item.stockKg += parseFloat(kg || 0);
  item.updatedAt = new Date().toISOString();

  res.json({ status: 'success', message: `Added ${kg} kg to stock`, data: { item } });
};

exports.stockOut = (req, res) => {
  const id = parseInt(req.params.id);
  const { kg } = req.body;
  const item = store.inventory.find(i => i.id === id);

  if (!item) {
    return res.status(404).json({ status: 'error', message: 'Inventory item not found' });
  }

  item.stockKg = Math.max(0, item.stockKg - parseFloat(kg || 0));
  item.updatedAt = new Date().toISOString();

  res.json({ status: 'success', message: `Deducted ${kg} kg from stock`, data: { item } });
};

/**
 * @desc Shop Availability & Services
 */
exports.getAvailability = (req, res) => {
  const millId = getShopkeeperMillId(req.user);
  const mill = store.mills.find(m => m.id === millId);

  res.json({
    status: 'success',
    data: {
      isOpen: mill ? mill.isOpen : true,
      services: mill ? mill.services : []
    }
  });
};

exports.updateAvailability = (req, res) => {
  const millId = getShopkeeperMillId(req.user);
  const mill = store.mills.find(m => m.id === millId);

  if (!mill) {
    return res.status(404).json({ status: 'error', message: 'Mill not found' });
  }

  const { isOpen } = req.body;
  if (isOpen !== undefined) {
    mill.isOpen = !!isOpen;
  }

  res.json({ status: 'success', message: 'Mill availability updated', data: { isOpen: mill.isOpen } });
};

exports.getServices = (req, res) => {
  const millId = getShopkeeperMillId(req.user);
  const mill = store.mills.find(m => m.id === millId);
  res.json({ status: 'success', data: { services: mill ? mill.services : [] } });
};

exports.updateServices = (req, res) => {
  const millId = getShopkeeperMillId(req.user);
  const mill = store.mills.find(m => m.id === millId);

  if (!mill) {
    return res.status(404).json({ status: 'error', message: 'Mill not found' });
  }

  const { services } = req.body;
  if (Array.isArray(services)) {
    mill.services = services;
  }

  res.json({ status: 'success', message: 'Services updated', data: { services: mill.services } });
};

exports.updateWorkingHours = (req, res) => {
  const millId = getShopkeeperMillId(req.user);
  const mill = store.mills.find(m => m.id === millId);

  if (!mill) {
    return res.status(404).json({ status: 'error', message: 'Mill not found' });
  }

  const { workingHours } = req.body;
  if (workingHours) {
    mill.workingHours = workingHours;
  }

  res.json({ status: 'success', message: 'Working hours updated', data: { workingHours: mill.workingHours } });
};

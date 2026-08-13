const store = require('../store/dataStore');
const { ORDER_STATUS, FULFILLMENT_TYPES } = require('../constants/enums');

// Helper to get Mill ID associated with logged-in Shopkeeper
function getShopkeeperMillId(user) {
  return user.millId || 101; // Default to 101 for shopkeeper user
}

exports.getDashboard = (req, res) => {
  const millId = getShopkeeperMillId(req.user);
  const millOrders = store.orders.filter(o => o.millId === millId);

  const pendingCount = millOrders.filter(o => o.status === ORDER_STATUS.PLACED).length;
  const activeCount = millOrders.filter(o => [ORDER_STATUS.ACCEPTED, ORDER_STATUS.PROCESSING, ORDER_STATUS.PACKING].includes(o.status)).length;
  const completedCount = millOrders.filter(o => [ORDER_STATUS.DELIVERED, ORDER_STATUS.PICKED_UP, ORDER_STATUS.COMPLETED].includes(o.status)).length;
  const totalRevenue = millOrders
    .filter(o => o.paymentStatus === 'PAID')
    .reduce((sum, o) => sum + o.totalAmount, 0);

  res.json({
    status: 'success',
    data: {
      millId,
      metrics: {
        pendingOrders: pendingCount,
        activeOrders: activeCount,
        completedOrders: completedCount,
        totalRevenue: parseFloat(totalRevenue.toFixed(2))
      }
    }
  });
};

exports.getTodayOrders = (req, res) => {
  const millId = getShopkeeperMillId(req.user);
  const millOrders = store.orders.filter(o => o.millId === millId);
  res.json({ status: 'success', count: millOrders.length, data: { orders: millOrders } });
};

exports.getPendingOrders = (req, res) => {
  const millId = getShopkeeperMillId(req.user);
  const pending = store.orders.filter(o => o.millId === millId && o.status === ORDER_STATUS.PLACED);
  res.json({ status: 'success', count: pending.length, data: { orders: pending } });
};

exports.getNewOrders = (req, res) => {
  return exports.getPendingOrders(req, res);
};

exports.getActiveOrders = (req, res) => {
  const millId = getShopkeeperMillId(req.user);
  const activeStatuses = [ORDER_STATUS.ACCEPTED, ORDER_STATUS.PROCESSING, ORDER_STATUS.PACKING, ORDER_STATUS.READY, ORDER_STATUS.READY_FOR_PICKUP];
  const active = store.orders.filter(o => o.millId === millId && activeStatuses.includes(o.status));
  res.json({ status: 'success', count: active.length, data: { orders: active } });
};

exports.getCompletedOrders = (req, res) => {
  const millId = getShopkeeperMillId(req.user);
  const completedStatuses = [ORDER_STATUS.DELIVERED, ORDER_STATUS.PICKED_UP, ORDER_STATUS.COMPLETED];
  const completed = store.orders.filter(o => o.millId === millId && completedStatuses.includes(o.status));
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

exports.acceptOrder = (req, res) => {
  const orderId = parseInt(req.params.orderId);
  const { estimatedCompletionMinutes = 45 } = req.body;
  const order = store.orders.find(o => o.id === orderId);

  if (!order) {
    return res.status(404).json({ status: 'error', message: 'Order not found' });
  }

  order.status = ORDER_STATUS.ACCEPTED;
  order.estimatedMinutes = estimatedCompletionMinutes;
  order.estimatedCompletionTime = new Date(Date.now() + estimatedCompletionMinutes * 60000).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
  order.timeline.push({
    status: ORDER_STATUS.ACCEPTED,
    timestamp: new Date().toISOString(),
    note: `Accepted by shopkeeper (Est: ${estimatedCompletionMinutes} mins)`
  });

  res.json({ status: 'success', message: 'Order accepted', data: { order } });
};

exports.rejectOrder = (req, res) => {
  const orderId = parseInt(req.params.orderId);
  const { reason = 'Machine unavailable' } = req.body;
  const order = store.orders.find(o => o.id === orderId);

  if (!order) {
    return res.status(404).json({ status: 'error', message: 'Order not found' });
  }

  order.status = ORDER_STATUS.REJECTED;
  order.timeline.push({
    status: ORDER_STATUS.REJECTED,
    timestamp: new Date().toISOString(),
    note: `Rejected by shopkeeper: ${reason}`
  });

  res.json({ status: 'success', message: 'Order rejected', data: { order } });
};

exports.setCompletionTime = (req, res) => {
  const orderId = parseInt(req.params.orderId);
  const { estimatedCompletionMinutes, estimatedCompletionTime } = req.body;
  const order = store.orders.find(o => o.id === orderId);

  if (!order) {
    return res.status(404).json({ status: 'error', message: 'Order not found' });
  }

  if (estimatedCompletionMinutes) order.estimatedMinutes = estimatedCompletionMinutes;
  if (estimatedCompletionTime) order.estimatedCompletionTime = estimatedCompletionTime;

  res.json({ status: 'success', message: 'Completion time updated', data: { order } });
};

// Processing State Machine Transitions
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
    note: 'Grinding process started'
  });

  res.json({ status: 'success', message: 'Order processing started', data: { order } });
};

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
    note: 'Packing started'
  });

  res.json({ status: 'success', message: 'Order packing started', data: { order } });
};

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
    note: `Order ready for ${order.fulfillmentType.toLowerCase()}`
  });

  res.json({ status: 'success', message: `Order marked ${nextStatus}`, data: { order } });
};

exports.handoverDelivery = (req, res) => {
  const orderId = parseInt(req.params.orderId);
  const order = store.orders.find(o => o.id === orderId);

  if (!order) {
    return res.status(404).json({ status: 'error', message: 'Order not found' });
  }

  order.status = ORDER_STATUS.OUT_FOR_DELIVERY;
  order.timeline.push({
    status: ORDER_STATUS.OUT_FOR_DELIVERY,
    timestamp: new Date().toISOString(),
    note: 'Handed over to delivery person'
  });

  res.json({ status: 'success', message: 'Order handed over to delivery', data: { order } });
};

exports.completeOrder = (req, res) => {
  const orderId = parseInt(req.params.orderId);
  const order = store.orders.find(o => o.id === orderId);

  if (!order) {
    return res.status(404).json({ status: 'error', message: 'Order not found' });
  }

  const statusVal = order.fulfillmentType === FULFILLMENT_TYPES.PICKUP ? ORDER_STATUS.PICKED_UP : ORDER_STATUS.COMPLETED;
  order.status = statusVal;
  order.timeline.push({
    status: statusVal,
    timestamp: new Date().toISOString(),
    note: 'Order completed'
  });

  res.json({ status: 'success', message: 'Order completed', data: { order } });
};

// Inventory Management
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

// Availability & Services
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

exports.getAvailability = (req, res) => {
  const millId = getShopkeeperMillId(req.user);
  const mill = store.mills.find(m => m.id === millId);

  res.json({
    status: 'success',
    data: {
      isOpen: mill ? mill.isOpen : false,
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

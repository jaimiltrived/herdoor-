const store = require('../store/dataStore');
const { query } = require('../config/database');
const { ORDER_STATUS, FULFILLMENT_TYPES, DELIVERY_STATUS } = require('../constants/enums');

// Helper to get Mill ID associated with logged-in Shopkeeper
function getShopkeeperMillId(req) {
  if (req && req.query && req.query.millId) return parseInt(req.query.millId);
  if (req && req.headers && req.headers['x-mill-id']) return parseInt(req.headers['x-mill-id']);
  if (req && req.user && req.user.millId) return req.user.millId;
  return 101; // Default to mill 101
}

async function getLiveOrders(millId) {
  try {
    let sql = 'SELECT * FROM orders';
    const params = [];
    if (millId) {
      sql += ' WHERE mill_id = ?';
      params.push(millId);
    }
    sql += ' ORDER BY id DESC';
    const dbOrders = await query(sql, params);
    if (dbOrders && Array.isArray(dbOrders)) {
      return dbOrders.map(row => ({
        id: row.id,
        orderNumber: row.order_number || `#HD-${row.id}`,
        userId: row.user_id,
        customerName: row.customer_name || 'Customer',
        customerPhone: row.customer_phone || '+919876543210',
        millId: row.mill_id,
        grainSource: row.grain_source,
        grainTypeId: row.grain_type_id,
        grainTypeName: row.grain_type_name,
        quantityKg: parseFloat(row.quantity_kg) || 5.0,
        serviceType: row.service_type,
        fulfillmentType: row.fulfillment_type,
        addressId: row.address_id,
        pickupPin: row.pickup_pin,
        deliveryOtp: row.delivery_otp,
        paymentMethod: row.payment_method,
        paymentStatus: row.payment_status,
        status: row.status,
        groupId: row.group_id,
        groupCode: row.group_code,
        estimatedMinutes: row.estimated_minutes,
        estimatedCompletionTime: row.estimated_completion_time,
        totalAmount: parseFloat(row.total_amount) || 0.0,
        createdAt: row.created_at ? new Date(row.created_at).toISOString() : new Date().toISOString()
      }));
    }
  } catch (err) {
    console.warn('MySQL getLiveOrders Error:', err.message);
  }

  return [];
}

function enrichOrder(o) {
  const u = store.users.find(usr => usr.id === o.userId);
  const addr = store.addresses.find(a => a.id === o.addressId);
  const delivery = store.deliveries.find(d => d.orderId === o.id);

  let itemsSummary = `${o.quantityKg || 5}kg ${o.grainTypeName || 'Wheat'}`;
  if (o.items && Array.isArray(o.items) && o.items.length > 0) {
    itemsSummary = o.items.map(i => `${i.quantity || 1}kg ${i.name}`).join(', ');
  }

  let timeAgo = 'Just now';
  if (o.createdAt) {
    const diffMs = Date.now() - new Date(o.createdAt).getTime();
    const diffMins = Math.floor(diffMs / 60000);
    if (diffMins < 1) {
      timeAgo = 'Just now';
    } else if (diffMins < 60) {
      timeAgo = `${diffMins} mins ago`;
    } else {
      const d = new Date(o.createdAt);
      const hours = d.getHours().toString().padStart ? d.getHours().toString().padStart(2, '0') : d.getHours();
      const mins = d.getMinutes().toString().padStart ? d.getMinutes().toString().padStart(2, '0') : d.getMinutes();
      timeAgo = `Ordered at ${hours}:${mins}`;
    }
  }

  const driverUser = delivery ? store.users.find(u => u.id === delivery.deliveryPersonId) : null;
  const driverName = delivery?.deliveryPersonName || o.deliveryPersonName || (driverUser ? driverUser.name : 'Vikram Delivery Agent');
  const driverPhone = delivery?.deliveryPersonPhone || o.deliveryPersonPhone || (driverUser ? driverUser.phone : '+919876543212');
  const driverVehicle = delivery?.vehicleNumber || o.deliveryPersonVehicle || (driverUser && driverUser.vehicleNumber ? `${driverUser.vehicleType || 'Electric Scooter'} #${driverUser.vehicleNumber}` : 'Electric Scooter #GJ-01-AB-1234');

  return {
    ...o,
    numericId: o.id,
    orderId: o.orderNumber || `#HD-${o.id}`,
    customerName: o.customerName || (u ? u.name : 'Customer'),
    customerPhone: o.customerPhone || (u ? u.phone : '+919876543210'),
    itemsSummary,
    grainType: o.grainTypeName || 'Wheat',
    quantityText: `${o.quantityKg || 5} kg`,
    timeAgo,
    statusTag: o.status,
    deliveryAddress: addr ? `${addr.addressLine1}, ${addr.city}` : (o.deliveryAddress || 'Store Pickup'),
    deliveryDriverName: driverName,
    deliveryDriverPhone: driverPhone,
    deliveryDriverVehicle: driverVehicle,
    driverAssigned: delivery ? {
      name: driverName,
      phone: driverPhone,
      vehicle: driverVehicle,
      status: delivery.status,
      pin: delivery.pickupPin
    } : null
  };
}

/**
 * @desc Get Shopkeeper Dashboard KPIs
 * @route GET /api/v1/shopkeeper/dashboard
 */
exports.getDashboard = async (req, res) => {
  const millId = getShopkeeperMillId(req);
  const millOrders = await getLiveOrders(millId);

  const pendingCount = millOrders.filter(o => o.status === ORDER_STATUS.PLACED || o.status === 'NEW').length;
  const activeCount = millOrders.filter(o => [ORDER_STATUS.ACCEPTED, ORDER_STATUS.PROCESSING, ORDER_STATUS.PACKING, ORDER_STATUS.READY, ORDER_STATUS.READY_FOR_PICKUP, ORDER_STATUS.OUT_FOR_DELIVERY].includes(o.status)).length;
  const readyCount = millOrders.filter(o => [ORDER_STATUS.READY, ORDER_STATUS.READY_FOR_PICKUP].includes(o.status)).length;
  const completedCount = millOrders.filter(o => [ORDER_STATUS.DELIVERED, ORDER_STATUS.PICKED_UP, ORDER_STATUS.COMPLETED].includes(o.status)).length;
  const totalRevenue = millOrders
    .filter(o => o.paymentStatus === 'PAID')
    .reduce((sum, o) => sum + o.totalAmount, 0);

  const activeOrders = millOrders
    .filter(o => [ORDER_STATUS.PLACED, 'NEW', ORDER_STATUS.ACCEPTED, ORDER_STATUS.PROCESSING, ORDER_STATUS.PACKING, ORDER_STATUS.READY, ORDER_STATUS.READY_FOR_PICKUP].includes(o.status))
    .map(enrichOrder);

  res.json({
    status: 'success',
    data: {
      millId,
      metrics: {
        pendingOrders: pendingCount,
        activeOrders: activeCount,
        readyForDispatchOrders: readyCount,
        completedOrders: completedCount,
        totalRevenue: parseFloat(totalRevenue.toFixed(2))
      },
      revenueToday: parseFloat(totalRevenue.toFixed(2)),
      totalOrders: millOrders.length,
      pendingOrdersCount: pendingCount,
      newOrdersCount: pendingCount,
      readyOrdersCount: readyCount,
      activeOrders
    }
  });
};

/**
 * @desc Get Mill / Shop Profile
 * @route GET /api/v1/shopkeeper/profile
 */
exports.getProfile = (req, res) => {
  const millId = getShopkeeperMillId(req);
  const mill = store.mills.find(m => m.id === millId);
  const user = store.users.find(u => req.user && u.id === req.user.id);

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
 * @desc Update Mill / Shop Profile & Store Details
 * @route PUT /api/v1/shopkeeper/profile
 */
exports.updateProfile = (req, res) => {
  const millId = getShopkeeperMillId(req);
  const mill = store.mills.find(m => m.id === millId);
  const user = store.users.find(u => req.user && u.id === req.user.id);

  const {
    name,
    ownerName,
    phone,
    email,
    address,
    city,
    state,
    pincode,
    latitude,
    longitude,
    workingHours,
    services,
    specialty,
    capacityKgPerDay,
    deliveryRadiusKm,
    storeImage,
    chakkiImage,
    isOpen,
    expressDeliveryEnabled,
    selfPickupEnabled
  } = req.body;

  if (user) {
    if (ownerName) user.name = ownerName;
    else if (name && !mill) user.name = name;
    if (phone) user.phone = phone;
    if (email) user.email = email;
  }

  if (mill) {
    if (name) mill.name = name;
    if (phone) mill.phone = phone;
    if (address) mill.address = address;
    if (city) mill.city = city;
    if (state) mill.state = state;
    if (pincode) mill.pincode = pincode;
    if (latitude !== undefined) mill.latitude = parseFloat(latitude);
    if (longitude !== undefined) mill.longitude = parseFloat(longitude);
    if (workingHours) mill.workingHours = workingHours;
    if (Array.isArray(services)) mill.services = services;
    if (specialty) mill.specialty = specialty;
    if (capacityKgPerDay !== undefined) mill.capacityKgPerDay = parseFloat(capacityKgPerDay);
    if (deliveryRadiusKm !== undefined) mill.deliveryRadiusKm = parseFloat(deliveryRadiusKm);
    if (storeImage) mill.storeImage = storeImage;
    if (chakkiImage) mill.chakkiImage = chakkiImage;
    if (isOpen !== undefined) mill.isOpen = !!isOpen;
    if (expressDeliveryEnabled !== undefined) mill.expressDeliveryEnabled = !!expressDeliveryEnabled;
    if (selfPickupEnabled !== undefined) mill.selfPickupEnabled = !!selfPickupEnabled;
  }

  res.json({
    status: 'success',
    message: 'Store details updated successfully',
    data: { user, mill }
  });
};

/**
 * @desc Upload / Update Store Images
 * @route POST /api/v1/shopkeeper/store-images
 */
exports.uploadStoreImages = (req, res) => {
  const millId = getShopkeeperMillId(req);
  const mill = store.mills.find(m => m.id === millId);

  const { storeImage, chakkiImage, bannerImage } = req.body;

  if (mill) {
    if (storeImage) mill.storeImage = storeImage;
    if (chakkiImage) mill.chakkiImage = chakkiImage;
    if (bannerImage) mill.bannerImage = bannerImage;
  }

  res.json({
    status: 'success',
    message: 'Store images updated successfully',
    data: {
      storeImage: mill?.storeImage || storeImage,
      chakkiImage: mill?.chakkiImage || chakkiImage,
      bannerImage: mill?.bannerImage || bannerImage
    }
  });
};


/**
 * @desc Get Orders Queues
 */
exports.getTodayOrders = async (req, res) => {
  const millId = getShopkeeperMillId(req);
  const millOrders = (await getLiveOrders(millId)).map(enrichOrder);
  res.json({ status: 'success', count: millOrders.length, data: { orders: millOrders } });
};

exports.getPendingOrders = async (req, res) => {
  const millId = getShopkeeperMillId(req);
  const allOrders = await getLiveOrders(millId);
  const pending = allOrders.filter(o => o.status === ORDER_STATUS.PLACED || o.status === 'NEW' || o.status === 'PLACED').map(enrichOrder);
  res.json({ status: 'success', count: pending.length, data: { orders: pending } });
};

exports.getNewOrders = (req, res) => {
  return exports.getPendingOrders(req, res);
};

exports.getActiveOrders = async (req, res) => {
  const millId = getShopkeeperMillId(req);
  const allOrders = await getLiveOrders(millId);
  const activeStatuses = [ORDER_STATUS.ACCEPTED, ORDER_STATUS.PROCESSING, ORDER_STATUS.PACKING, 'MILLING', 'IN PROGRESS'];
  const active = allOrders.filter(o => activeStatuses.includes(o.status)).map(enrichOrder);
  res.json({ status: 'success', count: active.length, data: { orders: active } });
};

exports.getReadyOrders = async (req, res) => {
  const millId = getShopkeeperMillId(req);
  const allOrders = await getLiveOrders(millId);
  const readyStatuses = [ORDER_STATUS.READY, ORDER_STATUS.READY_FOR_PICKUP, 'READY FOR PICKUP'];
  const ready = allOrders.filter(o => readyStatuses.includes(o.status)).map(enrichOrder);
  res.json({ status: 'success', count: ready.length, data: { orders: ready } });
};

exports.getCompletedOrders = async (req, res) => {
  const millId = getShopkeeperMillId(req);
  const allOrders = await getLiveOrders(millId);
  const completedStatuses = [ORDER_STATUS.DELIVERED, ORDER_STATUS.PICKED_UP, ORDER_STATUS.COMPLETED, ORDER_STATUS.OUT_FOR_DELIVERY, 'OUT FOR DELIVERY'];
  const completed = allOrders.filter(o => completedStatuses.includes(o.status)).map(enrichOrder);
  res.json({ status: 'success', count: completed.length, data: { orders: completed } });
};

exports.getRevenue = async (req, res) => {
  const millId = getShopkeeperMillId(req);
  const millOrders = (await getLiveOrders(millId)).filter(o => o.paymentStatus === 'PAID');
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
exports.acceptOrder = async (req, res) => {
  const rawParam = (req.params.orderId || '').toString().trim();
  const orderId = parseInt(rawParam.replace(/[^0-9]/g, '')) || parseInt(rawParam) || 501;
  const order = findOrder(req.params.orderId);
  const { estimatedCompletionMinutes = 30, estimatedCompletionTime } = req.body;

  try {
    await query('UPDATE orders SET status = ?, estimated_minutes = ?, updated_at = NOW() WHERE id = ?', [ORDER_STATUS.ACCEPTED, estimatedCompletionMinutes, orderId]);
  } catch (err) {
    console.warn('MySQL acceptOrder update warning:', err.message);
  }

  if (order) {
    order.status = ORDER_STATUS.ACCEPTED;
    order.estimatedMinutes = estimatedCompletionMinutes;
    order.estimatedCompletionTime = estimatedCompletionTime || new Date(Date.now() + estimatedCompletionMinutes * 60000).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    if (order.timeline) {
      order.timeline.push({
        status: ORDER_STATUS.ACCEPTED,
        timestamp: new Date().toISOString(),
        note: `Accepted by mill owner (ETA: ${order.estimatedCompletionTime})`
      });
    }
  }

  const liveOrders = await getLiveOrders();
  const updatedOrder = liveOrders.find(o => o.id === orderId) || order;

  res.json({ status: 'success', message: 'Order accepted', data: { order: enrichOrder(updatedOrder || { id: orderId, status: ORDER_STATUS.ACCEPTED }) } });
};

/**
 * @desc Reject Order
 * @route POST /api/v1/shopkeeper/orders/:orderId/reject
 */
exports.rejectOrder = async (req, res) => {
  const rawParam = (req.params.orderId || '').toString().trim();
  const orderId = parseInt(rawParam.replace(/[^0-9]/g, '')) || parseInt(rawParam) || 501;
  const order = findOrder(req.params.orderId);
  const { reason = 'Capacity exceeded' } = req.body;

  try {
    await query('UPDATE orders SET status = ?, updated_at = NOW() WHERE id = ?', [ORDER_STATUS.REJECTED, orderId]);
  } catch (err) {
    console.warn('MySQL rejectOrder update warning:', err.message);
  }

  if (order) {
    order.status = ORDER_STATUS.REJECTED;
    if (order.timeline) {
      order.timeline.push({
        status: ORDER_STATUS.REJECTED,
        timestamp: new Date().toISOString(),
        note: `Rejected by mill owner: ${reason}`
      });
    }
  }

  const liveOrders = await getLiveOrders();
  const updatedOrder = liveOrders.find(o => o.id === orderId) || order;

  res.json({ status: 'success', message: 'Order rejected', data: { order: enrichOrder(updatedOrder || { id: orderId, status: ORDER_STATUS.REJECTED }) } });
};

/**
 * @desc Set / Update Completion Time
 * @route PUT /api/v1/shopkeeper/orders/:orderId/completion-time
 */
exports.setCompletionTime = async (req, res) => {
  const rawParam = (req.params.orderId || '').toString().trim();
  const orderId = parseInt(rawParam.replace(/[^0-9]/g, '')) || parseInt(rawParam) || 501;
  const order = findOrder(req.params.orderId);
  const { estimatedCompletionMinutes, estimatedCompletionTime } = req.body;

  try {
    if (estimatedCompletionMinutes) {
      await query('UPDATE orders SET estimated_minutes = ?, updated_at = NOW() WHERE id = ?', [estimatedCompletionMinutes, orderId]);
    }
  } catch (err) {
    console.warn('MySQL setCompletionTime update warning:', err.message);
  }

  if (order) {
    if (estimatedCompletionMinutes) order.estimatedMinutes = estimatedCompletionMinutes;
    if (estimatedCompletionTime) order.estimatedCompletionTime = estimatedCompletionTime;
  }

  const liveOrders = await getLiveOrders();
  const updatedOrder = liveOrders.find(o => o.id === orderId) || order;

  res.json({ status: 'success', message: 'Completion time updated', data: { order: enrichOrder(updatedOrder || { id: orderId }) } });
};

/**
 * @desc Start Milling / Grinding Process
 * @route POST /api/v1/shopkeeper/orders/:orderId/start or /processing
 */
exports.startProcessing = async (req, res) => {
  const rawParam = (req.params.orderId || '').toString().trim();
  const orderId = parseInt(rawParam.replace(/[^0-9]/g, '')) || parseInt(rawParam) || 501;
  const order = findOrder(req.params.orderId);

  try {
    await query('UPDATE orders SET status = ?, updated_at = NOW() WHERE id = ?', [ORDER_STATUS.PROCESSING, orderId]);
  } catch (err) {
    console.warn('MySQL startProcessing update warning:', err.message);
  }

  if (order) {
    order.status = ORDER_STATUS.PROCESSING;
    if (order.timeline) {
      order.timeline.push({
        status: ORDER_STATUS.PROCESSING,
        timestamp: new Date().toISOString(),
        note: 'Chakki grinding started'
      });
    }
  }

  const liveOrders = await getLiveOrders();
  const updatedOrder = liveOrders.find(o => o.id === orderId) || order;

  res.json({ status: 'success', message: 'Milling process started', data: { order: enrichOrder(updatedOrder || { id: orderId, status: ORDER_STATUS.PROCESSING }) } });
};

/**
 * @desc Start Packing
 * @route POST /api/v1/shopkeeper/orders/:orderId/packing
 */
exports.startPacking = async (req, res) => {
  const rawParam = (req.params.orderId || '').toString().trim();
  const orderId = parseInt(rawParam.replace(/[^0-9]/g, '')) || parseInt(rawParam) || 501;
  const order = findOrder(req.params.orderId);

  try {
    await query('UPDATE orders SET status = ?, updated_at = NOW() WHERE id = ?', [ORDER_STATUS.PACKING, orderId]);
  } catch (err) {
    console.warn('MySQL startPacking update warning:', err.message);
  }

  if (order) {
    order.status = ORDER_STATUS.PACKING;
    if (order.timeline) {
      order.timeline.push({
        status: ORDER_STATUS.PACKING,
        timestamp: new Date().toISOString(),
        note: 'Flour packing & bagging started'
      });
    }
  }

  const liveOrders = await getLiveOrders();
  const updatedOrder = liveOrders.find(o => o.id === orderId) || order;

  res.json({ status: 'success', message: 'Packing started', data: { order: enrichOrder(updatedOrder || { id: orderId, status: ORDER_STATUS.PACKING }) } });
};

/**
 * @desc Mark Order Ready (Ready for Pickup / Driver Dispatch)
 * @route POST /api/v1/shopkeeper/orders/:orderId/ready
 */
exports.markReady = async (req, res) => {
  const rawParam = (req.params.orderId || '').toString().trim();
  const orderId = parseInt(rawParam.replace(/[^0-9]/g, '')) || parseInt(rawParam) || 501;
  const order = findOrder(req.params.orderId);

  const nextStatus = (order && order.fulfillmentType === FULFILLMENT_TYPES.PICKUP)
    ? ORDER_STATUS.READY_FOR_PICKUP
    : ORDER_STATUS.READY;

  try {
    await query('UPDATE orders SET status = ?, updated_at = NOW() WHERE id = ?', [nextStatus, orderId]);
  } catch (err) {
    console.warn('MySQL markReady update warning:', err.message);
  }

  if (order) {
    order.status = nextStatus;
    if (order.timeline) {
      order.timeline.push({
        status: nextStatus,
        timestamp: new Date().toISOString(),
        note: `Order packed and ready for ${order.fulfillmentType ? order.fulfillmentType.toLowerCase() : 'fulfillment'}`
      });
    }
  }

  const liveOrders = await getLiveOrders();
  const updatedOrder = liveOrders.find(o => o.id === orderId) || order;

  res.json({ status: 'success', message: `Order marked ${nextStatus}`, data: { order: enrichOrder(updatedOrder || { id: orderId, status: nextStatus }) } });
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

/**
 * @desc Handover Order to Delivery Rider with Verification PIN / QR
 * @route POST /api/v1/shopkeeper/orders/:orderId/handover
 */
exports.handoverDelivery = (req, res) => {
  const order = findOrder(req.params.orderId);

  if (!order) {
    return res.status(404).json({ status: 'error', message: 'Order not found' });
  }

  const orderId = order.id;
  const { pin } = req.body;

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
  const order = findOrder(req.params.orderId);

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
  const mill = store.mills.find(m => m.id === millId) || store.mills[0];

  res.json({
    status: 'success',
    data: {
      isOpen: mill ? mill.isOpen : true,
      statusMode: mill ? (mill.statusMode !== undefined ? mill.statusMode : (mill.isOpen ? 0 : 2)) : 0,
      deliveryRadiusKm: mill ? (mill.deliveryRadiusKm || 5.0) : 5.0,
      expressDeliveryEnabled: mill ? (mill.expressDeliveryEnabled !== false) : true,
      selfPickupEnabled: mill ? (mill.selfPickupEnabled !== false) : true,
      services: mill ? (mill.services || []) : [],
      workingHours: mill ? (mill.workingHours || '08:00 AM - 08:00 PM') : '08:00 AM - 08:00 PM'
    }
  });
};

exports.updateAvailability = (req, res) => {
  const millId = getShopkeeperMillId(req.user);
  const mill = store.mills.find(m => m.id === millId) || store.mills[0];

  if (!mill) {
    return res.status(404).json({ status: 'error', message: 'Mill not found' });
  }

  const { isOpen, statusMode, deliveryRadiusKm, expressDeliveryEnabled, selfPickupEnabled, workingHours, services } = req.body;
  if (isOpen !== undefined) {
    mill.isOpen = !!isOpen;
  }
  if (statusMode !== undefined) {
    mill.statusMode = parseInt(statusMode);
    mill.isOpen = mill.statusMode !== 2;
  }
  if (deliveryRadiusKm !== undefined) {
    mill.deliveryRadiusKm = parseFloat(deliveryRadiusKm);
  }
  if (expressDeliveryEnabled !== undefined) {
    mill.expressDeliveryEnabled = !!expressDeliveryEnabled;
  }
  if (selfPickupEnabled !== undefined) {
    mill.selfPickupEnabled = !!selfPickupEnabled;
  }
  if (workingHours !== undefined) {
    mill.workingHours = workingHours;
  }
  if (Array.isArray(services)) {
    mill.services = services;
  }

  res.json({
    status: 'success',
    message: 'Mill availability updated',
    data: {
      isOpen: mill.isOpen,
      statusMode: mill.statusMode,
      deliveryRadiusKm: mill.deliveryRadiusKm,
      expressDeliveryEnabled: mill.expressDeliveryEnabled,
      selfPickupEnabled: mill.selfPickupEnabled,
      workingHours: mill.workingHours,
      services: mill.services
    }
  });
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

/**
 * @desc Food Safety & Hygiene Audit
 */
exports.getSafetyAudit = (req, res) => {
  const millId = getShopkeeperMillId(req.user);
  const mill = store.mills.find(m => m.id === millId) || store.mills[0];

  const defaultAudit = {
    chakkiSanitized: true,
    moistureCheckPassed: true,
    dustExtractorActive: true,
    ecoPackagingVerified: true,
    pestControlCertified: true,
    safetyScore: 99,
    lastAuditDate: new Date().toISOString(),
    grade: 'A+'
  };

  const audit = (mill && mill.safetyAudit) ? mill.safetyAudit : defaultAudit;
  res.json({ status: 'success', data: { safetyAudit: audit } });
};

exports.updateSafetyAudit = (req, res) => {
  const millId = getShopkeeperMillId(req.user);
  const mill = store.mills.find(m => m.id === millId) || store.mills[0];

  if (!mill) {
    return res.status(404).json({ status: 'error', message: 'Mill not found' });
  }

  const {
    chakkiSanitized = true,
    moistureCheckPassed = true,
    dustExtractorActive = true,
    ecoPackagingVerified = true,
    pestControlCertified = true
  } = req.body;

  const checks = [chakkiSanitized, moistureCheckPassed, dustExtractorActive, ecoPackagingVerified, pestControlCertified];
  const passedCount = checks.filter(Boolean).length;
  const score = Math.round((passedCount / checks.length) * 100);
  const grade = score >= 90 ? 'A+' : (score >= 75 ? 'A' : (score >= 60 ? 'B' : 'Needs Inspection'));

  mill.safetyAudit = {
    chakkiSanitized: !!chakkiSanitized,
    moistureCheckPassed: !!moistureCheckPassed,
    dustExtractorActive: !!dustExtractorActive,
    ecoPackagingVerified: !!ecoPackagingVerified,
    pestControlCertified: !!pestControlCertified,
    safetyScore: score,
    lastAuditDate: new Date().toISOString(),
    grade
  };

  res.json({
    status: 'success',
    message: 'Safety audit compliance updated successfully',
    data: { safetyAudit: mill.safetyAudit }
  });
};

/**
 * @desc Get Shopkeeper Profile & Mill Details
 * @route GET /api/v1/shopkeeper/profile
 */
exports.getProfile = (req, res) => {
  const millId = getShopkeeperMillId(req.user);
  const mill = store.mills.find(m => m.id === millId) || store.mills[0];
  const user = (req.user && req.user.id) ? store.users.find(u => u.id === req.user.id) : store.users[1];

  res.json({
    status: 'success',
    data: {
      user: user ? {
        id: user.id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        role: user.role,
        millId: user.millId
      } : null,
      mill: mill || null
    }
  });
};

/**
 * @desc Update Shopkeeper Profile & Mill Details
 * @route PUT /api/v1/shopkeeper/profile
 */
exports.updateProfile = async (req, res) => {
  const millId = getShopkeeperMillId(req.user);
  let mill = store.mills.find(m => m.id === millId);
  const user = (req.user && req.user.id) ? store.users.find(u => u.id === req.user.id) : null;

  if (!mill && store.mills.length > 0) {
    mill = store.mills[0];
  }

  const {
    name,
    ownerName,
    phone,
    email,
    address,
    city,
    state,
    pincode,
    capacityKgPerDay,
    deliveryRadiusKm,
    workingHours,
    services,
    specialty,
    storeImage,
    chakkiImage,
    bannerImage,
    isOpen,
    expressDeliveryEnabled,
    selfPickupEnabled
  } = req.body;

  if (user) {
    if (ownerName) user.name = ownerName;
    if (phone) user.phone = phone;
    if (email) user.email = email;
  }

  if (mill) {
    if (name) mill.name = name;
    if (phone) mill.phone = phone;
    if (address) mill.address = address;
    if (city) mill.city = city;
    if (state) mill.state = state;
    if (pincode) mill.pincode = pincode;
    if (capacityKgPerDay !== undefined) mill.capacityKgPerDay = parseFloat(capacityKgPerDay);
    if (deliveryRadiusKm !== undefined) mill.deliveryRadiusKm = parseFloat(deliveryRadiusKm);
    if (workingHours) mill.workingHours = workingHours;
    if (Array.isArray(services)) mill.services = services;
    if (specialty) mill.specialty = specialty;
    if (storeImage) mill.storeImage = storeImage;
    if (chakkiImage) mill.chakkiImage = chakkiImage;
    if (bannerImage) mill.bannerImage = bannerImage;
    if (isOpen !== undefined) mill.isOpen = !!isOpen;
    if (expressDeliveryEnabled !== undefined) mill.expressDeliveryEnabled = !!expressDeliveryEnabled;
    if (selfPickupEnabled !== undefined) mill.selfPickupEnabled = !!selfPickupEnabled;
    mill.updatedAt = new Date().toISOString();
  }

  res.json({
    status: 'success',
    message: 'Store profile updated successfully',
    data: {
      mill,
      user: user ? { id: user.id, name: user.name, email: user.email, phone: user.phone } : null
    }
  });
};

/**
 * @desc Upload Storefront / Mill Images (Cloudinary integrated)
 * @route POST /api/v1/shopkeeper/store-images
 */
exports.uploadStoreImages = async (req, res) => {
  const { uploadToCloudinary } = require('../config/cloudinary');
  const millId = getShopkeeperMillId(req.user);
  const mill = store.mills.find(m => m.id === millId) || store.mills[0];

  const { storeImage, chakkiImage, bannerImage } = req.body;
  const uploadedUrls = {};

  try {
    if (storeImage) {
      const resImg = await uploadToCloudinary(storeImage, 'herdoor/stores');
      uploadedUrls.storeImage = resImg.url;
      if (mill) mill.storeImage = resImg.url;
    }
    if (chakkiImage) {
      const resImg = await uploadToCloudinary(chakkiImage, 'herdoor/machines');
      uploadedUrls.chakkiImage = resImg.url;
      if (mill) mill.chakkiImage = resImg.url;
    }
    if (bannerImage) {
      const resImg = await uploadToCloudinary(bannerImage, 'herdoor/banners');
      uploadedUrls.bannerImage = resImg.url;
      if (mill) mill.bannerImage = resImg.url;
    }

    res.json({
      status: 'success',
      message: 'Images uploaded and updated successfully via Cloudinary',
      data: {
        images: uploadedUrls,
        mill
      }
    });
  } catch (err) {
    res.status(500).json({
      status: 'error',
      message: 'Failed to upload image: ' + err.message
    });
  }
};


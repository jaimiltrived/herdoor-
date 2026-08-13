const bcrypt = require('bcryptjs');
const store = require('../store/dataStore');
const { generateToken } = require('../utils/jwt');
const { ROLES, ORDER_STATUS, DELIVERY_STATUS } = require('../constants/enums');

exports.deliveryLogin = (req, res) => {
  const { phone, email, password } = req.body;
  const user = store.users.find(u => (u.phone === phone || u.email === email) && u.role === ROLES.DELIVERY);

  if (!user || !bcrypt.compareSync(password, user.password)) {
    return res.status(401).json({ status: 'error', message: 'Invalid delivery credentials' });
  }

  const token = generateToken({
    id: user.id,
    name: user.name,
    role: user.role
  });

  res.json({
    status: 'success',
    data: { user: { id: user.id, name: user.name, role: user.role }, token }
  });
};

exports.getDeliveryOrders = (req, res) => {
  res.json({ status: 'success', data: { deliveries: store.deliveries } });
};

exports.getAssignedOrders = (req, res) => {
  const assigned = store.deliveries.filter(d => d.deliveryPersonId === req.user.id);
  res.json({ status: 'success', data: { deliveries: assigned } });
};

exports.getDeliveryOrderById = (req, res) => {
  const orderId = parseInt(req.params.orderId);
  const delivery = store.deliveries.find(d => d.orderId === orderId);

  if (!delivery) {
    return res.status(404).json({ status: 'error', message: 'Delivery record not found' });
  }

  res.json({ status: 'success', data: { delivery } });
};

exports.acceptDelivery = (req, res) => {
  const orderId = parseInt(req.params.orderId);
  let delivery = store.deliveries.find(d => d.orderId === orderId);

  if (!delivery) {
    delivery = {
      id: 800 + store.deliveries.length + 1,
      orderId,
      deliveryPersonId: req.user.id,
      deliveryPersonName: req.user.name,
      status: DELIVERY_STATUS.ASSIGNED,
      updatedAt: new Date().toISOString()
    };
    store.deliveries.push(delivery);
  } else {
    delivery.deliveryPersonId = req.user.id;
    delivery.status = DELIVERY_STATUS.ASSIGNED;
    delivery.updatedAt = new Date().toISOString();
  }

  res.json({ status: 'success', message: 'Delivery task accepted', data: { delivery } });
};

exports.markPickedUp = (req, res) => {
  const orderId = parseInt(req.params.orderId);
  const delivery = store.deliveries.find(d => d.orderId === orderId);
  const order = store.orders.find(o => o.id === orderId);

  if (delivery) {
    delivery.status = DELIVERY_STATUS.PICKED_UP_FROM_MILL;
    delivery.updatedAt = new Date().toISOString();
  }

  if (order) {
    order.status = ORDER_STATUS.OUT_FOR_DELIVERY;
    order.timeline.push({
      status: ORDER_STATUS.OUT_FOR_DELIVERY,
      timestamp: new Date().toISOString(),
      note: 'Picked up from mill by delivery agent'
    });
  }

  res.json({ status: 'success', message: 'Order marked picked up from mill', data: { delivery } });
};

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

exports.markDelivered = (req, res) => {
  const orderId = parseInt(req.params.orderId);
  const delivery = store.deliveries.find(d => d.orderId === orderId);
  const order = store.orders.find(o => o.id === orderId);

  if (delivery) {
    delivery.status = DELIVERY_STATUS.DELIVERED;
    delivery.updatedAt = new Date().toISOString();
  }

  if (order) {
    order.status = ORDER_STATUS.DELIVERED;
    order.timeline.push({
      status: ORDER_STATUS.DELIVERED,
      timestamp: new Date().toISOString(),
      note: 'Order successfully delivered to customer'
    });
  }

  res.json({ status: 'success', message: 'Order marked delivered', data: { delivery } });
};

exports.getDeliveryTracking = (req, res) => {
  const deliveryId = parseInt(req.params.deliveryId);
  const delivery = store.deliveries.find(d => d.id === deliveryId);

  if (!delivery) {
    return res.status(404).json({ status: 'error', message: 'Delivery record not found' });
  }

  res.json({ status: 'success', data: { delivery } });
};

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

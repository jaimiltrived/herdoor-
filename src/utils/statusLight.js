const {
  ORDER_STATUS,
  DELIVERY_STATUS,
  PAYMENT_STATUS,
  GROUP_RUN_STATUS,
  STATUS_LIGHT,
  STATUS_LIGHT_DEFS
} = require('../constants/enums');

const ORDER_STATUS_LIGHT_MAP = {
  [ORDER_STATUS.PENDING]: STATUS_LIGHT.AMBER,
  [ORDER_STATUS.PLACED]: STATUS_LIGHT.AMBER,
  [ORDER_STATUS.NEW]: STATUS_LIGHT.AMBER,
  [ORDER_STATUS.CONFIRMED]: STATUS_LIGHT.AMBER,
  [ORDER_STATUS.ACCEPTED]: STATUS_LIGHT.GREEN,
  [ORDER_STATUS.MILLING]: STATUS_LIGHT.AMBER,
  [ORDER_STATUS.PROCESSING]: STATUS_LIGHT.AMBER,
  [ORDER_STATUS.PACKING]: STATUS_LIGHT.AMBER,
  [ORDER_STATUS.READY]: STATUS_LIGHT.GREEN,
  [ORDER_STATUS.READY_FOR_PICKUP]: STATUS_LIGHT.GREEN,
  [ORDER_STATUS.OUT_FOR_DELIVERY]: STATUS_LIGHT.BLUE,
  [ORDER_STATUS.PICKED_UP]: STATUS_LIGHT.BLUE,
  [ORDER_STATUS.DELIVERED]: STATUS_LIGHT.GREEN,
  [ORDER_STATUS.COMPLETED]: STATUS_LIGHT.GREEN,
  [ORDER_STATUS.CANCELLED]: STATUS_LIGHT.RED,
  [ORDER_STATUS.REJECTED]: STATUS_LIGHT.RED,
  [ORDER_STATUS.PAYMENT_FAILED]: STATUS_LIGHT.RED,
  [ORDER_STATUS.DELIVERY_FAILED]: STATUS_LIGHT.RED,
  [ORDER_STATUS.RETURNED]: STATUS_LIGHT.RED,
  'IN PROGRESS': STATUS_LIGHT.AMBER,
  'NEW REQUESTS PENDING': STATUS_LIGHT.RED,
  'BATCH IN PROGRESS': STATUS_LIGHT.AMBER,
  'ALL STOPS DELIVERED': STATUS_LIGHT.GREEN
};

const PAYMENT_STATUS_LIGHT_MAP = {
  [PAYMENT_STATUS.PENDING]: STATUS_LIGHT.AMBER,
  [PAYMENT_STATUS.PAID]: STATUS_LIGHT.GREEN,
  [PAYMENT_STATUS.FAILED]: STATUS_LIGHT.RED,
  [PAYMENT_STATUS.REFUNDED]: STATUS_LIGHT.GREY,
  'CREATED': STATUS_LIGHT.AMBER
};

const DELIVERY_STATUS_LIGHT_MAP = {
  [DELIVERY_STATUS.ASSIGNED]: STATUS_LIGHT.AMBER,
  [DELIVERY_STATUS.PICKED_UP_FROM_MILL]: STATUS_LIGHT.BLUE,
  [DELIVERY_STATUS.OUT_FOR_DELIVERY]: STATUS_LIGHT.BLUE,
  [DELIVERY_STATUS.ARRIVED]: STATUS_LIGHT.AMBER,
  [DELIVERY_STATUS.DELIVERED]: STATUS_LIGHT.GREEN
};

const GROUP_RUN_LIGHT_MAP = {
  [GROUP_RUN_STATUS.CREATED]: STATUS_LIGHT.AMBER,
  [GROUP_RUN_STATUS.ASSIGNED]: STATUS_LIGHT.AMBER,
  [GROUP_RUN_STATUS.ACCEPTED]: STATUS_LIGHT.GREEN,
  [GROUP_RUN_STATUS.AT_MILL]: STATUS_LIGHT.AMBER,
  [GROUP_RUN_STATUS.IN_TRANSIT]: STATUS_LIGHT.BLUE,
  [GROUP_RUN_STATUS.COMPLETED]: STATUS_LIGHT.GREEN,
  [GROUP_RUN_STATUS.CANCELLED]: STATUS_LIGHT.RED
};

const MILL_STATUS_LIGHT_MAP = {
  'Active': STATUS_LIGHT.GREEN,
  'Maintenance': STATUS_LIGHT.AMBER,
  'Inactive': STATUS_LIGHT.GREY,
  'Offline': STATUS_LIGHT.RED
};

const USER_STATUS_LIGHT_MAP = {
  'Active': STATUS_LIGHT.GREEN,
  'VIP': STATUS_LIGHT.GREEN,
  'Inactive': STATUS_LIGHT.GREY,
  'Suspended': STATUS_LIGHT.RED,
  'Pending': STATUS_LIGHT.AMBER,
  'APPROVED': STATUS_LIGHT.GREEN,
  'PENDING': STATUS_LIGHT.AMBER,
  'REJECTED': STATUS_LIGHT.RED,
  'Pending Review': STATUS_LIGHT.AMBER,
  'Approved & Active': STATUS_LIGHT.GREEN,
  'Rejected': STATUS_LIGHT.RED
};

function resolveLightFromMap(map, status, fallback = STATUS_LIGHT.GREY) {
  if (!status) return fallback;
  const normalized = String(status).toUpperCase().trim();
  if (map[normalized]) return map[normalized];
  const original = String(status).trim();
  if (map[original]) return map[original];
  for (const key of Object.keys(map)) {
    if (key.toUpperCase() === normalized) return map[key];
  }
  return fallback;
}

function getOrderStatusLight(status) {
  return resolveLightFromMap(ORDER_STATUS_LIGHT_MAP, status);
}

function getPaymentStatusLight(status) {
  return resolveLightFromMap(PAYMENT_STATUS_LIGHT_MAP, status);
}

function getDeliveryStatusLight(status) {
  return resolveLightFromMap(DELIVERY_STATUS_LIGHT_MAP, status);
}

function getGroupRunStatusLight(status) {
  return resolveLightFromMap(GROUP_RUN_LIGHT_MAP, status);
}

function getMillStatusLight(status) {
  return resolveLightFromMap(MILL_STATUS_LIGHT_MAP, status);
}

function getMillLoadLight(loadKg, capacityKg) {
  if (!capacityKg || capacityKg <= 0) return STATUS_LIGHT.GREY;
  const pct = (loadKg / capacityKg) * 100;
  if (pct >= 95) return STATUS_LIGHT.RED;
  if (pct >= 80) return STATUS_LIGHT.AMBER;
  return STATUS_LIGHT.GREEN;
}

function getUserStatusLight(status) {
  return resolveLightFromMap(USER_STATUS_LIGHT_MAP, status);
}

function getInventoryStockLight(stockKg, minimumKg) {
  if (stockKg <= 0) return STATUS_LIGHT.RED;
  if (typeof minimumKg === 'number' && stockKg <= minimumKg) return STATUS_LIGHT.AMBER;
  return STATUS_LIGHT.GREEN;
}

function getDriverOnlineLight(isOnline) {
  return isOnline === true ? STATUS_LIGHT.GREEN : STATUS_LIGHT.GREY;
}

function getBatteryLight(pct) {
  if (pct == null) return STATUS_LIGHT.GREY;
  if (pct < 15) return STATUS_LIGHT.RED;
  if (pct < 40) return STATUS_LIGHT.AMBER;
  return STATUS_LIGHT.GREEN;
}

function getLightDef(light) {
  return STATUS_LIGHT_DEFS[light] || STATUS_LIGHT_DEFS[STATUS_LIGHT.GREY];
}

function getStatusLightPackage(status, type = 'order') {
  let light;
  switch (type) {
    case 'order': light = getOrderStatusLight(status); break;
    case 'payment': light = getPaymentStatusLight(status); break;
    case 'delivery': light = getDeliveryStatusLight(status); break;
    case 'groupRun': light = getGroupRunStatusLight(status); break;
    case 'mill': light = getMillStatusLight(status); break;
    case 'user': light = getUserStatusLight(status); break;
    default: light = resolveLightFromMap(ORDER_STATUS_LIGHT_MAP, status);
  }
  return { light, def: getLightDef(light) };
}

function annotateOrderWithLight(order) {
  const result = { ...order };
  if (order.status != null) {
    const { light, def } = getStatusLightPackage(order.status, 'order');
    result.statusLight = light;
    result.statusLightDef = def;
  }
  if (order.paymentStatus != null) {
    const { light, def } = getStatusLightPackage(order.paymentStatus, 'payment');
    result.paymentLight = light;
    result.paymentLightDef = def;
  }
  return result;
}

function annotateMillWithLight(mill) {
  const result = { ...mill };
  const millStatus = mill.isOpen === true ? 'Active' : (mill.isOpen === false ? 'Maintenance' : (mill.status || 'Active'));
  const { light, def } = getStatusLightPackage(millStatus, 'mill');
  result.statusLight = light;
  result.statusLightDef = def;
  const loadLight = getMillLoadLight(mill.currentLoadKg || mill.output || 0, mill.capacityKgPerDay || mill.capacity || 500);
  result.loadLight = loadLight;
  result.loadLightDef = getLightDef(loadLight);
  return result;
}

function annotateInventoryItemWithLight(item) {
  const result = { ...item };
  const stockKg = item.stockKg != null ? item.stockKg : (item.inStock ? 100 : 0);
  const minimumKg = item.minimumStockKg != null ? item.minimumStockKg : item.minimumKg;
  const light = getInventoryStockLight(stockKg, minimumKg);
  result.stockLight = light;
  result.stockLightDef = getLightDef(light);
  return result;
}

function annotateUserWithLight(user) {
  const result = { ...user };
  const userStatus = user.status || (user.isOnline === true ? 'Active' : (user.isOnline === false ? 'Inactive' : 'Active'));
  const { light, def } = getStatusLightPackage(userStatus, 'user');
  result.statusLight = light;
  result.statusLightDef = def;
  if (user.isOnline != null || user.role === 'DELIVERY') {
    const onlineLight = getDriverOnlineLight(user.isOnline);
    result.onlineLight = onlineLight;
    result.onlineLightDef = getLightDef(onlineLight);
  }
  if (user.batteryLevelPct != null) {
    const battLight = getBatteryLight(user.batteryLevelPct);
    result.batteryLight = battLight;
    result.batteryLightDef = getLightDef(battLight);
  }
  return result;
}

module.exports = {
  ORDER_STATUS_LIGHT_MAP,
  PAYMENT_STATUS_LIGHT_MAP,
  DELIVERY_STATUS_LIGHT_MAP,
  GROUP_RUN_LIGHT_MAP,
  MILL_STATUS_LIGHT_MAP,
  USER_STATUS_LIGHT_MAP,
  getOrderStatusLight,
  getPaymentStatusLight,
  getDeliveryStatusLight,
  getGroupRunStatusLight,
  getMillStatusLight,
  getMillLoadLight,
  getUserStatusLight,
  getInventoryStockLight,
  getDriverOnlineLight,
  getBatteryLight,
  getLightDef,
  getStatusLightPackage,
  annotateOrderWithLight,
  annotateMillWithLight,
  annotateInventoryItemWithLight,
  annotateUserWithLight
};

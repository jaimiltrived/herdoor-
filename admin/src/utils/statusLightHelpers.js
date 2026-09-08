export const STATUS_LIGHT = {
  GREEN: 'GREEN',
  AMBER: 'AMBER',
  RED: 'RED',
  BLUE: 'BLUE',
  GREY: 'GREY'
};

export const STATUS_LIGHT_DEFS = {
  [STATUS_LIGHT.GREEN]: {
    color: '#2ECC71',
    bg: '#E8F8F0',
    text: '#1E8449',
    border: '#A9DFBF',
    label: 'Good',
    glow: 'rgba(46, 204, 113, 0.35)',
    pulse: false
  },
  [STATUS_LIGHT.AMBER]: {
    color: '#F39C12',
    bg: '#FFF8E7',
    text: '#B7791F',
    border: '#F6AD55',
    label: 'Attention',
    glow: 'rgba(243, 156, 18, 0.35)',
    pulse: true
  },
  [STATUS_LIGHT.RED]: {
    color: '#E74C3C',
    bg: '#FDEDEC',
    text: '#C0392B',
    border: '#F1948A',
    label: 'Problem',
    glow: 'rgba(231, 76, 60, 0.35)',
    pulse: true
  },
  [STATUS_LIGHT.BLUE]: {
    color: '#3498DB',
    bg: '#EBF5FB',
    text: '#21618C',
    border: '#85C1E9',
    label: 'In Transit',
    glow: 'rgba(52, 152, 219, 0.35)',
    pulse: false
  },
  [STATUS_LIGHT.GREY]: {
    color: '#95A5A6',
    bg: '#F2F3F4',
    text: '#616A6B',
    border: '#D5D8DC',
    label: 'Inactive',
    glow: 'rgba(149, 165, 166, 0.25)',
    pulse: false
  }
};

const ORDER_MAP = {
  PENDING: STATUS_LIGHT.AMBER, PLACED: STATUS_LIGHT.AMBER, NEW: STATUS_LIGHT.AMBER,
  CONFIRMED: STATUS_LIGHT.AMBER, ACCEPTED: STATUS_LIGHT.GREEN, MILLING: STATUS_LIGHT.AMBER,
  PROCESSING: STATUS_LIGHT.AMBER, PACKING: STATUS_LIGHT.AMBER, READY: STATUS_LIGHT.GREEN,
  READY_FOR_PICKUP: STATUS_LIGHT.GREEN, OUT_FOR_DELIVERY: STATUS_LIGHT.BLUE,
  PICKED_UP: STATUS_LIGHT.BLUE, DELIVERED: STATUS_LIGHT.GREEN, COMPLETED: STATUS_LIGHT.GREEN,
  CANCELLED: STATUS_LIGHT.RED, REJECTED: STATUS_LIGHT.RED, PAYMENT_FAILED: STATUS_LIGHT.RED,
  DELIVERY_FAILED: STATUS_LIGHT.RED, RETURNED: STATUS_LIGHT.RED,
  'IN PROGRESS': STATUS_LIGHT.AMBER, 'NEW REQUESTS PENDING': STATUS_LIGHT.RED,
  'BATCH IN PROGRESS': STATUS_LIGHT.AMBER, 'ALL STOPS DELIVERED': STATUS_LIGHT.GREEN
};

const PAYMENT_MAP = {
  PENDING: STATUS_LIGHT.AMBER, PAID: STATUS_LIGHT.GREEN, FAILED: STATUS_LIGHT.RED,
  REFUNDED: STATUS_LIGHT.GREY, CREATED: STATUS_LIGHT.AMBER
};

const DELIVERY_MAP = {
  ASSIGNED: STATUS_LIGHT.AMBER, PICKED_UP_FROM_MILL: STATUS_LIGHT.BLUE,
  OUT_FOR_DELIVERY: STATUS_LIGHT.BLUE, ARRIVED: STATUS_LIGHT.AMBER, DELIVERED: STATUS_LIGHT.GREEN
};

const MILL_MAP = {
  Active: STATUS_LIGHT.GREEN, Maintenance: STATUS_LIGHT.AMBER,
  Inactive: STATUS_LIGHT.GREY, Offline: STATUS_LIGHT.RED
};

const USER_MAP = {
  Active: STATUS_LIGHT.GREEN, VIP: STATUS_LIGHT.GREEN, Inactive: STATUS_LIGHT.GREY,
  Suspended: STATUS_LIGHT.RED, Pending: STATUS_LIGHT.AMBER,
  APPROVED: STATUS_LIGHT.GREEN, PENDING: STATUS_LIGHT.AMBER, REJECTED: STATUS_LIGHT.RED,
  'Pending Review': STATUS_LIGHT.AMBER, 'Approved & Active': STATUS_LIGHT.GREEN,
  Rejected: STATUS_LIGHT.RED
};

function resolveFromMap(map, status, fallback = STATUS_LIGHT.GREY) {
  if (!status) return fallback;
  const norm = String(status).toUpperCase().trim();
  if (map[norm]) return map[norm];
  const orig = String(status).trim();
  if (map[orig]) return map[orig];
  for (const k of Object.keys(map)) {
    if (k.toUpperCase() === norm) return map[k];
  }
  return fallback;
}

export function getOrderLight(s) { return resolveFromMap(ORDER_MAP, s); }
export function getPaymentLight(s) { return resolveFromMap(PAYMENT_MAP, s); }
export function getDeliveryLight(s) { return resolveFromMap(DELIVERY_MAP, s); }
export function getMillLight(s) { return resolveFromMap(MILL_MAP, s); }
export function getUserLight(s) { return resolveFromMap(USER_MAP, s); }

export function getMillLoadLight(loadKg, capacityKg) {
  if (!capacityKg || capacityKg <= 0) return STATUS_LIGHT.GREY;
  const pct = (loadKg / capacityKg) * 100;
  if (pct >= 95) return STATUS_LIGHT.RED;
  if (pct >= 80) return STATUS_LIGHT.AMBER;
  return STATUS_LIGHT.GREEN;
}

export function getInventoryLight(stockKg, minimumKg) {
  if (stockKg <= 0) return STATUS_LIGHT.RED;
  if (typeof minimumKg === 'number' && stockKg <= minimumKg) return STATUS_LIGHT.AMBER;
  return STATUS_LIGHT.GREEN;
}

export function getBatteryLight(pct) {
  if (pct == null) return STATUS_LIGHT.GREY;
  if (pct < 15) return STATUS_LIGHT.RED;
  if (pct < 40) return STATUS_LIGHT.AMBER;
  return STATUS_LIGHT.GREEN;
}

export function resolveStatusLight(status, type = 'order') {
  switch (type) {
    case 'order': return getOrderLight(status);
    case 'payment': return getPaymentLight(status);
    case 'delivery': return getDeliveryLight(status);
    case 'mill': return getMillLight(status);
    case 'user': return getUserLight(status);
    default: return getOrderLight(status);
  }
}

export function getLightDef(light) {
  return STATUS_LIGHT_DEFS[light] || STATUS_LIGHT_DEFS[STATUS_LIGHT.GREY];
}

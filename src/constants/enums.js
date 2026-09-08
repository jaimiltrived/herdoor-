const ROLES = {
  CUSTOMER: 'CUSTOMER',
  SHOPKEEPER: 'SHOPKEEPER',
  DELIVERY: 'DELIVERY',
  ADMIN: 'ADMIN'
};

const ORDER_STATUS = {
  // Master Standard Status Flow
  PENDING: 'PENDING',
  CONFIRMED: 'CONFIRMED',
  MILLING: 'MILLING',
  READY_FOR_PICKUP: 'READY_FOR_PICKUP',
  OUT_FOR_DELIVERY: 'OUT_FOR_DELIVERY',
  DELIVERED: 'DELIVERED',

  // Failure / Terminal States
  CANCELLED: 'CANCELLED',
  PAYMENT_FAILED: 'PAYMENT_FAILED',
  DELIVERY_FAILED: 'DELIVERY_FAILED',
  RETURNED: 'RETURNED',

  // Compatibility names for existing tests and models
  PLACED: 'PLACED',
  ACCEPTED: 'ACCEPTED',
  ASSIGNED: 'ASSIGNED',
  PROCESSING: 'PROCESSING',
  PACKING: 'PACKING',
  READY: 'READY',
  PICKED_UP: 'PICKED_UP',
  COMPLETED: 'COMPLETED',
  REJECTED: 'REJECTED'
};

const GROUP_RUN_STATUS = {
  CREATED: 'CREATED',
  ASSIGNED: 'ASSIGNED',
  ACCEPTED: 'ACCEPTED',
  AT_MILL: 'AT_MILL',
  IN_TRANSIT: 'IN_TRANSIT',
  COMPLETED: 'COMPLETED',
  CANCELLED: 'CANCELLED'
};

const GRAIN_SOURCES = {
  CUSTOMER: 'CUSTOMER', // Customer provides their own grain
  MILL: 'MILL',         // Mill provides grain
  VENDOR: 'VENDOR'      // Vendor supplied
};

const SERVICE_TYPES = {
  GRINDING: 'GRINDING',
  PACKING: 'PACKING',
  DELIVERY: 'DELIVERY',
  CLEANING: 'CLEANING'
};

const FULFILLMENT_TYPES = {
  DELIVERY: 'DELIVERY',
  PICKUP: 'PICKUP'
};

const DELIVERY_STATUS = {
  ASSIGNED: 'ASSIGNED',
  PICKED_UP_FROM_MILL: 'PICKED_UP_FROM_MILL',
  OUT_FOR_DELIVERY: 'OUT_FOR_DELIVERY',
  ARRIVED: 'ARRIVED',
  DELIVERED: 'DELIVERED'
};

const PAYMENT_STATUS = {
  PENDING: 'PENDING',
  PAID: 'PAID',
  FAILED: 'FAILED',
  REFUNDED: 'REFUNDED'
};

const STATUS_LIGHT = {
  GREEN: 'GREEN',
  AMBER: 'AMBER',
  RED: 'RED',
  BLUE: 'BLUE',
  GREY: 'GREY'
};

const STATUS_LIGHT_DEFS = {
  [STATUS_LIGHT.GREEN]: {
    color: '#2ECC71',
    bg: '#E8F8F0',
    text: '#1E8449',
    border: '#A9DFBF',
    label: 'Good',
    pulse: false
  },
  [STATUS_LIGHT.AMBER]: {
    color: '#F39C12',
    bg: '#FFF8E7',
    text: '#B7791F',
    border: '#F6AD55',
    label: 'Attention',
    pulse: true
  },
  [STATUS_LIGHT.RED]: {
    color: '#E74C3C',
    bg: '#FDEDEC',
    text: '#C0392B',
    border: '#F1948A',
    label: 'Problem',
    pulse: true
  },
  [STATUS_LIGHT.BLUE]: {
    color: '#3498DB',
    bg: '#EBF5FB',
    text: '#21618C',
    border: '#85C1E9',
    label: 'In Transit',
    pulse: false
  },
  [STATUS_LIGHT.GREY]: {
    color: '#95A5A6',
    bg: '#F2F3F4',
    text: '#616A6B',
    border: '#D5D8DC',
    label: 'Inactive',
    pulse: false
  }
};

module.exports = {
  ROLES,
  ORDER_STATUS,
  GROUP_RUN_STATUS,
  GRAIN_SOURCES,
  SERVICE_TYPES,
  FULFILLMENT_TYPES,
  DELIVERY_STATUS,
  PAYMENT_STATUS,
  STATUS_LIGHT,
  STATUS_LIGHT_DEFS
};

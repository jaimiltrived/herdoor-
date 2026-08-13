const bcrypt = require('bcryptjs');
const { ROLES, ORDER_STATUS, GRAIN_SOURCES, SERVICE_TYPES, FULFILLMENT_TYPES } = require('../constants/enums');

// Initial hashed password for test users
const hashedPassword = bcrypt.hashSync('Password123!', 8);

const store = {
  users: [
    {
      id: 1,
      name: 'Ramesh Patel',
      email: 'ramesh@example.com',
      phone: '+919876543210',
      password: hashedPassword,
      role: ROLES.CUSTOMER,
      profileImage: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb',
      createdAt: '2026-01-10T10:00:00Z'
    },
    {
      id: 2,
      name: 'Suresh Mill Owner',
      email: 'shop@shreeganesh.com',
      phone: '+919876543211',
      password: hashedPassword,
      role: ROLES.SHOPKEEPER,
      millId: 101,
      profileImage: null,
      createdAt: '2026-01-01T10:00:00Z'
    },
    {
      id: 3,
      name: 'Vikram Delivery Agent',
      email: 'delivery@herdoor.com',
      phone: '+919876543212',
      password: hashedPassword,
      role: ROLES.DELIVERY,
      vehicleNumber: 'GJ-01-AB-1234',
      profileImage: null,
      createdAt: '2026-01-15T10:00:00Z'
    }
  ],

  addresses: [
    {
      id: 25,
      userId: 1,
      addressLine1: 'Flat 402, Shivalik Towers',
      addressLine2: 'Satellite Road',
      city: 'Ahmedabad',
      state: 'Gujarat',
      pincode: '380015',
      latitude: 23.0250,
      longitude: 72.5700,
      isDefault: true
    }
  ],

  mills: [
    {
      id: 101,
      name: 'Shree Ganesh Flour Mill',
      ownerUserId: 2,
      phone: '+919876543211',
      address: '12 Market Yard, Ellisbridge, Ahmedabad',
      latitude: 23.0225,
      longitude: 72.5714,
      rating: 4.6,
      totalRatings: 128,
      isOpen: true,
      estimatedTime: '30-45 min',
      services: ['Flour Grinding', 'Packing', 'Home Delivery', 'Cleaning'],
      workingHours: '08:00 AM - 08:00 PM'
    },
    {
      id: 102,
      name: 'Navrang Quality Atta Mill',
      ownerUserId: 99,
      phone: '+919876543299',
      address: '45 Swastik Cross Road, Navrangpura, Ahmedabad',
      latitude: 23.0380,
      longitude: 72.5620,
      rating: 4.8,
      totalRatings: 94,
      isOpen: true,
      estimatedTime: '20-30 min',
      services: ['Flour Grinding', 'Home Delivery'],
      workingHours: '09:00 AM - 07:30 PM'
    }
  ],

  grainSources: [
    { id: 1, code: GRAIN_SOURCES.CUSTOMER, name: "Customer's own grain", description: "Bring/pickup customer's own raw grain for milling" },
    { id: 2, code: GRAIN_SOURCES.MILL, name: "Mill-provided grain", description: "Fresh grain supplied directly by the mill" },
    { id: 3, code: GRAIN_SOURCES.VENDOR, name: "Vendor grain", description: "Premium vendor sourced grain" }
  ],

  grainTypes: [
    { id: 1, name: 'Wheat (Gehun)', category: 'GRAIN', pricePerKg: 35, grindingFeePerKg: 5 },
    { id: 2, name: 'Rice (Chawal)', category: 'GRAIN', pricePerKg: 40, grindingFeePerKg: 6 },
    { id: 3, name: 'Bajra (Pearl Millet)', category: 'GRAIN', pricePerKg: 30, grindingFeePerKg: 5 },
    { id: 4, name: 'Jowar (Sorghum)', category: 'GRAIN', pricePerKg: 38, grindingFeePerKg: 5 },
    { id: 5, name: 'Maize (Makai)', category: 'GRAIN', pricePerKg: 28, grindingFeePerKg: 4 },
    { id: 6, name: 'Multigrain Mix', category: 'GRAIN', pricePerKg: 60, grindingFeePerKg: 8 },
    { id: 7, name: 'Ragi (Finger Millet)', category: 'GRAIN', pricePerKg: 55, grindingFeePerKg: 7 }
  ],

  orders: [
    {
      id: 501,
      orderNumber: 'ORD-2026-1001',
      userId: 1,
      millId: 101,
      grainSource: GRAIN_SOURCES.CUSTOMER,
      grainTypeId: 1,
      grainTypeName: 'Wheat (Gehun)',
      quantityKg: 10,
      serviceType: SERVICE_TYPES.GRINDING,
      fulfillmentType: FULFILLMENT_TYPES.DELIVERY,
      addressId: 25,
      paymentMethod: 'UPI',
      paymentStatus: 'PAID',
      status: ORDER_STATUS.PROCESSING,
      estimatedMinutes: 45,
      estimatedCompletionTime: '18:30',
      totalAmount: 90.0,
      timeline: [
        { status: ORDER_STATUS.PLACED, timestamp: '2026-08-12T10:00:00Z', note: 'Order placed by customer' },
        { status: ORDER_STATUS.ACCEPTED, timestamp: '2026-08-12T10:05:00Z', note: 'Accepted by shopkeeper' },
        { status: ORDER_STATUS.PROCESSING, timestamp: '2026-08-12T10:15:00Z', note: 'Grinding started' }
      ],
      createdAt: '2026-08-12T10:00:00Z'
    }
  ],

  payments: [
    {
      id: 'PAY-1001',
      orderId: 501,
      amount: 90.0,
      paymentMethod: 'UPI',
      status: 'SUCCESS',
      transactionId: 'TXN_9988776655',
      createdAt: '2026-08-12T10:00:00Z'
    }
  ],

  deliveries: [
    {
      id: 801,
      orderId: 501,
      deliveryPersonId: 3,
      deliveryPersonName: 'Vikram Delivery Agent',
      deliveryPersonPhone: '+919876543212',
      status: 'ASSIGNED',
      pickupAddress: 'Shree Ganesh Flour Mill, Market Yard',
      deliveryAddress: 'Flat 402, Shivalik Towers, Satellite Road',
      updatedAt: '2026-08-12T10:05:00Z'
    }
  ],

  inventory: [
    {
      id: 1,
      millId: 101,
      productType: 'FLOUR',
      name: 'Wheat Flour (Fresh Atta)',
      stockKg: 150,
      minimumStockKg: 30,
      pricePerKg: 45,
      updatedAt: '2026-08-12T09:00:00Z'
    },
    {
      id: 2,
      millId: 101,
      productType: 'GRAIN',
      name: 'Raw Premium Sharbati Wheat',
      stockKg: 400,
      minimumStockKg: 100,
      pricePerKg: 36,
      updatedAt: '2026-08-12T09:00:00Z'
    }
  ],

  reviews: [
    {
      id: 1,
      orderId: 500,
      userId: 1,
      userName: 'Ramesh Patel',
      millId: 101,
      rating: 5,
      review: 'Excellent grinding quality and fast home delivery service.',
      createdAt: '2026-08-10T12:00:00Z'
    }
  ],

  notifications: [
    {
      id: 1,
      userId: 1,
      title: 'Order Accepted',
      message: 'Shree Ganesh Flour Mill accepted your order #ORD-2026-1001.',
      read: false,
      createdAt: '2026-08-12T10:05:00Z'
    }
  ],

  devices: [
    {
      id: 1,
      userId: 1,
      fcmToken: 'token_sample_abc123',
      deviceType: 'ANDROID'
    }
  ]
};

module.exports = store;

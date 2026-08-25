const bcrypt = require('bcryptjs');
const { ROLES, ORDER_STATUS, GRAIN_SOURCES, SERVICE_TYPES, FULFILLMENT_TYPES, DELIVERY_STATUS } = require('../constants/enums');

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
      vehicleType: 'Electric Scooter',
      isOnline: true,
      rating: 4.9,
      totalTrips: 184,
      profileImage: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d',
      createdAt: '2026-01-15T10:00:00Z'
    },
    {
      id: 4,
      name: 'Super Admin',
      email: 'admin@herdoor.com',
      phone: '+919876543200',
      password: hashedPassword,
      role: ROLES.ADMIN,
      profileImage: null,
      createdAt: '2026-01-01T00:00:00Z'
    },
    {
      id: 5,
      name: 'Rajesh Kumar',
      email: 'rajesh.rider@herdoor.com',
      phone: '+919876543215',
      password: hashedPassword,
      role: ROLES.DELIVERY,
      vehicleNumber: 'GJ-01-EB-4821',
      vehicleType: 'Electric Bike',
      isOnline: true,
      rating: 4.85,
      totalTrips: 96,
      profileImage: null,
      createdAt: '2026-02-01T10:00:00Z'
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
    },
    {
      id: 26,
      userId: 1,
      addressLine1: 'Office 301, Pinnacle Business Park',
      addressLine2: 'Prahlad Nagar',
      city: 'Ahmedabad',
      state: 'Gujarat',
      pincode: '380015',
      latitude: 23.0120,
      longitude: 72.5080,
      isDefault: false
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
      rating: 4.8,
      totalRatings: 128,
      isOpen: true,
      estimatedTime: '30-45 min',
      capacityKgPerDay: 600,
      currentLoadKg: 420,
      services: ['Flour Grinding', 'Packing', 'Home Delivery', 'Cleaning'],
      workingHours: '08:00 AM - 08:00 PM',
      specialty: 'Fresh Stone Ground Flour'
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
      capacityKgPerDay: 500,
      currentLoadKg: 310,
      services: ['Flour Grinding', 'Home Delivery'],
      workingHours: '09:00 AM - 07:30 PM',
      specialty: 'Organic Whole Wheat & Multigrain'
    },
    {
      id: 103,
      name: 'Mahadev Traditional Chakki',
      ownerUserId: 100,
      phone: '+919876543288',
      address: 'Shop 8, Vastrapur Lake Complex, Ahmedabad',
      latitude: 23.0350,
      longitude: 72.5280,
      rating: 4.7,
      totalRatings: 76,
      isOpen: true,
      estimatedTime: '25-40 min',
      capacityKgPerDay: 450,
      currentLoadKg: 290,
      services: ['Flour Grinding', 'Packing', 'Home Delivery'],
      workingHours: '08:30 AM - 08:30 PM',
      specialty: 'Bajra & Jowar Specialized Grinding'
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
      customerName: 'Ramesh Patel',
      customerPhone: '+919876543210',
      millId: 101,
      grainSource: GRAIN_SOURCES.CUSTOMER,
      grainTypeId: 1,
      grainTypeName: 'Wheat (Gehun)',
      quantityKg: 10,
      serviceType: SERVICE_TYPES.GRINDING,
      fulfillmentType: FULFILLMENT_TYPES.DELIVERY,
      addressId: 25,
      pickupPin: '4821',
      deliveryOtp: '7391',
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
    },
    {
      id: 502,
      orderNumber: 'ORD-2026-1002',
      userId: 1,
      customerName: 'Elena Rodriguez',
      customerPhone: '+919876543219',
      millId: 101,
      grainSource: GRAIN_SOURCES.CUSTOMER,
      grainTypeId: 6,
      grainTypeName: 'Multigrain Mix',
      quantityKg: 5,
      serviceType: SERVICE_TYPES.GRINDING,
      fulfillmentType: FULFILLMENT_TYPES.DELIVERY,
      addressId: 25,
      pickupPin: '1942',
      deliveryOtp: '6543',
      paymentMethod: 'UPI',
      paymentStatus: 'PAID',
      status: ORDER_STATUS.PLACED,
      estimatedMinutes: 30,
      estimatedCompletionTime: null,
      totalAmount: 175.0,
      timeline: [
        { status: ORDER_STATUS.PLACED, timestamp: '2026-08-12T11:00:00Z', note: 'Order placed by customer' }
      ],
      createdAt: '2026-08-12T11:00:00Z'
    },
    {
      id: 503,
      orderNumber: 'ORD-2026-1003',
      userId: 1,
      customerName: 'Marcus Chen',
      customerPhone: '+919876543220',
      millId: 101,
      grainSource: GRAIN_SOURCES.MILL,
      grainTypeId: 4,
      grainTypeName: 'Jowar (Sorghum)',
      quantityKg: 10,
      serviceType: SERVICE_TYPES.GRINDING,
      fulfillmentType: FULFILLMENT_TYPES.DELIVERY,
      addressId: 25,
      pickupPin: '8210',
      deliveryOtp: '9120',
      paymentMethod: 'UPI',
      paymentStatus: 'PAID',
      status: ORDER_STATUS.DELIVERED,
      estimatedMinutes: 40,
      estimatedCompletionTime: '12:40',
      totalAmount: 380.0,
      timeline: [
        { status: ORDER_STATUS.PLACED, timestamp: '2026-08-11T09:00:00Z', note: 'Order placed' },
        { status: ORDER_STATUS.COMPLETED, timestamp: '2026-08-11T12:40:00Z', note: 'Order delivered' }
      ],
      createdAt: '2026-08-11T09:00:00Z'
    },
    {
      id: 504,
      orderNumber: 'ORD-2026-1004',
      userId: 1,
      customerName: 'Priya Sharma',
      customerPhone: '+919876543222',
      millId: 101,
      grainSource: GRAIN_SOURCES.MILL,
      grainTypeId: 1,
      grainTypeName: 'Wheat (Gehun)',
      quantityKg: 5,
      serviceType: SERVICE_TYPES.GRINDING,
      fulfillmentType: FULFILLMENT_TYPES.PICKUP,
      addressId: null,
      pickupPin: '3321',
      deliveryOtp: null,
      paymentMethod: 'CASH',
      paymentStatus: 'PENDING',
      status: ORDER_STATUS.READY_FOR_PICKUP,
      estimatedMinutes: 25,
      estimatedCompletionTime: '15:00',
      totalAmount: 200.0,
      timeline: [
        { status: ORDER_STATUS.PLACED, timestamp: '2026-08-12T13:00:00Z', note: 'Self pickup order placed' },
        { status: ORDER_STATUS.ACCEPTED, timestamp: '2026-08-12T13:05:00Z', note: 'Accepted' },
        { status: ORDER_STATUS.READY_FOR_PICKUP, timestamp: '2026-08-12T13:30:00Z', note: 'Ready at counter' }
      ],
      createdAt: '2026-08-12T13:00:00Z'
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
      status: DELIVERY_STATUS.ASSIGNED,
      pickupAddress: 'Shree Ganesh Flour Mill, 12 Market Yard, Ellisbridge',
      deliveryAddress: 'Flat 402, Shivalik Towers, Satellite Road, Ahmedabad',
      currentLatitude: 23.0230,
      currentLongitude: 72.5705,
      pickupPin: '4821',
      deliveryOtp: '7391',
      deliveryFee: 40.0,
      estimatedMinutes: 18,
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
    },
    {
      id: 3,
      millId: 101,
      productType: 'FLOUR',
      name: 'Multigrain Dietary Flour',
      stockKg: 65,
      minimumStockKg: 20,
      pricePerKg: 68,
      updatedAt: '2026-08-12T09:00:00Z'
    },
    {
      id: 4,
      millId: 101,
      productType: 'GRAIN',
      name: 'Dark Rye Grain',
      stockKg: 12,
      minimumStockKg: 25,
      pricePerKg: 48,
      updatedAt: '2026-08-12T09:00:00Z'
    }
  ],

  reviews: [
    {
      id: 1,
      orderId: 503,
      userId: 1,
      userName: 'Ramesh Patel',
      millId: 101,
      rating: 5,
      review: 'Excellent grinding quality, perfect fineness, and super fast home delivery service.',
      createdAt: '2026-08-11T13:00:00Z'
    }
  ],

  notifications: [
    {
      id: 1,
      userId: 2,
      title: '🚨 New Order Received #ORD-2026-1002',
      message: 'Elena Rodriguez placed a new order for 5kg Multigrain Mix (₹175.00).',
      read: false,
      createdAt: '2026-08-12T11:00:00Z'
    },
    {
      id: 2,
      userId: 2,
      title: '🛵 Driver Arrived for Pickup',
      message: 'Rajesh Kumar (Electric Bike #EB-4821) arrived at store for order #ORD-2026-1001.',
      read: false,
      createdAt: '2026-08-12T10:30:00Z'
    },
    {
      id: 3,
      userId: 2,
      title: '⚠️ Low Stock Alert: Dark Rye Blend',
      message: 'Stock has fallen below threshold (12kg remaining). Restock soon.',
      read: false,
      createdAt: '2026-08-12T09:15:00Z'
    },
    {
      id: 4,
      userId: 2,
      title: '🛡️ Food Safety Audit Status',
      message: 'Daily chakki stone sanitization and grain moisture test verified (Score 99%).',
      read: true,
      createdAt: '2026-08-12T08:00:00Z'
    }
  ],

  wholesalers: [
    {
      id: 1,
      name: 'Gujarat Agro Grain Depot',
      contactPerson: 'Harish Mehta',
      phone: '+919876543301',
      city: 'Ahmedabad',
      grainsSupplied: ['Wheat', 'Bajra', 'Jowar'],
      rating: 4.8,
      stockAvailableTons: 145.5,
      status: 'ACTIVE'
    },
    {
      id: 2,
      name: 'Saurashtra Organic Pulses & Grains',
      contactPerson: 'Bhavesh Dave',
      phone: '+919876543302',
      city: 'Rajkot',
      grainsSupplied: ['Ragi', 'Makai', 'Organic Wheat'],
      rating: 4.9,
      stockAvailableTons: 88.0,
      status: 'ACTIVE'
    }
  ],

  grainTypes: [
    { id: 1, name: 'Wheat (Gehun)', category: 'GRAIN', pricePerKg: 35.0, grindingFeePerKg: 5.0 },
    { id: 2, name: 'Rice (Chawal)', category: 'GRAIN', pricePerKg: 40.0, grindingFeePerKg: 6.0 },
    { id: 3, name: 'Bajra (Pearl Millet)', category: 'GRAIN', pricePerKg: 30.0, grindingFeePerKg: 5.0 },
    { id: 4, name: 'Jowar (Sorghum)', category: 'GRAIN', pricePerKg: 38.0, grindingFeePerKg: 5.0 },
    { id: 5, name: 'Maize (Makai)', category: 'GRAIN', pricePerKg: 28.0, grindingFeePerKg: 4.0 },
    { id: 6, name: 'Multigrain Mix', category: 'GRAIN', pricePerKg: 60.0, grindingFeePerKg: 8.0 },
    { id: 7, name: 'Ragi (Finger Millet)', category: 'GRAIN', pricePerKg: 55.0, grindingFeePerKg: 7.0 }
  ],

  readymadeProducts: [
    {
      id: 'p1',
      millId: 101,
      name: 'Pre-packed Wheat',
      subtitle: '1kg Pack • Stone ground flour',
      category: 'Flour',
      price: 2.50,
      image: 'assets/images/cat_wheat.jpg',
      imageUrl: 'https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b?auto=format&fit=crop&w=400&q=80',
      stockQuantity: 150
    },
    {
      id: 'p2',
      millId: 101,
      name: 'Masala Mix',
      subtitle: '500g Pack • Premium blend spices',
      category: 'Spices',
      price: 3.00,
      image: 'assets/images/cat_spices.jpg',
      imageUrl: 'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?auto=format&fit=crop&w=400&q=80',
      stockQuantity: 80
    },
    {
      id: 'p3',
      millId: 101,
      name: 'Organic Multigrain Flour',
      subtitle: '1kg Pack • 7 Grain high fiber mix',
      category: 'Flour',
      price: 3.50,
      image: 'assets/images/cat_millet.jpg',
      imageUrl: 'https://images.unsplash.com/photo-1586444248902-2f64eddc13df?auto=format&fit=crop&w=400&q=80',
      stockQuantity: 60
    },
    {
      id: 'p4',
      millId: 101,
      name: 'Pure Besan (Gram Flour)',
      subtitle: '500g Pack • Fine ground chana dal',
      category: 'Flour',
      price: 2.20,
      image: 'assets/images/cat_all.jpg',
      imageUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=400&q=80',
      stockQuantity: 90
    }
  ],

  devices: [
    {
      id: 1,
      userId: 1,
      fcmToken: 'token_sample_customer_123',
      deviceType: 'ANDROID'
    },
    {
      id: 2,
      userId: 2,
      fcmToken: 'token_sample_merchant_456',
      deviceType: 'ANDROID'
    }
  ]
};

module.exports = store;

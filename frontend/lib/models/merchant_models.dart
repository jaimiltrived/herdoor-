import 'package:flutter/material.dart';

enum UserRole {
  customer,
  merchant,
  delivery,
}

class MerchantDashboardMetrics {
  int pendingOrders;
  int activeOrders;
  int completedOrders;
  int readyForDispatchOrders;
  double totalRevenue;

  MerchantDashboardMetrics({
    required this.pendingOrders,
    required this.activeOrders,
    required this.completedOrders,
    this.readyForDispatchOrders = 0,
    required this.totalRevenue,
  });

  factory MerchantDashboardMetrics.fromJson(Map<String, dynamic> json) {
    return MerchantDashboardMetrics(
      pendingOrders: json['pendingOrders'] ?? 0,
      activeOrders: json['activeOrders'] ?? 0,
      completedOrders: json['completedOrders'] ?? 0,
      readyForDispatchOrders: json['readyForDispatchOrders'] ?? json['readyOrdersCount'] ?? 0,
      totalRevenue: (json['totalRevenue'] ?? 0.0).toDouble(),
    );
  }
}

class AppNotification {
  final int id;
  final String title;
  final String message;
  bool read;
  final String createdAt;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.read,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '1') ?? 1,
      title: json['title'] ?? 'Notification',
      message: json['message'] ?? '',
      read: json['read'] ?? false,
      createdAt: json['createdAt'] != null && json['createdAt'].toString().length >= 16
          ? json['createdAt'].toString().substring(11, 16)
          : 'Recently',
    );
  }
}

class MerchantProcessStep {
  final String title;
  final String timeText;
  final String detailsNote;
  final IconData icon;
  final bool isCompleted;
  final bool isCurrent;
  final bool isHighlighted;

  MerchantProcessStep({
    required this.title,
    required this.timeText,
    this.detailsNote = '',
    required this.icon,
    this.isCompleted = false,
    this.isCurrent = false,
    this.isHighlighted = false,
  });

  factory MerchantProcessStep.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status']?.toString().toUpperCase() ?? '';
    final noteStr = json['note']?.toString() ?? '';
    final timestampStr = json['timestamp'] != null
        ? json['timestamp'].toString().length >= 16
            ? json['timestamp'].toString().substring(11, 16)
            : json['timestamp'].toString()
        : '';

    IconData stepIcon = Icons.check_circle_rounded;
    if (statusStr.contains('PLACED') || statusStr.contains('ORDER')) {
      stepIcon = Icons.receipt_long_rounded;
    } else if (statusStr.contains('ACCEPT')) {
      stepIcon = Icons.verified_rounded;
    } else if (statusStr.contains('PROCESS') || statusStr.contains('GRIND')) {
      stepIcon = Icons.grass_rounded;
    } else if (statusStr.contains('PACK')) {
      stepIcon = Icons.inventory_2_rounded;
    } else if (statusStr.contains('READY') || statusStr.contains('DELIVER')) {
      stepIcon = Icons.local_shipping_rounded;
    }

    return MerchantProcessStep(
      title: statusStr.replaceAll('_', ' '),
      timeText: timestampStr,
      detailsNote: noteStr,
      icon: stepIcon,
      isCompleted: true,
      isCurrent: false,
      isHighlighted: false,
    );
  }
}

class MerchantOrder {
  final int? numericId;
  final String orderId;
  final String customerName;
  final String itemsSummary;
  final String grainType;
  final String quantityText;
  final String timeAgo;
  String statusTag; // 'NEW', 'IN PROGRESS', 'PACKING', 'READY FOR PICKUP', 'OUT FOR DELIVERY', 'COMPLETED'
  Color statusColor;
  final String? binLocation;
  String? estimatedCompletionTime;
  final String? deliveryDriverName;
  final String? deliveryDriverPhone;
  final String? deliveryDriverVehicle;
  final List<MerchantProcessStep> timelineSteps;
  final double totalPrice;
  final String millName;

  MerchantOrder({
    this.numericId,
    required this.orderId,
    required this.customerName,
    required this.itemsSummary,
    required this.grainType,
    required this.quantityText,
    required this.timeAgo,
    required this.statusTag,
    required this.statusColor,
    this.binLocation,
    this.estimatedCompletionTime,
    this.deliveryDriverName,
    this.deliveryDriverPhone,
    this.deliveryDriverVehicle,
    required this.timelineSteps,
    this.totalPrice = 90.0,
    this.millName = 'Artisan Mill Co.',
  });

  factory MerchantOrder.fromJson(Map<String, dynamic> json) {
    final int? rawId = json['id'] is int
        ? json['id']
        : (json['id'] != null ? int.tryParse(json['id'].toString()) : null);

    final String displayOrderId = json['orderNumber'] ?? (rawId != null ? '#HD-$rawId' : '#HD-1001');
    final String rawStatus = json['status']?.toString().toUpperCase() ?? 'NEW';

    String mappedTag = 'NEW';
    Color mappedColor = const Color(0xFFFF8A80);

    if (rawStatus == 'PLACED') {
      mappedTag = 'NEW';
      mappedColor = const Color(0xFF81C784);
    } else if (rawStatus == 'ACCEPTED' || rawStatus == 'PROCESSING') {
      mappedTag = 'IN PROGRESS';
      mappedColor = const Color(0xFFCBA034);
    } else if (rawStatus == 'PACKING') {
      mappedTag = 'PACKING';
      mappedColor = const Color(0xFFCBA034);
    } else if (rawStatus == 'READY' || rawStatus == 'READY_FOR_PICKUP') {
      mappedTag = 'READY FOR PICKUP';
      mappedColor = const Color(0xFFCBA034);
    } else if (rawStatus == 'OUT_FOR_DELIVERY') {
      mappedTag = 'OUT FOR DELIVERY';
      mappedColor = const Color(0xFF3498DB);
    } else if (rawStatus == 'COMPLETED' || rawStatus == 'DELIVERED' || rawStatus == 'PICKED_UP') {
      mappedTag = 'COMPLETED';
      mappedColor = const Color(0xFF2ECC71);
    } else {
      mappedTag = rawStatus;
    }

    final String custName = json['customerName'] ?? json['userName'] ?? 'Customer ${rawId ?? ""}';
    final String grainName = json['grainTypeName'] ?? 'Wheat (Gehun)';
    final String qty = '${json['quantityKg'] ?? 10} kg';
    final String items = '${json['quantityKg'] ?? 10}kg $grainName';
    final String created = json['createdAt'] != null && json['createdAt'].toString().length >= 16
        ? 'Ordered at ${json['createdAt'].toString().substring(11, 16)}'
        : 'Recently';

    final double price = (json['totalAmount'] as num?)?.toDouble() ?? 90.0;
    final String resolvedMill = json['millName'] ?? 'Artisan Mill Co.';

    final String? estTime = json['estimatedCompletionTime'] ??
        (json['estimatedMinutes'] != null ? '${json['estimatedMinutes']} Mins' : null);

    List<MerchantProcessStep> steps = [];
    if (json['timeline'] is List) {
      steps = (json['timeline'] as List)
          .map((item) => MerchantProcessStep.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return MerchantOrder(
      numericId: rawId,
      orderId: displayOrderId,
      customerName: custName,
      itemsSummary: items,
      grainType: grainName,
      quantityText: qty,
      timeAgo: created,
      statusTag: mappedTag,
      statusColor: mappedColor,
      binLocation: json['binLocation'] ?? 'Bin A-4',
      estimatedCompletionTime: estTime,
      deliveryDriverName: json['deliveryDriverName'],
      deliveryDriverPhone: json['deliveryDriverPhone'],
      deliveryDriverVehicle: json['deliveryDriverVehicle'],
      timelineSteps: steps,
      totalPrice: price,
      millName: resolvedMill,
    );
  }
}

class MerchantInventoryItem {
  final String id;
  final int? numericId;
  final String name;
  final String description;
  final String grind;
  final String weightOptions;
  final double price;
  bool inStock;
  final String imageUrl;
  final double stockKg;
  final double minimumStockKg;
  final String productType;

  MerchantInventoryItem({
    required this.id,
    this.numericId,
    required this.name,
    required this.description,
    required this.grind,
    required this.weightOptions,
    required this.price,
    required this.inStock,
    required this.imageUrl,
    this.stockKg = 100.0,
    this.minimumStockKg = 20.0,
    this.productType = 'FLOUR',
  });

  factory MerchantInventoryItem.fromJson(Map<String, dynamic> json) {
    final int? numId = json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '');
    final double stock = (json['stockKg'] ?? 100).toDouble();
    final double minStock = (json['minimumStockKg'] ?? 20).toDouble();
    final bool available = stock > minStock;
    final double priceVal = (json['pricePerKg'] ?? json['price'] ?? 45.0).toDouble();
    final String typeVal = json['productType'] ?? 'FLOUR';

    return MerchantInventoryItem(
      id: numId?.toString() ?? 'inv-1',
      numericId: numId,
      name: json['name'] ?? 'Classic All-Purpose Flour',
      description: json['description'] ?? 'Fresh ground high-quality flour directly from mill.',
      grind: typeVal == 'GRAIN' ? 'Raw Grain' : 'Fine',
      weightOptions: '$stock kg stock',
      price: priceVal,
      inStock: available,
      imageUrl: json['imageUrl'] ??
          'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=600&q=80',
      stockKg: stock,
      minimumStockKg: minStock,
      productType: typeVal,
    );
  }
}

class MerchantMockData {
  static final MerchantOrder sampleOrderHD8829 = MerchantOrder(
    numericId: 501,
    orderId: '#HD-8829',
    customerName: 'Mrs. Eleanor Rigby',
    itemsSummary: '10kg Whole Wheat Flour',
    grainType: 'Whole Wheat',
    quantityText: '10 kg',
    timeAgo: 'Ready at 11:05 AM',
    statusTag: 'Ready for Pickup',
    statusColor: const Color(0xFFFF8A80),
    binLocation: 'Bin A-4',
    estimatedCompletionTime: '30 Mins',
    deliveryDriverName: 'Rajesh Kumar',
    deliveryDriverPhone: '+91 98765 43210',
    deliveryDriverVehicle: 'Electric Bike #EB-4821',
    timelineSteps: [
      MerchantProcessStep(
        title: 'Order Received',
        timeText: '09:00 AM',
        icon: Icons.check_circle_rounded,
        isCompleted: true,
      ),
      MerchantProcessStep(
        title: 'Security Check Passed',
        timeText: '09:15 AM',
        detailsNote: 'Grain box QR verified. Container integrity confirmed.',
        icon: Icons.shield_rounded,
        isCompleted: true,
      ),
      MerchantProcessStep(
        title: 'Milling Commenced',
        timeText: '09:30 AM',
        detailsNote: '⚙️ Premium Whole Wheat. Fine grind setting.',
        icon: Icons.grass_rounded,
        isCompleted: true,
      ),
      MerchantProcessStep(
        title: 'Milling Complete',
        timeText: '10:45 AM',
        detailsNote: '10kg processed. Quality inspected.',
        icon: Icons.check_circle_rounded,
        isCompleted: true,
      ),
      MerchantProcessStep(
        title: 'Packing & Sealing',
        timeText: '11:00 AM',
        detailsNote: 'Eco-friendly bag sealed and labeled.',
        icon: Icons.inventory_2_rounded,
        isCompleted: true,
      ),
      MerchantProcessStep(
        title: 'Ready for Pickup',
        timeText: '11:05 AM',
        detailsNote: 'Stored in Bin A-4. Delivery partner notified.',
        icon: Icons.local_shipping_rounded,
        isCompleted: true,
        isCurrent: true,
        isHighlighted: true,
      ),
    ],
  );

  static final List<MerchantOrder> activeOrders = [
    MerchantOrder(
      numericId: 1042,
      orderId: '#HD-1042',
      customerName: 'Elena Rodriguez',
      itemsSummary: '2x Whole Wheat Flour (5kg), 1x Rye Mix',
      grainType: 'Organic Whole Wheat',
      quantityText: '5 lbs',
      timeAgo: 'Ordered 10 mins ago',
      statusTag: 'NEW',
      statusColor: const Color(0xFFFF8A80),
      timelineSteps: [],
    ),
    MerchantOrder(
      numericId: 1039,
      orderId: '#HD-1039',
      customerName: 'Marcus Chen',
      itemsSummary: '1x Stoneground Rye (10kg)',
      grainType: 'Stoneground Rye',
      quantityText: '10 lbs',
      timeAgo: 'Ordered 25 mins ago',
      statusTag: 'IN PROGRESS',
      statusColor: const Color(0xFFCBA034),
      estimatedCompletionTime: '20 Mins',
      timelineSteps: [],
    ),
    sampleOrderHD8829,
  ];

  static final List<MerchantOrder> pendingRequests = [
    MerchantOrder(
      numericId: 9921,
      orderId: '#ORD-9921-A',
      customerName: 'Elena Rodriguez',
      itemsSummary: 'Organic Whole Wheat (5 lbs)',
      grainType: 'Organic Whole Wheat',
      quantityText: '5 lbs',
      timeAgo: 'Just now',
      statusTag: 'New Request',
      statusColor: const Color(0xFFCBA034),
      timelineSteps: [],
    ),
    MerchantOrder(
      numericId: 9922,
      orderId: '#ORD-9922-B',
      customerName: 'Marcus Chen',
      itemsSummary: 'Stoneground Rye (10 lbs)',
      grainType: 'Stoneground Rye',
      quantityText: '10 lbs',
      timeAgo: '5 mins ago',
      statusTag: 'New Request',
      statusColor: const Color(0xFFCBA034),
      timelineSteps: [],
    ),
  ];

  static final List<MerchantInventoryItem> inventoryItems = [
    MerchantInventoryItem(
      id: 'inv-1',
      numericId: 1,
      name: 'Classic All-Purpose',
      description: 'Versatile and soft, perfect for everyday baking, cakes, and pastries.',
      grind: 'Fine',
      weightOptions: '150 kg stock',
      price: 45.00,
      inStock: true,
      imageUrl: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=600&q=80',
      stockKg: 150,
      minimumStockKg: 30,
      productType: 'FLOUR',
    ),
    MerchantInventoryItem(
      id: 'inv-2',
      numericId: 2,
      name: 'Rustic Whole Wheat',
      description: 'Rich in flavor and nutrients, ideal for hearty artisan breads.',
      grind: 'Coarse',
      weightOptions: '400 kg stock',
      price: 36.00,
      inStock: true,
      imageUrl: 'https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b?auto=format&fit=crop&w=600&q=80',
      stockKg: 400,
      minimumStockKg: 100,
      productType: 'GRAIN',
    ),
    MerchantInventoryItem(
      id: 'inv-3',
      numericId: 3,
      name: 'Dark Rye Blend',
      description: 'A deep, earthy blend for traditional sourdoughs and pumpernickel.',
      grind: 'Medium',
      weightOptions: '15 kg stock (Low)',
      price: 55.00,
      inStock: false,
      imageUrl: 'https://images.unsplash.com/photo-1586444248902-2f64eddc13df?auto=format&fit=crop&w=600&q=80',
      stockKg: 15,
      minimumStockKg: 20,
      productType: 'FLOUR',
    ),
  ];
}

class DeliveryTripStop {
  final int orderId;
  final String orderNumber;
  final String customerName;
  final String customerPhone;
  final String deliveryAddress;
  final String homePickupAddress;
  final String? homePickupLandmark;
  final String? homePickupInstructions;
  final bool isHomeGrainPickup;
  final double quantityKg;
  final String grainTypeName;
  final String deliveryOtp;
  final String pickupPin;
  final String barcodeNumber;
  final bool isPickedUp;
  final bool isDelivered;
  final double distanceKm;
  final double latitude;
  final double longitude;
  final String? customerNotes;
  final double orderPayout;

  DeliveryTripStop({
    required this.orderId,
    required this.orderNumber,
    required this.customerName,
    required this.customerPhone,
    required this.deliveryAddress,
    this.homePickupAddress = 'Flat 402, Shivalik Towers, Ellisbridge, Ahmedabad - 380006',
    this.homePickupLandmark = 'Near Central Bank / Behind Town Hall',
    this.homePickupInstructions = 'Ring bell 402, raw grain bag kept outside door',
    this.isHomeGrainPickup = true,
    required this.quantityKg,
    required this.grainTypeName,
    this.deliveryOtp = '7391',
    this.pickupPin = '4821',
    required this.barcodeNumber,
    this.isPickedUp = false,
    this.isDelivered = false,
    this.distanceKm = 1.8,
    this.latitude = 23.0225,
    this.longitude = 72.5714,
    this.customerNotes,
    this.orderPayout = 45.0,
  });

  factory DeliveryTripStop.fromJson(Map<String, dynamic> json) {
    return DeliveryTripStop(
      orderId: json['orderId'] ?? json['id'] ?? 0,
      orderNumber: json['orderNumber'] ?? '#HD-${json['orderId'] ?? json['id'] ?? '101'}',
      customerName: json['customerName'] ?? 'Customer',
      customerPhone: json['customerPhone'] ?? '+919876543210',
      deliveryAddress: json['deliveryAddress'] ?? 'Ahmedabad',
      homePickupAddress: json['homePickupAddress'] ?? json['pickupAddress'] ?? 'Flat 402, Shivalik Towers, Ellisbridge, Ahmedabad',
      homePickupLandmark: json['homePickupLandmark'] ?? json['landmark'] ?? 'Near Central Bank / Behind Town Hall',
      homePickupInstructions: json['homePickupInstructions'] ?? json['pickupInstructions'] ?? 'Ring bell, grain bag ready',
      isHomeGrainPickup: json['isHomeGrainPickup'] ?? true,
      quantityKg: (json['quantityKg'] ?? 5.0).toDouble(),
      grainTypeName: json['grainTypeName'] ?? 'Fresh Flour',
      deliveryOtp: json['deliveryOtp'] ?? '7391',
      pickupPin: json['pickupPin'] ?? '4821',
      barcodeNumber: json['barcodeNumber'] ?? 'HD-BAG-${json['orderId'] ?? '101'}',
      isPickedUp: json['isPickedUp'] ?? false,
      isDelivered: json['isDelivered'] ?? false,
      distanceKm: (json['distanceKm'] ?? 1.8).toDouble(),
      latitude: (json['latitude'] ?? 23.0225).toDouble(),
      longitude: (json['longitude'] ?? 72.5714).toDouble(),
      customerNotes: json['customerNotes'],
      orderPayout: (json['orderPayout'] ?? json['deliveryFee'] ?? 45.0).toDouble(),
    );
  }

  DeliveryTripStop copyWith({
    bool? isPickedUp,
    bool? isDelivered,
    String? homePickupAddress,
    String? deliveryAddress,
  }) {
    return DeliveryTripStop(
      orderId: orderId,
      orderNumber: orderNumber,
      customerName: customerName,
      customerPhone: customerPhone,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      homePickupAddress: homePickupAddress ?? this.homePickupAddress,
      homePickupLandmark: homePickupLandmark,
      homePickupInstructions: homePickupInstructions,
      isHomeGrainPickup: isHomeGrainPickup,
      quantityKg: quantityKg,
      grainTypeName: grainTypeName,
      deliveryOtp: deliveryOtp,
      pickupPin: pickupPin,
      barcodeNumber: barcodeNumber,
      isPickedUp: isPickedUp ?? this.isPickedUp,
      isDelivered: isDelivered ?? this.isDelivered,
      distanceKm: distanceKm,
      latitude: latitude,
      longitude: longitude,
      customerNotes: customerNotes,
      orderPayout: orderPayout,
    );
  }
}

class DeliveryTrip {
  final int orderId;
  final String orderNumber;
  final String customerName;
  final String customerPhone;
  final String millName;
  final String millAddress;
  final String millPhone;
  final String deliveryAddress;
  final String homePickupAddress;
  final String? homePickupLandmark;
  final String? homePickupInstructions;
  final bool isHomeGrainPickup;
  final double quantityKg;
  final String grainTypeName;
  final double deliveryFee;
  final double distanceKm;
  final String status;
  final String pickupPin;
  final String deliveryOtp;
  final String barcodeNumber;
  final double currentLatitude;
  final double currentLongitude;
  final double millLatitude;
  final double millLongitude;
  final String? customerNotes;
  final bool isBatch;
  final int batchOrderCount;
  final double surgeBonus;
  final double heavyBagBonus;
  final int estimatedMins;
  final String pickupZone;
  final String paymentMode;
  final String vehicleTypeAllowed; // 'ANY' | 'CAR_VAN' | 'BIKE_EV'
  final List<DeliveryTripStop> stops;

  DeliveryTrip({
    required this.orderId,
    required this.orderNumber,
    required this.customerName,
    required this.customerPhone,
    required this.millName,
    required this.millAddress,
    this.millPhone = '+919876543211',
    required this.deliveryAddress,
    this.homePickupAddress = 'Flat 402, Shivalik Towers, Ellisbridge, Ahmedabad - 380006',
    this.homePickupLandmark = 'Near Central Bank / Behind Town Hall',
    this.homePickupInstructions = 'Ring bell 402, raw grain bag kept outside door',
    this.isHomeGrainPickup = true,
    required this.quantityKg,
    required this.grainTypeName,
    this.deliveryFee = 40.0,
    this.distanceKm = 2.8,
    required this.status,
    this.pickupPin = '4821',
    this.deliveryOtp = '7391',
    this.barcodeNumber = 'HD-BAG-101',
    this.currentLatitude = 23.0225,
    this.currentLongitude = 72.5714,
    this.millLatitude = 23.0280,
    this.millLongitude = 72.5680,
    this.customerNotes = 'Leave package at doorstep / Ring bell',
    this.isBatch = false,
    this.batchOrderCount = 1,
    this.surgeBonus = 0.0,
    this.heavyBagBonus = 0.0,
    this.estimatedMins = 18,
    this.pickupZone = 'Ellisbridge Hub',
    this.paymentMode = 'PREPAID_ONLINE',
    this.vehicleTypeAllowed = 'ANY',
    this.stops = const [],
  });

  List<DeliveryTripStop> get resolvedStops {
    if (stops.isNotEmpty) return stops;
    return [
      DeliveryTripStop(
        orderId: orderId,
        orderNumber: orderNumber,
        customerName: customerName,
        customerPhone: customerPhone,
        deliveryAddress: deliveryAddress,
        homePickupAddress: homePickupAddress,
        homePickupLandmark: homePickupLandmark,
        homePickupInstructions: homePickupInstructions,
        isHomeGrainPickup: isHomeGrainPickup,
        quantityKg: quantityKg,
        grainTypeName: grainTypeName,
        deliveryOtp: deliveryOtp,
        pickupPin: pickupPin,
        barcodeNumber: barcodeNumber,
        distanceKm: distanceKm,
        customerNotes: customerNotes,
        orderPayout: deliveryFee,
      ),
    ];
  }

  factory DeliveryTrip.fromJson(Map<String, dynamic> json) {
    var rawStops = json['stops'] as List?;
    List<DeliveryTripStop> parsedStops = [];
    if (rawStops != null) {
      parsedStops = rawStops
          .map((s) => DeliveryTripStop.fromJson(Map<String, dynamic>.from(s as Map)))
          .toList();
    }

    return DeliveryTrip(
      orderId: json['orderId'] ?? json['id'] ?? 0,
      orderNumber: json['orderNumber'] ?? '#HD-${json['orderId'] ?? json['id'] ?? '101'}',
      customerName: json['customerName'] ?? 'Customer',
      customerPhone: json['customerPhone'] ?? '+919876543210',
      millName: json['millName'] ?? json['pickupAddress'] ?? 'Shree Ganesh Flour Mill',
      millAddress: json['millAddress'] ?? json['pickupAddress'] ?? '12 Market Yard, Ellisbridge',
      millPhone: json['millPhone'] ?? '+919876543211',
      deliveryAddress: json['deliveryAddress'] ?? 'Sunrise Arcade, Ahmedabad',
      quantityKg: (json['quantityKg'] ?? 5.0).toDouble(),
      grainTypeName: json['grainTypeName'] ?? 'Fresh Wheat Flour',
      deliveryFee: (json['deliveryFee'] ?? json['estimatedDeliveryFee'] ?? 40.0).toDouble(),
      distanceKm: (json['distanceKm'] ?? 2.8).toDouble(),
      status: json['status'] ?? 'ASSIGNED',
      pickupPin: json['pickupPin'] ?? '4821',
      deliveryOtp: json['deliveryOtp'] ?? '7391',
      barcodeNumber: json['barcodeNumber'] ?? 'HD-BAG-${json['orderId'] ?? json['id'] ?? '101'}',
      currentLatitude: (json['currentLatitude'] ?? 23.0225).toDouble(),
      currentLongitude: (json['currentLongitude'] ?? 72.5714).toDouble(),
      millLatitude: (json['millLatitude'] ?? 23.0280).toDouble(),
      millLongitude: (json['millLongitude'] ?? 72.5680).toDouble(),
      customerNotes: json['customerNotes'] ?? 'Leave at doorstep and ring bell',
      isBatch: json['isBatch'] ?? (parsedStops.length > 1),
      batchOrderCount: json['batchOrderCount'] ?? (parsedStops.isNotEmpty ? parsedStops.length : 1),
      surgeBonus: (json['surgeBonus'] ?? 0.0).toDouble(),
      heavyBagBonus: (json['heavyBagBonus'] ?? ((json['quantityKg'] ?? 5.0) >= 10 ? 20.0 : 0.0)).toDouble(),
      estimatedMins: json['estimatedMins'] ?? 18,
      pickupZone: json['pickupZone'] ?? 'Central Ahmedabad',
      paymentMode: json['paymentMode'] ?? 'PREPAID_ONLINE',
      vehicleTypeAllowed: json['vehicleTypeAllowed'] ?? 'ANY',
      stops: parsedStops,
    );
  }
}

class RiderProfile {
  final int id;
  final String name;
  final String phone;
  final String email;
  final String vehicleNumber;
  final String vehicleType;
  final double rating;
  final int totalTrips;
  final bool isOnline;
  final String drivingLicense;
  final double acceptanceRate;
  final double onTimeRate;
  final int batteryLevelPct;

  RiderProfile({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.vehicleNumber,
    required this.vehicleType,
    required this.rating,
    required this.totalTrips,
    required this.isOnline,
    this.drivingLicense = 'GJ-01-2022-009841',
    this.acceptanceRate = 98.4,
    this.onTimeRate = 99.1,
    this.batteryLevelPct = 84,
  });

  factory RiderProfile.fromJson(Map<String, dynamic> json) {
    return RiderProfile(
      id: json['id'] ?? 3,
      name: json['name'] ?? 'Vikram Delivery Agent',
      phone: json['phone'] ?? '+919876543212',
      email: json['email'] ?? 'delivery@herdoor.com',
      vehicleNumber: json['vehicleNumber'] ?? 'GJ-01-AB-4821',
      vehicleType: json['vehicleType'] ?? 'Hero Electric Nyx Scooter',
      rating: (json['rating'] ?? 4.9).toDouble(),
      totalTrips: json['totalTrips'] ?? 348,
      isOnline: json['isOnline'] ?? true,
      drivingLicense: json['drivingLicense'] ?? 'GJ-01-2022-009841',
      acceptanceRate: (json['acceptanceRate'] ?? 98.4).toDouble(),
      onTimeRate: (json['onTimeRate'] ?? 99.1).toDouble(),
      batteryLevelPct: json['batteryLevelPct'] ?? 84,
    );
  }
}

class RiderEarnings {
  final double todayEarnings;
  final int todayTrips;
  final double weeklyEarnings;
  final double tripEarnings;
  final double surgeBonus;
  final double tips;
  final double totalPayout;
  final int targetTrips;
  final double targetBonus;

  RiderEarnings({
    required this.todayEarnings,
    required this.todayTrips,
    required this.weeklyEarnings,
    required this.tripEarnings,
    required this.surgeBonus,
    required this.tips,
    required this.totalPayout,
    this.targetTrips = 8,
    this.targetBonus = 150.0,
  });

  factory RiderEarnings.fromJson(Map<String, dynamic> json) {
    return RiderEarnings(
      todayEarnings: (json['todayEarnings'] ?? 525.0).toDouble(),
      todayTrips: json['todayTrips'] ?? 7,
      weeklyEarnings: (json['weeklyEarnings'] ?? 3840.0).toDouble(),
      tripEarnings: (json['tripEarnings'] ?? 440.0).toDouble(),
      surgeBonus: (json['surgeBonus'] ?? 60.0).toDouble(),
      tips: (json['tips'] ?? 25.0).toDouble(),
      totalPayout: (json['totalPayout'] ?? 525.0).toDouble(),
      targetTrips: json['targetTrips'] ?? 8,
      targetBonus: (json['targetBonus'] ?? 150.0).toDouble(),
    );
  }
}

class RiderShiftSlot {
  final String id;
  final String title;
  final String timing;
  final double guaranteedPay;
  final String surgeMultiplier;
  final String zone;
  final int spotsLeft;
  final bool isBooked;
  final String status;

  RiderShiftSlot({
    required this.id,
    required this.title,
    required this.timing,
    required this.guaranteedPay,
    required this.surgeMultiplier,
    required this.zone,
    required this.spotsLeft,
    required this.isBooked,
    required this.status,
  });

  factory RiderShiftSlot.fromJson(Map<String, dynamic> json) {
    return RiderShiftSlot(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Peak Shift',
      timing: json['timing'] ?? '08:00 AM - 12:00 PM',
      guaranteedPay: (json['guaranteedPay'] ?? 450.0).toDouble(),
      surgeMultiplier: json['surgeMultiplier'] ?? '1.5x',
      zone: json['zone'] ?? 'Ahmedabad Central',
      spotsLeft: json['spotsLeft'] ?? 5,
      isBooked: json['isBooked'] ?? false,
      status: json['status'] ?? 'OPEN',
    );
  }
}

class RiderLeaderboardEntry {
  final int rank;
  final String name;
  final int totalTrips;
  final double rating;
  final double earnings;
  final String badge;
  final bool isMe;

  RiderLeaderboardEntry({
    required this.rank,
    required this.name,
    required this.totalTrips,
    required this.rating,
    required this.earnings,
    required this.badge,
    required this.isMe,
  });

  factory RiderLeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return RiderLeaderboardEntry(
      rank: json['rank'] ?? 1,
      name: json['name'] ?? 'Rider',
      totalTrips: json['totalTrips'] ?? 0,
      rating: (json['rating'] ?? 4.9).toDouble(),
      earnings: (json['earnings'] ?? 0.0).toDouble(),
      badge: json['badge'] ?? '⚡ Star Rider',
      isMe: json['isMe'] ?? false,
    );
  }
}

class RiderCashoutTransaction {
  final String id;
  final double amount;
  final String method;
  final String upiId;
  final String status;
  final String timestamp;
  final String referenceNo;

  RiderCashoutTransaction({
    required this.id,
    required this.amount,
    required this.method,
    required this.upiId,
    required this.status,
    required this.timestamp,
    required this.referenceNo,
  });

  factory RiderCashoutTransaction.fromJson(Map<String, dynamic> json) {
    return RiderCashoutTransaction(
      id: json['id'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      method: json['method'] ?? 'Instant UPI',
      upiId: json['upiId'] ?? '',
      status: json['status'] ?? 'COMPLETED',
      timestamp: json['timestamp'] ?? 'Recently',
      referenceNo: json['referenceNo'] ?? 'UPI/2026/0000',
    );
  }
}

class RiderExpenseItem {
  final String id;
  final String type;
  final double amount;
  final String date;
  final String note;

  RiderExpenseItem({
    required this.id,
    required this.type,
    required this.amount,
    required this.date,
    required this.note,
  });

  factory RiderExpenseItem.fromJson(Map<String, dynamic> json) {
    return RiderExpenseItem(
      id: json['id'] ?? '',
      type: json['type'] ?? 'Expense',
      amount: (json['amount'] ?? 0.0).toDouble(),
      date: json['date'] ?? 'Today',
      note: json['note'] ?? '',
    );
  }
}


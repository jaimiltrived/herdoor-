import 'package:flutter/material.dart';

enum UserRole {
  customer,
  merchant,
}

class MerchantDashboardMetrics {
  final int pendingOrders;
  final int activeOrders;
  final int completedOrders;
  final double totalRevenue;

  MerchantDashboardMetrics({
    required this.pendingOrders,
    required this.activeOrders,
    required this.completedOrders,
    required this.totalRevenue,
  });

  factory MerchantDashboardMetrics.fromJson(Map<String, dynamic> json) {
    return MerchantDashboardMetrics(
      pendingOrders: json['pendingOrders'] ?? 0,
      activeOrders: json['activeOrders'] ?? 0,
      completedOrders: json['completedOrders'] ?? 0,
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
  final Color statusColor;
  final String? binLocation;
  String? estimatedCompletionTime;
  final String? deliveryDriverName;
  final String? deliveryDriverPhone;
  final String? deliveryDriverVehicle;
  final List<MerchantProcessStep> timelineSteps;

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
      mappedColor = const Color(0xFFFF8A80);
    } else if (rawStatus == 'ACCEPTED' || rawStatus == 'PROCESSING') {
      mappedTag = 'IN PROGRESS';
      mappedColor = const Color(0xFFCBA034);
    } else if (rawStatus == 'PACKING') {
      mappedTag = 'PACKING';
      mappedColor = const Color(0xFFCBA034);
    } else if (rawStatus == 'READY' || rawStatus == 'READY_FOR_PICKUP') {
      mappedTag = 'READY FOR PICKUP';
      mappedColor = const Color(0xFF2ECC71);
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

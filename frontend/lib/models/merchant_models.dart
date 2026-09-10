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
  final String? type;
  final String? orderId;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.read,
    required this.createdAt,
    this.type,
    this.orderId,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    String formattedTime = '11:00';
    final rawCreated = json['createdAt']?.toString() ?? '';
    if (rawCreated.isNotEmpty) {
      if (rawCreated.contains('T') || rawCreated.contains('-')) {
        try {
          final dt = DateTime.parse(rawCreated).toLocal();
          final hour = dt.hour.toString().padLeft(2, '0');
          final minute = dt.minute.toString().padLeft(2, '0');
          formattedTime = '$hour:$minute';
        } catch (_) {
          formattedTime = rawCreated.length >= 16 ? rawCreated.substring(11, 16) : rawCreated;
        }
      } else {
        formattedTime = rawCreated;
      }
    }

    return AppNotification(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '1') ?? 1,
      title: json['title'] ?? 'Notification',
      message: json['message'] ?? '',
      read: json['read'] ?? false,
      createdAt: formattedTime,
      type: json['type']?.toString(),
      orderId: json['orderId']?.toString() ?? json['orderNumber']?.toString(),
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
  final String? intakeStatus; // 'ACCEPTED' | 'REJECTED' | 'PENDING'
  final String? rejectionReason;
  final String? rejectionNotes;

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
    this.intakeStatus,
    this.rejectionReason,
    this.rejectionNotes,
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
    } else if (rawStatus == 'REJECTED' || rawStatus == 'REJECTED_AT_MILL' || rawStatus == 'RETURN_TO_CUSTOMER') {
      mappedTag = 'REJECTED';
      mappedColor = const Color(0xFFE74C3C);
    } else {
      mappedTag = rawStatus;
    }

    final String custName = json['customerName'] ?? json['userName'] ?? 'Customer ${rawId ?? ""}';
    final String grainName = json['grainTypeName'] ?? 'Wheat (Gehun)';
    final double rawQtyNum = (json['quantityKg'] as num?)?.toDouble() ?? 10.0;
    final String qty = rawQtyNum % 1 == 0 ? '${rawQtyNum.toInt()} kg' : '${rawQtyNum.toStringAsFixed(1)} kg';

    // Parse product-wise names and weights:
    final rawParts = grainName.split(RegExp(r',\s*')).map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
    String items;
    if (rawParts.length > 1) {
      final hasIndividualKg = rawParts.any((p) => RegExp(r'^\d+(\.\d+)?\s*(kg|g|unit)', caseSensitive: false).hasMatch(p));
      if (hasIndividualKg) {
        items = rawParts.join(', ');
      } else {
        final perItemQty = rawQtyNum / rawParts.length;
        final perItemQtyStr = perItemQty % 1 == 0 ? '${perItemQty.toInt()}kg' : '${perItemQty.toStringAsFixed(1)}kg';
        items = rawParts.map((p) => '$perItemQtyStr $p').join(', ');
      }
    } else {
      if (RegExp(r'^\d+(\.\d+)?\s*(kg|g|unit)', caseSensitive: false).hasMatch(grainName)) {
        items = grainName;
      } else {
        items = '$qty $grainName';
      }
    }
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
      intakeStatus: json['intakeStatus'],
      rejectionReason: json['rejectionReason'],
      rejectionNotes: json['rejectionNotes'],
    );
  }

  List<ProductBagItem> get productBags {
    final rawParts = grainType
        .split(RegExp(r',|\+|\band\b|&'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    double qtyNum = 5.0;
    final match = RegExp(r'(\d+(\.\d+)?)').firstMatch(quantityText);
    if (match != null) {
      qtyNum = double.tryParse(match.group(1) ?? '5.0') ?? 5.0;
    }

    final rawOrderId = numericId ?? int.tryParse(orderId.replaceAll(RegExp(r'[^0-9]'), '')) ?? 101;
    final baseTag = 'HD-BAG-$rawOrderId';

    if (rawParts.isEmpty) {
      final parsed = ParsedProductUnitInfo.parse(grainType, qtyNum);
      return [
        ProductBagItem(
          bagId: baseTag,
          orderId: rawOrderId,
          orderNumber: orderId,
          productName: parsed.cleanName.isNotEmpty ? parsed.cleanName : 'Fresh Ground Flour',
          quantityKg: parsed.quantityKg,
          unitText: parsed.unitText,
          customerName: customerName,
          customerPhone: deliveryDriverPhone ?? '',
          deliveryAddress: 'Customer Address',
          homePickupAddress: 'Customer Home',
          pickupPin: '4821',
          deliveryOtp: '7391',
        ),
      ];
    }

    final fallbackEachWeight = double.parse((qtyNum / rawParts.length).toStringAsFixed(1));

    return rawParts.asMap().entries.map((entry) {
      final idx = entry.key;
      final rawName = entry.value;
      final parsed = ParsedProductUnitInfo.parse(rawName, fallbackEachWeight);
      final tag = rawParts.length == 1
          ? baseTag
          : '$baseTag-${(idx + 1).toString().padLeft(2, '0')}';

      return ProductBagItem(
        bagId: tag,
        orderId: rawOrderId,
        orderNumber: orderId,
        productName: parsed.cleanName,
        quantityKg: parsed.quantityKg,
        unitText: parsed.unitText,
        customerName: customerName,
        customerPhone: deliveryDriverPhone ?? '',
        deliveryAddress: 'Customer Address',
        homePickupAddress: 'Customer Home',
        pickupPin: '4821',
        deliveryOtp: '7391',
      );
    }).toList();
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

  List<ProductBagItem> get productBags {
    final rawParts = grainTypeName
        .split(RegExp(r',|\+|\band\b|&'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (rawParts.isEmpty) {
      final parsed = ParsedProductUnitInfo.parse(grainTypeName, quantityKg);
      return [
        ProductBagItem(
          bagId: barcodeNumber,
          orderId: orderId,
          orderNumber: orderNumber,
          productName: parsed.cleanName.isNotEmpty ? parsed.cleanName : 'Fresh Stone Ground Flour',
          quantityKg: parsed.quantityKg,
          unitText: parsed.unitText,
          customerName: customerName,
          customerPhone: customerPhone,
          deliveryAddress: deliveryAddress,
          homePickupAddress: homePickupAddress,
          homePickupLandmark: homePickupLandmark,
          homePickupInstructions: homePickupInstructions,
          pickupPin: pickupPin,
          deliveryOtp: deliveryOtp,
          isPickedUp: isPickedUp,
          isDelivered: isDelivered,
        ),
      ];
    }

    final fallbackEachWeight = double.parse((quantityKg / rawParts.length).toStringAsFixed(1));
    final baseTag = barcodeNumber.replaceAll(RegExp(r'-\d+$'), '');

    return rawParts.asMap().entries.map((entry) {
      final idx = entry.key;
      final rawName = entry.value;
      final parsed = ParsedProductUnitInfo.parse(rawName, fallbackEachWeight);
      final tag = rawParts.length == 1
          ? barcodeNumber
          : '$baseTag-${(idx + 1).toString().padLeft(2, '0')}';

      return ProductBagItem(
        bagId: tag,
        orderId: orderId,
        orderNumber: orderNumber,
        productName: parsed.cleanName,
        quantityKg: parsed.quantityKg,
        unitText: parsed.unitText,
        customerName: customerName,
        customerPhone: customerPhone,
        deliveryAddress: deliveryAddress,
        homePickupAddress: homePickupAddress,
        homePickupLandmark: homePickupLandmark,
        homePickupInstructions: homePickupInstructions,
        pickupPin: pickupPin,
        deliveryOtp: deliveryOtp,
        isPickedUp: isPickedUp,
        isDelivered: isDelivered,
      );
    }).toList();
  }
}

class ParsedProductUnitInfo {
  final String cleanName;
  final double quantityKg;
  final String unitText;

  ParsedProductUnitInfo({
    required this.cleanName,
    required this.quantityKg,
    required this.unitText,
  });

  static ParsedProductUnitInfo parse(String rawItem, double fallbackWeight) {
    final trimmed = rawItem.trim();
    if (trimmed.isEmpty) {
      final w = fallbackWeight > 0 ? fallbackWeight : 1.0;
      return ParsedProductUnitInfo(
        cleanName: 'Product',
        quantityKg: w,
        unitText: fallbackWeight > 0 ? '${w.toStringAsFixed(w.truncateToDouble() == w ? 0 : 1)} kg' : '1 Unit',
      );
    }

    // Pattern 1: e.g. "5kg Multigrain Mix (Milling)", "5 kg Maize", "1 Unit Flour", "2 Bags Rice", "1 each Sharbati"
    final regexPrefix = RegExp(r'^(\d+(?:\.\d+)?)\s*(kg|kgs|g|gm|units?|packs?|bags?|each|pcs?|items?)\s*(?:•|-|x|of)?\s*(.*)$', caseSensitive: false);
    final matchPrefix = regexPrefix.firstMatch(trimmed);
    if (matchPrefix != null) {
      final val = double.tryParse(matchPrefix.group(1) ?? '1') ?? 1.0;
      final unit = (matchPrefix.group(2) ?? 'Unit').toLowerCase();
      final name = (matchPrefix.group(3) ?? '').trim();
      String formattedUnit;
      if (unit.startsWith('kg') || unit == 'g' || unit == 'gm') {
        formattedUnit = '${val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 1)} kg';
      } else if (unit.startsWith('pack')) {
        formattedUnit = '${val.toInt()} ${val.toInt() == 1 ? 'Pack' : 'Packs'}';
      } else if (unit.startsWith('bag')) {
        formattedUnit = '${val.toInt()} ${val.toInt() == 1 ? 'Bag' : 'Bags'}';
      } else {
        formattedUnit = '${val.toInt()} ${val.toInt() == 1 ? 'Unit' : 'Units'}';
      }
      return ParsedProductUnitInfo(
        cleanName: name.isNotEmpty ? name : trimmed,
        quantityKg: (unit.startsWith('kg') || unit == 'g' || unit == 'gm') ? val : 1.0,
        unitText: formattedUnit,
      );
    }

    // Pattern 2: e.g. "Multigrain Mix (5 kg)", "Dietary Flour (1 Unit)"
    final regexSuffix = RegExp(r'^(.*?)\s*[\(\[]\s*(\d+(?:\.\d+)?)\s*(kg|kgs|g|gm|units?|packs?|bags?|each|pcs?|items?)\s*[\)\]]$', caseSensitive: false);
    final matchSuffix = regexSuffix.firstMatch(trimmed);
    if (matchSuffix != null) {
      final name = (matchSuffix.group(1) ?? '').trim();
      final val = double.tryParse(matchSuffix.group(2) ?? '1') ?? 1.0;
      final unit = (matchSuffix.group(3) ?? 'Unit').toLowerCase();
      String formattedUnit;
      if (unit.startsWith('kg')) {
        formattedUnit = '${val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 1)} kg';
      } else {
        formattedUnit = '${val.toInt()} ${val.toInt() == 1 ? 'Unit' : 'Units'}';
      }
      return ParsedProductUnitInfo(
        cleanName: name.isNotEmpty ? name : trimmed,
        quantityKg: unit.startsWith('kg') ? val : 1.0,
        unitText: formattedUnit,
      );
    }

    // Default fallback based on product nature
    final lower = trimmed.toLowerCase();
    final isMilling = lower.contains('milling') || lower.contains('grain') || lower.contains('chakki') || lower.contains('grinding') || lower.contains('wheat') || lower.contains('makai') || lower.contains('jowar') || lower.contains('bajra') || lower.contains('chawal') || lower.contains('ragi');
    
    if (isMilling) {
      final w = fallbackWeight > 0 ? fallbackWeight : 5.0;
      return ParsedProductUnitInfo(
        cleanName: trimmed,
        quantityKg: w,
        unitText: '${w.toStringAsFixed(w.truncateToDouble() == w ? 0 : 1)} kg',
      );
    }

    return ParsedProductUnitInfo(
      cleanName: trimmed,
      quantityKg: 1.0,
      unitText: '1 Unit',
    );
  }
}

class ProductBagItem {
  final String bagId;
  final int orderId;
  final String orderNumber;
  final String productName;
  final double quantityKg;
  final String unitText;
  final String customerName;
  final String customerPhone;
  final String deliveryAddress;
  final String homePickupAddress;
  final String? homePickupLandmark;
  final String? homePickupInstructions;
  final String pickupPin;
  final String deliveryOtp;
  final bool isPickedUp;
  final bool isDelivered;
  final bool isInspected;
  final bool? isAccepted;
  final String? rejectionReason;

  ProductBagItem({
    required this.bagId,
    required this.orderId,
    required this.orderNumber,
    required this.productName,
    required this.quantityKg,
    this.unitText = '1 Unit',
    required this.customerName,
    required this.customerPhone,
    required this.deliveryAddress,
    required this.homePickupAddress,
    this.homePickupLandmark,
    this.homePickupInstructions,
    required this.pickupPin,
    required this.deliveryOtp,
    this.isPickedUp = false,
    this.isDelivered = false,
    this.isInspected = false,
    this.isAccepted,
    this.rejectionReason,
  });

  ProductBagItem copyWith({
    bool? isPickedUp,
    bool? isDelivered,
    bool? isInspected,
    bool? isAccepted,
    String? rejectionReason,
    String? unitText,
    String? homePickupAddress,
    String? deliveryAddress,
  }) {
    return ProductBagItem(
      bagId: bagId,
      orderId: orderId,
      orderNumber: orderNumber,
      productName: productName,
      quantityKg: quantityKg,
      unitText: unitText ?? this.unitText,
      customerName: customerName,
      customerPhone: customerPhone,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      homePickupAddress: homePickupAddress ?? this.homePickupAddress,
      homePickupLandmark: homePickupLandmark,
      homePickupInstructions: homePickupInstructions,
      pickupPin: pickupPin,
      deliveryOtp: deliveryOtp,
      isPickedUp: isPickedUp ?? this.isPickedUp,
      isDelivered: isDelivered ?? this.isDelivered,
      isInspected: isInspected ?? this.isInspected,
      isAccepted: isAccepted ?? this.isAccepted,
      rejectionReason: rejectionReason ?? this.rejectionReason,
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
  final String legType; // 'LEG_1_GRAIN_PICKUP' | 'LEG_2_FLOUR_DELIVERY' | 'RETURN_LEG_GRAIN_RETURN'
  final String? tripBadge;
  final String? originTitle;
  final String? destinationTitle;
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
  final String? groupCode;
  final int? groupId;
  final bool isReturnLeg;
  final bool isRejectedByMill;
  final String? rejectionReason;
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
    this.legType = 'LEG_1_GRAIN_PICKUP',
    this.tripBadge,
    this.originTitle,
    this.destinationTitle,
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
    this.groupCode,
    this.groupId,
    this.isReturnLeg = false,
    this.isRejectedByMill = false,
    this.rejectionReason,
    this.stops = const [],
  });

  bool get isReturnToCustomer =>
      isReturnLeg ||
      isRejectedByMill ||
      legType == 'RETURN_LEG_GRAIN_RETURN' ||
      status == 'RETURN_TO_CUSTOMER' ||
      status == 'REJECTED_AT_MILL';

  bool get isLeg1GrainPickup =>
      !isReturnToCustomer &&
      (legType == 'LEG_1_GRAIN_PICKUP' ||
          (isHomeGrainPickup && (status == 'PLACED' || status == 'ACCEPTED' || status == 'CONFIRMED' || status == 'PENDING' || status == 'NEW')));

  bool get isLeg2FlourDelivery => !isLeg1GrainPickup && !isReturnToCustomer;

  String get resolvedLegBadge =>
      tripBadge ??
      (isReturnToCustomer
          ? '⚠️ Return Grain (Rejected by Mill)'
          : (isLeg1GrainPickup ? '🌾 Grain Pickup (Home ➔ Mill)' : '🍞 Flour Delivery (Mill ➔ Home)'));

  String get resolvedOriginName =>
      originTitle ??
      (isReturnToCustomer
          ? '$millName (Return Rejected Grain)'
          : (isLeg1GrainPickup ? 'Customer Home ($customerName)' : millName));

  String get resolvedDestinationName =>
      destinationTitle ??
      (isReturnToCustomer
          ? 'Customer Doorstep ($customerName)'
          : (isLeg1GrainPickup ? '$millName (Drop for Grinding)' : 'Customer Doorstep ($customerName)'));

  String get effectivePickupLocation => isLeg1GrainPickup ? homePickupAddress : millAddress;

  String get effectiveDeliveryLocation => isLeg1GrainPickup ? millAddress : deliveryAddress;

  List<ProductBagItem> get productBags => resolvedStops.expand((s) => s.productBags).toList();

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

    final String statusStr = (json['status'] ?? 'ASSIGNED').toString().toUpperCase();
    final bool homeGrain = json['isHomeGrainPickup'] ?? true;
    final String parsedLeg = json['legType'] ?? (homeGrain && ['PLACED', 'ACCEPTED', 'CONFIRMED', 'PENDING', 'NEW'].contains(statusStr) ? 'LEG_1_GRAIN_PICKUP' : 'LEG_2_FLOUR_DELIVERY');

    return DeliveryTrip(
      orderId: json['orderId'] ?? json['id'] ?? 0,
      orderNumber: json['orderNumber'] ?? '#HD-${json['orderId'] ?? json['id'] ?? '101'}',
      customerName: json['customerName'] ?? 'Customer',
      customerPhone: json['customerPhone'] ?? '+919876543210',
      millName: json['millName'] ?? json['pickupAddress'] ?? 'Shree Ganesh Flour Mill',
      millAddress: json['millAddress'] ?? json['pickupAddress'] ?? '12 Market Yard, Ellisbridge',
      millPhone: json['millPhone'] ?? '+919876543211',
      deliveryAddress: json['deliveryAddress'] ?? 'Sunrise Arcade, Ahmedabad',
      homePickupAddress: json['homePickupAddress'] ?? 'Flat 402, Shivalik Towers, Ellisbridge',
      homePickupLandmark: json['homePickupLandmark'] ?? 'Near Central Bank',
      homePickupInstructions: json['homePickupInstructions'] ?? 'Pick up raw grain bag from doorstep',
      isHomeGrainPickup: homeGrain,
      legType: parsedLeg,
      tripBadge: json['tripBadge'],
      originTitle: json['originTitle'],
      destinationTitle: json['destinationTitle'],
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
      groupCode: json['groupCode']?.toString(),
      groupId: json['groupId'] is int ? json['groupId'] as int : (json['groupId'] != null ? int.tryParse(json['groupId'].toString()) : null),
      isReturnLeg: json['isReturnLeg'] ?? (statusStr == 'RETURN_TO_CUSTOMER' || statusStr == 'REJECTED_AT_MILL' || parsedLeg == 'RETURN_LEG_GRAIN_RETURN'),
      isRejectedByMill: json['isRejectedByMill'] ?? (statusStr == 'RETURN_TO_CUSTOMER' || statusStr == 'REJECTED_AT_MILL'),
      rejectionReason: json['rejectionReason']?.toString(),
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


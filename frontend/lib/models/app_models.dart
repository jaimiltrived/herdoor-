import 'dart:async';

class FlourMill {
  final String id;
  final String name;
  final double rating;
  final int reviewCount;
  final double distanceKm;
  final String specialty;
  final String statusText;
  final bool isOpen;
  final String imageUrl;
  final String address;
  final String story;

  FlourMill({
    required this.id,
    required this.name,
    required this.rating,
    required this.reviewCount,
    required this.distanceKm,
    required this.specialty,
    required this.statusText,
    required this.isOpen,
    required this.imageUrl,
    required this.address,
    required this.story,
  });

  factory FlourMill.fromJson(Map<String, dynamic> json) {
    final rawId = json['id']?.toString() ?? '101';
    final name = json['name']?.toString() ?? 'Flour Mill';
    final rating = (json['rating'] as num?)?.toDouble() ?? 4.9;
    final reviewCount = (json['reviewCount'] ?? json['review_count'] as num?)?.toInt() ?? 128;
    final distanceKm = (json['distanceKm'] ?? json['distance_km'] as num?)?.toDouble() ?? 0.8;
    final specialty = json['specialty']?.toString() ?? 'Specialist in Stone Grounding';
    final statusText = json['statusText'] ?? (json['isOpen'] == false ? 'Closed' : 'Open • Busy (25m wait)');
    final isOpen = json['isOpen'] is bool ? json['isOpen'] : (json['is_active'] != 0);
    final imageUrl = json['imageUrl'] ?? json['image_url'] ?? 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=600&q=80';
    final address = json['address']?.toString() ?? '12 Market Yard, Ellisbridge, Ahmedabad';
    final story = json['story']?.toString() ?? 'Crafting pure, stone-ground flour since 1982.';

    return FlourMill(
      id: rawId,
      name: name,
      rating: rating,
      reviewCount: reviewCount,
      distanceKm: distanceKm,
      specialty: specialty,
      statusText: statusText,
      isOpen: isOpen,
      imageUrl: imageUrl,
      address: address,
      story: story,
    );
  }
}

class GrainProduct {
  final String id;
  final String name;
  final String description;
  final double pricePerKg;
  final String imageUrl;

  GrainProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.pricePerKg,
    required this.imageUrl,
  });
}

class TrackingStep {
  final String title;
  final String subtitle;
  final String timeText;
  final bool isCompleted;
  final bool isCurrent;

  TrackingStep({
    required this.title,
    required this.subtitle,
    required this.timeText,
    this.isCompleted = false,
    this.isCurrent = false,
  });
}

class OrderModel {
  final String orderId;
  final String millName;
  final String itemSummary;
  final String quantityKg;
  final String estimatedDelivery;
  String statusStep;
  final double totalPrice;
  final List<TrackingStep> trackingSteps;
  bool isActive;
  final String date;
  final String selectedGrain;
  final int grainSource; // 1 = Own grain, 2 = Buy from mill
  final String pickupAddress;
  final String deliveryAddress;
  final String paymentMethod;
  final double millingFee;
  final double pickupFee;
  final double deliveryFee;
  final List<Map<String, dynamic>> items;

  final String millPhone;
  final String? deliveryDriverName;
  final String? deliveryDriverPhone;
  final String? deliveryDriverVehicle;
  final String? pickupPin;
  final String? deliveryOtp;

  OrderModel({
    required this.orderId,
    required this.millName,
    required this.itemSummary,
    required this.quantityKg,
    required this.estimatedDelivery,
    required this.statusStep,
    required this.totalPrice,
    required this.trackingSteps,
    this.isActive = true,
    this.date = 'Today',
    this.selectedGrain = 'Premium Wheat',
    this.grainSource = 1,
    this.pickupAddress = 'Home - 124 Heritage Way',
    this.deliveryAddress = 'Home - 124 Heritage Way',
    this.paymentMethod = 'Visa Card (•••• 4242)',
    this.millingFee = 0.0,
    this.pickupFee = 0.0,
    this.deliveryFee = 0.0,
    this.items = const [],
    this.millPhone = '+919876543211',
    this.deliveryDriverName,
    this.deliveryDriverPhone,
    this.deliveryDriverVehicle,
    this.pickupPin,
    this.deliveryOtp,
  });

  /// Returns clean product-wise items with their individual weight/kg
  List<Map<String, String>> get productItemsWithKg {
    final double? totalQty = double.tryParse(quantityKg.replaceAll(RegExp(r'[^0-9.]'), ''));

    if (items.isNotEmpty) {
      return items.map((i) {
        final name = (i['name'] ?? 'Product').toString();
        final q = i['quantity'] ?? i['quantityKg'] ?? i['qty'];
        final String kgStr = q != null ? '${q}kg' : (quantityKg.isNotEmpty ? quantityKg : '1kg');
        return {
          'name': name.replaceAll(RegExp(r'^\d+(\.\d+)?\s*(kg|g)\s*', caseSensitive: false), '').trim(),
          'kg': kgStr,
        };
      }).toList();
    }

    String raw = itemSummary.isNotEmpty ? itemSummary : selectedGrain;

    // Remove overall total kg prefix if present at start (e.g., "36kg ")
    if (totalQty != null && totalQty > 0) {
      final totalQtyInt = totalQty.toInt();
      raw = raw.replaceFirst(RegExp('^($totalQty|$totalQtyInt)\\s*kg\\s*', caseSensitive: false), '');
    }

    final parts = raw.split(RegExp(r',\s*')).map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) {
      return [{'name': selectedGrain, 'kg': quantityKg.isNotEmpty ? quantityKg : '1 kg'}];
    }

    final double eachQty = (totalQty != null && totalQty > 0 && parts.isNotEmpty) ? (totalQty / parts.length) : 0;
    final String defaultEachStr = eachQty > 0
        ? (eachQty % 1 == 0 ? '${eachQty.toInt()} kg' : '${eachQty.toStringAsFixed(1)} kg')
        : (quantityKg.isNotEmpty ? quantityKg : '1 kg');

    return parts.map((part) {
      final match = RegExp(r'^(\d+(\.\d+)?\s*(?:kg|g|units?))\s*(.+)$', caseSensitive: false).firstMatch(part);
      if (match != null) {
        return {
          'kg': match.group(1)!.trim(),
          'name': match.group(3)!.trim(),
        };
      }
      return {
        'kg': defaultEachStr,
        'name': part,
      };
    }).toList();
  }
}

class MockData {
  static final List<String> savedAddresses = [
    'Home - 124 Heritage Way, Grain District',
    'Work - 45 Old Mill Road, Westside',
    'Parents Home - 88 Golden Avenue, East End',
  ];

  static final List<Map<String, String>> paymentMethods = [
    {
      'title': 'Visa Card',
      'subtitle': '•••• •••• •••• 4242 (Expires 12/28)',
      'icon': 'credit_card',
    },
    {
      'title': 'Mastercard',
      'subtitle': '•••• •••• •••• 8890 (Expires 09/27)',
      'icon': 'credit_card',
    },
    {
      'title': 'Apple Pay',
      'subtitle': 'Connected to Wallet',
      'icon': 'phone_iphone',
    },
    {
      'title': 'Cash on Delivery',
      'subtitle': 'Pay with cash upon delivery',
      'icon': 'payments',
    },
  ];

  static final Set<String> favoriteMillIds = {'101'};

  static bool isFavorite(String millId) => favoriteMillIds.contains(millId.toString());
  static void toggleFavorite(String millId) {
    final strId = millId.toString();
    if (favoriteMillIds.contains(strId)) {
      favoriteMillIds.remove(strId);
    } else {
      favoriteMillIds.add(strId);
    }
  }

  static final List<FlourMill> mills = [
    FlourMill(
      id: '101',
      name: 'Shree Ganesh Flour Mill',
      rating: 4.8,
      reviewCount: 128,
      distanceKm: 0.8,
      specialty: 'Fresh Stone Ground Flour',
      statusText: 'Open now',
      isOpen: true,
      imageUrl: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=600&q=80',
      address: '12 Market Yard, Ellisbridge, Ahmedabad',
      story: 'Founded in 1982, Shree Ganesh Flour Mill has been dedicated to stone-milling heritage grains to preserve their natural flavor and nutritional value. We source our wheat directly from local organic farmers.',
    ),
    FlourMill(
      id: '102',
      name: 'Navrang Quality Atta Mill',
      rating: 4.8,
      reviewCount: 94,
      distanceKm: 1.2,
      specialty: 'Organic Whole Wheat & Multigrain',
      statusText: 'Open now',
      isOpen: true,
      imageUrl: 'https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b?auto=format&fit=crop&w=600&q=80',
      address: '45 Swastik Cross Road, Navrangpura, Ahmedabad',
      story: 'Navrang Quality Atta Mill specializes in non-GMO ancient grains and organic cold-milling.',
    ),
    FlourMill(
      id: '103',
      name: 'Mahadev Traditional Chakki',
      rating: 4.7,
      reviewCount: 156,
      distanceKm: 2.0,
      specialty: 'Bajra & Jowar Specialized Grinding',
      statusText: 'Closes soon',
      isOpen: true,
      imageUrl: 'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=600&q=80',
      address: 'Shop 8, Vastrapur Lake Complex, Ahmedabad',
      story: 'Traditional milling with modern quality standards.',
    ),
  ];

  static final List<GrainProduct> popularGrains = [
    GrainProduct(
      id: 'g1',
      name: 'Whole Wheat',
      description: 'Stone ground',
      pricePerKg: 45.00,
      imageUrl: 'https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b?auto=format&fit=crop&w=400&q=80',
    ),
    GrainProduct(
      id: 'g2',
      name: 'Multigrain Mix',
      description: '7-grain blend',
      pricePerKg: 52.00,
      imageUrl: 'https://images.unsplash.com/photo-1586444248902-2f64eddc13df?auto=format&fit=crop&w=400&q=80',
    ),
  ];

  static final List<OrderModel> orders = [
    OrderModel(
      orderId: 'ORD-2026-1004',
      millName: 'Artisan Mill Co.',
      itemSummary: '5kg Wheat (Gehun)',
      quantityKg: '5 kg',
      estimatedDelivery: 'Within 20 minutes',
      statusStep: 'READY FOR PICKUP',
      totalPrice: 120.00,
      isActive: true,
      date: 'Ordered at 13:00',
      selectedGrain: 'Wheat (Gehun)',
      grainSource: 1,
      pickupAddress: 'Home - 124 Heritage Way',
      deliveryAddress: 'Home - 124 Heritage Way',
      paymentMethod: 'Visa Card (•••• 4242)',
      millingFee: 25.00,
      deliveryFee: 35.00,
      trackingSteps: [
        TrackingStep(
          title: 'Order Placed',
          subtitle: 'We received your order.',
          timeText: '13:00',
          isCompleted: true,
        ),
        TrackingStep(
          title: 'Order Pickup',
          subtitle: 'Picked up by Rahul Sharma',
          timeText: '13:15',
          isCompleted: true,
        ),
        TrackingStep(
          title: 'Ready for Pickup',
          subtitle: 'Milled and ready for delivery/pickup.',
          timeText: '13:30',
          isCompleted: true,
          isCurrent: true,
        ),
        TrackingStep(
          title: 'Out for Delivery',
          subtitle: 'Delivery partner assigned.',
          timeText: 'Pending',
          isCompleted: false,
        ),
        TrackingStep(
          title: 'Delivered',
          subtitle: 'Fresh flour delivered at your door.',
          timeText: 'Pending',
          isCompleted: false,
        ),
      ],
    ),
    OrderModel(
      orderId: 'ORD-2026-1001',
      millName: 'Artisan Mill Co.',
      itemSummary: '10kg Wheat (Gehun)',
      quantityKg: '10 kg',
      estimatedDelivery: 'Within 30 minutes',
      statusStep: 'IN PROGRESS',
      totalPrice: 175.00,
      isActive: true,
      date: 'Ordered at 10:00',
      selectedGrain: 'Wheat (Gehun)',
      grainSource: 1,
      pickupAddress: 'Home - 124 Heritage Way',
      deliveryAddress: 'Home - 124 Heritage Way',
      paymentMethod: 'Visa Card (•••• 4242)',
      millingFee: 50.00,
      deliveryFee: 35.00,
      trackingSteps: [
        TrackingStep(
          title: 'Order Placed',
          subtitle: 'We received your order.',
          timeText: '10:00',
          isCompleted: true,
        ),
        TrackingStep(
          title: 'Milling in Progress',
          subtitle: 'Stone chakki grinding.',
          timeText: '10:20',
          isCompleted: false,
          isCurrent: true,
        ),
      ],
    ),
    OrderModel(
      orderId: '#HD-6212',
      millName: 'Artisan Mill Co.',
      itemSummary: 'Whole Wheat (Milling), Pre-packed Wheat, Masala Mix',
      quantityKg: '35 items',
      estimatedDelivery: 'Delivered Today',
      statusStep: 'Delivered',
      totalPrice: 390.00,
      isActive: false,
      date: 'Today',
      items: [
        {
          'name': 'Whole Wheat (Milling)',
          'type': 'milling',
          'source': 'Own Grain',
          'quantity': 13,
          'price': 5.00,
        },
        {
          'name': 'Pre-packed Wheat',
          'type': 'readymade',
          'quantity': 14,
          'price': 45.00,
        },
        {
          'name': 'Masala Mix',
          'type': 'readymade',
          'quantity': 8,
          'price': 55.00,
        },
      ],
      trackingSteps: [],
    ),
    OrderModel(
      orderId: '#HD-7104',
      millName: 'Heritage Grains',
      itemSummary: 'Multigrain Mix (Milling)',
      quantityKg: '5 kg',
      estimatedDelivery: 'Delivered Aug 14',
      statusStep: 'Delivered',
      totalPrice: 60.00,
      isActive: false,
      date: '14 Aug 2026',
      items: [
        {
          'name': 'Multigrain Mix (Milling)',
          'type': 'milling',
          'source': 'Own Grain',
          'quantity': 5,
          'price': 5.00,
        },
      ],
      trackingSteps: [],
    ),
  ];

  static OrderModel get activeOrder => orders.firstWhere((o) => o.isActive, orElse: () => orders.first);

  static Timer? _globalOrderTimer;
  static bool isAutoSimulationRunning = true;

  static void startGlobalOrderSimulation() {
    if (_globalOrderTimer != null && _globalOrderTimer!.isActive) return;
    // Step advances every 20 minutes
    _globalOrderTimer = Timer.periodic(const Duration(minutes: 20), (timer) {
      if (!isAutoSimulationRunning) return;
      final activeOrders = orders.where((o) => o.isActive).toList();
      if (activeOrders.isEmpty) return;

      for (var order in activeOrders) {
        advanceOrderStep(order);
      }
    });
  }

  static void advanceOrderStep(OrderModel order) {
    final steps = order.trackingSteps;
    if (steps.isEmpty) return;

    int currentIndex = steps.indexWhere((s) => s.isCurrent);
    if (currentIndex == -1) {
      currentIndex = steps.indexWhere((s) => !s.isCompleted);
    }

    if (currentIndex != -1 && currentIndex < steps.length) {
      final now = DateTime.now();
      final hour = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
      final period = now.hour >= 12 ? 'PM' : 'AM';
      final minute = now.minute.toString().padLeft(2, '0');
      final timeStr = '$hour:$minute $period';

      steps[currentIndex] = TrackingStep(
        title: steps[currentIndex].title,
        subtitle: steps[currentIndex].subtitle,
        timeText: steps[currentIndex].timeText.isEmpty ? timeStr : steps[currentIndex].timeText,
        isCompleted: true,
        isCurrent: false,
      );

      final nextIndex = currentIndex + 1;
      if (nextIndex < steps.length) {
        final isLast = nextIndex == steps.length - 1;
        steps[nextIndex] = TrackingStep(
          title: steps[nextIndex].title,
          subtitle: steps[nextIndex].subtitle,
          timeText: isLast ? 'Delivered' : 'In 20 mins',
          isCompleted: isLast,
          isCurrent: !isLast,
        );
        order.statusStep = steps[nextIndex].title;
        if (isLast) {
          order.isActive = false;
        }
      } else {
        order.statusStep = 'Delivered';
        order.isActive = false;
      }
    }
  }
}

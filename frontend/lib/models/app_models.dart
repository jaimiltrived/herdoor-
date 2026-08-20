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
  final double deliveryFee;

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
    this.millingFee = 5.00,
    this.deliveryFee = 2.50,
  });
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
      'title': 'Apple Pay / Google Wallet',
      'subtitle': 'Fast & secure contactless checkout',
      'icon': 'account_balance_wallet',
    },
    {
      'title': 'Cash on Delivery (COD)',
      'subtitle': 'Pay when flour is delivered home',
      'icon': 'payments',
    },
  ];

  static final List<FlourMill> mills = [
    FlourMill(
      id: 'm1',
      name: 'Artisan Mill Co.',
      rating: 4.9,
      reviewCount: 128,
      distanceKm: 0.8,
      specialty: 'Specialist in Stone Grounding',
      statusText: 'Open now',
      isOpen: true,
      imageUrl: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=600&q=80',
      address: '124 Heritage Way, Grain District',
      story: 'Founded in 1982, Artisan Mill Co. has been dedicated to stone-milling heritage grains to preserve their natural flavor and nutritional value. We source our wheat directly from local organic farmers.',
    ),
    FlourMill(
      id: 'm2',
      name: 'Heritage Grains',
      rating: 4.9,
      reviewCount: 94,
      distanceKm: 1.2,
      specialty: 'Ancient Grain Specialists',
      statusText: 'Open now',
      isOpen: true,
      imageUrl: 'https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b?auto=format&fit=crop&w=600&q=80',
      address: '45 Old Mill Road, Westside',
      story: 'Heritage Grains specializes in non-GMO ancient grains and organic cold-milling.',
    ),
    FlourMill(
      id: 'm3',
      name: 'The Golden Mill',
      rating: 4.7,
      reviewCount: 156,
      distanceKm: 2.0,
      specialty: 'Organic Whole Wheat Experts',
      statusText: 'Closes soon',
      isOpen: true,
      imageUrl: 'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=600&q=80',
      address: '88 Golden Avenue, East End',
      story: 'Traditional milling with modern quality standards.',
    ),
  ];

  static final List<GrainProduct> popularGrains = [
    GrainProduct(
      id: 'g1',
      name: 'Whole Wheat',
      description: 'Stone ground',
      pricePerKg: 4.50,
      imageUrl: 'https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b?auto=format&fit=crop&w=400&q=80',
    ),
    GrainProduct(
      id: 'g2',
      name: 'Multigrain Mix',
      description: '7-grain blend',
      pricePerKg: 5.20,
      imageUrl: 'https://images.unsplash.com/photo-1586444248902-2f64eddc13df?auto=format&fit=crop&w=400&q=80',
    ),
  ];

  static final List<OrderModel> orders = [
    OrderModel(
      orderId: '#HD-8472',
      millName: 'Artisan Mill Co.',
      itemSummary: 'Premium Sharbati',
      quantityKg: '10 kg',
      estimatedDelivery: 'Today, by 6:00 PM',
      statusStep: 'Milling in Progress',
      totalPrice: 14.00,
      isActive: true,
      date: 'Today, 11:15 AM',
      selectedGrain: 'Premium Wheat',
      grainSource: 1,
      pickupAddress: 'Home - 124 Heritage Way',
      deliveryAddress: 'Home - 124 Heritage Way',
      paymentMethod: 'Visa Card (•••• 4242)',
      millingFee: 4.00,
      deliveryFee: 2.00,
      trackingSteps: [
        TrackingStep(
          title: 'Grain Selection',
          subtitle: 'High-grade Sharbati wheat selected.',
          timeText: '09:00 AM',
          isCompleted: true,
        ),
        TrackingStep(
          title: 'Collection from Home',
          subtitle: 'Empty container picked up.',
          timeText: '10:30 AM',
          isCompleted: true,
        ),
        TrackingStep(
          title: 'Arrival at Shop',
          subtitle: 'Container ready for filling.',
          timeText: '11:15 AM',
          isCompleted: true,
        ),
        TrackingStep(
          title: 'Milling in Progress',
          subtitle: 'Fresh cold-pressed milling started.',
          timeText: 'Current Step',
          isCompleted: false,
          isCurrent: true,
        ),
        TrackingStep(
          title: 'Packaging',
          subtitle: 'Filling your container securely.',
          timeText: '',
          isCompleted: false,
        ),
        TrackingStep(
          title: 'Dispatched',
          subtitle: 'Order leaves the mill.',
          timeText: '',
          isCompleted: false,
        ),
        TrackingStep(
          title: 'With Delivery Partner',
          subtitle: 'On the way to your door.',
          timeText: '',
          isCompleted: false,
        ),
        TrackingStep(
          title: 'Delivered',
          subtitle: 'Fresh flour arrives home.',
          timeText: '',
          isCompleted: false,
        ),
      ],
    ),
    OrderModel(
      orderId: '#HD-7104',
      millName: 'Heritage Grains',
      itemSummary: 'Multigrain Mix',
      quantityKg: '5 kg',
      estimatedDelivery: 'Delivered Aug 14',
      statusStep: 'Delivered',
      totalPrice: 26.00,
      isActive: false,
      date: '14 Aug 2026',
      trackingSteps: [],
    ),
  ];

  static OrderModel get activeOrder => orders.firstWhere((o) => o.isActive, orElse: () => orders.first);

  static Timer? _globalOrderTimer;
  static bool isAutoSimulationRunning = true;

  static void startGlobalOrderSimulation() {
    if (_globalOrderTimer != null && _globalOrderTimer!.isActive) return;
    _globalOrderTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
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
          timeText: 'Just Now',
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

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../theme/app_theme.dart';
import '../models/app_models.dart';
import 'cart_screen.dart';
import 'mill_map_screen.dart';
import '../services/customer_api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class MillDetailScreen extends StatefulWidget {
  final FlourMill mill;
  final VoidCallback? onStartOrder;
  final String? heroTag;

  const MillDetailScreen({
    super.key,
    required this.mill,
    this.onStartOrder,
    this.heroTag,
  });

  @override
  State<MillDetailScreen> createState() => _MillDetailScreenState();
}

class _MillDetailScreenState extends State<MillDetailScreen> {
  int _menuTab = 0; // 0 = Custom Milling, 1 = Readymade
  late bool _isFavorite;
  
  // Cart State
  final List<Map<String, dynamic>> _cartItems = [];

  List<Map<String, dynamic>> _readymadeProducts = [
    {
      'title': 'Pre-packed Wheat',
      'desc': '1kg Pack • Stone ground flour',
      'imageUrl': 'https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b?auto=format&fit=crop&w=400&q=80',
      'price': 2.50,
    },
    {
      'title': 'Masala Mix',
      'desc': '500g Pack • Premium blend spices',
      'imageUrl': 'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?auto=format&fit=crop&w=400&q=80',
      'price': 3.00,
    },
    {
      'title': 'Organic Multigrain Flour',
      'desc': '1kg Pack • 7 Grain high fiber mix',
      'imageUrl': 'https://images.unsplash.com/photo-1586444248902-2f64eddc13df?auto=format&fit=crop&w=400&q=80',
      'price': 3.50,
    },
    {
      'title': 'Pure Besan (Gram Flour)',
      'desc': '500g Pack • Fine ground chana dal',
      'imageUrl': 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=400&q=80',
      'price': 2.20,
    },
  ];

  List<GrainProduct> _grainProducts = MockData.popularGrains;

  double get _cartTotal {
    return _cartItems.fold(0.0, (total, item) => total + (item['price'] * item['quantity']));
  }

  @override
  void initState() {
    super.initState();
    _isFavorite = MockData.isFavorite(widget.mill.id);
    _fetchDbData();
  }

  Future<void> _fetchDbData() async {
    final millId = int.tryParse(widget.mill.id) ?? 101;
    final products = await CustomerApiService.instance.getMillProducts(millId);
    if (products != null && products.isNotEmpty && mounted) {
      setState(() {
        _readymadeProducts = products.map((p) => {
          'title': p['name'] ?? 'Product',
          'desc': p['subtitle'] ?? 'Fresh from mill',
          'imageUrl': p['imageUrl'] ?? 'https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b?auto=format&fit=crop&w=400&q=80',
          'price': (p['price'] as num?)?.toDouble() ?? 2.50,
        }).toList();
      });
    }

    final grains = await CustomerApiService.instance.getMillGrains(millId);
    if (grains != null && grains.isNotEmpty && mounted) {
      setState(() {
        _grainProducts = grains.map((g) => GrainProduct(
          id: g['id']?.toString() ?? 'g1',
          name: g['name'] ?? 'Wheat',
          description: g['category'] ?? 'Grain',
          pricePerKg: (g['pricePerKg'] as num?)?.toDouble() ?? 35.0,
          imageUrl: (g['name'].toString().toLowerCase().contains('wheat'))
              ? 'https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b?auto=format&fit=crop&w=400&q=80'
              : 'https://images.unsplash.com/photo-1586444248902-2f64eddc13df?auto=format&fit=crop&w=400&q=80',
        )).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Banner Image with Floating Back & Share
                Stack(
                  children: [
                    Hero(
                      tag: widget.heroTag ?? 'mill_image_${widget.mill.id}',
                      child: Container(
                        height: 260,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: NetworkImage(widget.mill.imageUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.white.withValues(alpha: 0.85),
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary, size: 20),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                            CircleAvatar(
                              backgroundColor: Colors.white.withValues(alpha: 0.85),
                              child: IconButton(
                                icon: const Icon(Icons.share_outlined, color: AppTheme.textPrimary, size: 20),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Link copied for ${widget.mill.name}'),
                                      duration: const Duration(seconds: 2),
                                      backgroundColor: AppTheme.primaryTerracotta,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Main Info Card (Overlapping Banner)
                Transform.translate(
                  offset: const Offset(0, -30),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                widget.mill.name,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: widget.mill.isOpen ? AppTheme.surfaceCream : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppTheme.borderLight),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: widget.mill.isOpen ? AppTheme.mustardDark : Colors.grey,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    widget.mill.statusText,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: widget.mill.isOpen ? AppTheme.textPrimary : Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.star_outline_rounded, size: 18, color: AppTheme.mustardDark),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.mill.rating} (${widget.mill.reviewCount} reviews)',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text('•', style: TextStyle(color: AppTheme.textMuted)),
                            const SizedBox(width: 12),
                            Text(
                              '${widget.mill.distanceKm} km',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            GestureDetector(
                              onTap: () async {
                                final destination = '${widget.mill.name}, Ahmedabad';
                                final Uri url = Uri.parse(
                                  'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(destination)}&travelmode=driving',
                                );
                                try {
                                  if (await canLaunchUrl(url)) {
                                    await launchUrl(url, mode: LaunchMode.externalApplication);
                                  } else {
                                    await launchUrl(url, mode: LaunchMode.platformDefault);
                                  }
                                } catch (_) {}
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: AppTheme.surfaceCream,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.directions_outlined, size: 18, color: AppTheme.primaryTerracotta),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () async {
                                final Uri url = Uri.parse('tel:1234567890');
                                if (await canLaunchUrl(url)) {
                                  await launchUrl(url);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: AppTheme.surfaceCream,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.phone_outlined, size: 18, color: AppTheme.textPrimary),
                              ),
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isFavorite = !_isFavorite;
                                  MockData.toggleFavorite(widget.mill.id);
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _isFavorite ? AppTheme.primaryTerracotta.withValues(alpha: 0.15) : AppTheme.surfaceCream,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                                  size: 18,
                                  color: _isFavorite ? AppTheme.primaryTerracotta : AppTheme.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Our Story Section
                        Text(
                          'Our Story',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          widget.mill.story,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 28),
                      ],
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Availability & Timings Section
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppTheme.borderLight),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Availability',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    showModalBottomSheet(
                                      context: context,
                                      backgroundColor: Colors.white,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                                      ),
                                      builder: (context) => Padding(
                                        padding: const EdgeInsets.all(24.0),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Center(
                                              child: Container(
                                                width: 40,
                                                height: 4,
                                                decoration: BoxDecoration(
                                                  color: AppTheme.borderLight,
                                                  borderRadius: BorderRadius.circular(2),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              '${widget.mill.name} Timings',
                                              style: GoogleFonts.playfairDisplay(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            ...['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'].map(
                                              (day) => Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 6.0),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text(
                                                      day,
                                                      style: GoogleFonts.plusJakartaSans(
                                                        fontSize: 14,
                                                        fontWeight: day == 'Today' ? FontWeight.bold : FontWeight.w500,
                                                        color: AppTheme.textPrimary,
                                                      ),
                                                    ),
                                                    Text(
                                                      day == 'Sunday' ? '10:00 AM - 2:00 PM' : '10:00 AM - 12:00 PM, 4:00 PM - 9:00 PM',
                                                      style: GoogleFonts.plusJakartaSans(
                                                        fontSize: 13,
                                                        color: AppTheme.textSecondary,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 20),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                  child: Row(
                                    children: [
                                      Text(
                                        'Full Schedule',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.primaryTerracotta,
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      const Icon(Icons.chevron_right, size: 18, color: AppTheme.primaryTerracotta),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Today',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '10:00 AM - 12:00 PM',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '4:00 PM - 9:00 PM',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Location & Map Section
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MillMapScreen(
                                mill: widget.mill,
                                address: widget.mill.address,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppTheme.borderLight),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, color: AppTheme.primaryTerracotta, size: 22),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      widget.mill.address,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.open_in_full_rounded,
                                    size: 16,
                                    color: AppTheme.primaryTerracotta,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              // Real OpenStreetMap
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: SizedBox(
                                  height: 120,
                                  width: double.infinity,
                                  child: Stack(
                                    children: [
                                      FlutterMap(
                                        options: MapOptions(
                                          initialCenter: const LatLng(40.7128, -74.0060), // New York
                                          initialZoom: 15.0,
                                          interactionOptions: const InteractionOptions(flags: InteractiveFlag.none), // Static map feel
                                        ),
                                        children: [
                                          TileLayer(
                                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                            userAgentPackageName: 'com.example.herdoor_app',
                                          ),
                                          MarkerLayer(
                                            markers: [
                                              Marker(
                                                point: const LatLng(40.7128, -74.0060),
                                                width: 40,
                                                height: 40,
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.primaryTerracotta,
                                                    shape: BoxShape.circle,
                                                    border: Border.all(color: Colors.white, width: 2),
                                                    boxShadow: [
                                                      BoxShadow(color: AppTheme.primaryTerracotta.withValues(alpha: 0.4), blurRadius: 8, spreadRadius: 2),
                                                    ],
                                                  ),
                                                  child: const Icon(Icons.storefront, color: Colors.white, size: 20),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      Positioned(
                                        bottom: 8,
                                        right: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(alpha: 0.65),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.touch_app_rounded, size: 12, color: Colors.white),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Tap to expand',
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      // Services Section
                      Text(
                        'Services',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(child: _buildServiceTile(Icons.settings_outlined, 'Custom Grinding')),
                          const SizedBox(width: 10),
                          Expanded(child: _buildServiceTile(Icons.shopping_bag_outlined, 'Buy Fresh Flour')),
                          const SizedBox(width: 10),
                          Expanded(child: _buildServiceTile(Icons.blender_outlined, 'Custom Mix')),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // --- MENU TOGGLE ---
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceCream,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _menuTab = 0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: _menuTab == 0 ? Colors.white : Colors.transparent,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: _menuTab == 0 ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)] : [],
                                  ),
                                  child: Center(
                                    child: Text('Custom Milling', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: _menuTab == 0 ? AppTheme.primaryTerracotta : AppTheme.textSecondary)),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _menuTab = 1),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: _menuTab == 1 ? Colors.white : Colors.transparent,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: _menuTab == 1 ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)] : [],
                                  ),
                                  child: Center(
                                    child: Text('Readymade', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: _menuTab == 1 ? AppTheme.primaryTerracotta : AppTheme.textSecondary)),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // --- CONDITIONAL MENU CONTENT ---
                      if (_menuTab == 0) ...[
                        Text(
                          'Select Grain to Mill',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Column(
                          children: _grainProducts.map((product) {
                            return _CustomMillingItemCard(
                              product: product,
                              onAddToCart: (item) {
                                setState(() {
                                  _cartItems.add(item);
                                });
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text('${item['name']} added to cart!'),
                                  duration: const Duration(seconds: 1),
                                  behavior: SnackBarBehavior.floating,
                                ));
                              },
                            );
                          }).toList(),
                        ),
                      ] else ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Readymade Products',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            TextButton(
                              onPressed: () {},
                              child: Text(
                                'View All',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryTerracotta,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Column(
                          children: _readymadeProducts.map((prod) {
                            return _ReadymadeItemCard(
                              title: prod['title'] ?? 'Product',
                              desc: prod['desc'] ?? '',
                              imageUrl: prod['imageUrl'] ?? 'https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b?auto=format&fit=crop&w=400&q=80',
                              price: (prod['price'] as num?)?.toDouble() ?? 2.50,
                              onAddToCart: (item) {
                                setState(() {
                                  _cartItems.add(item);
                                });
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text('${item['name']} added to cart!'),
                                  duration: const Duration(seconds: 1),
                                  behavior: SnackBarBehavior.floating,
                                ));
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Sticky Bottom Bar "Start Order"
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.background,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    if (_cartItems.isEmpty) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CartScreen(
                          millName: widget.mill.name,
                          millId: int.tryParse(widget.mill.id) ?? (widget.mill.name.toLowerCase().contains('navrang') ? 102 : 101),
                          cartItems: _cartItems,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _cartItems.isEmpty ? Colors.grey[300] : AppTheme.primaryTerracotta,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart_outlined, color: _cartItems.isEmpty ? Colors.grey[500] : Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        _cartItems.isEmpty 
                            ? 'Cart is empty' 
                            : 'View Cart (${_cartItems.length} items) - \$${_cartTotal.toStringAsFixed(2)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _cartItems.isEmpty ? Colors.grey[600] : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceTile(IconData icon, String title) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: AppTheme.surfaceCream,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.primaryTerracotta, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadymadeItemCard extends StatefulWidget {
  final String title;
  final String desc;
  final String imageUrl;
  final double price;
  final Function(Map<String, dynamic> item) onAddToCart;

  const _ReadymadeItemCard({
    required this.title,
    required this.desc,
    required this.imageUrl,
    required this.price,
    required this.onAddToCart,
  });

  @override
  State<_ReadymadeItemCard> createState() => _ReadymadeItemCardState();
}

class _ReadymadeItemCardState extends State<_ReadymadeItemCard> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final totalPrice = widget.price * _quantity;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  widget.imageUrl,
                  width: 75,
                  height: 75,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.desc,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '\$${widget.price.toStringAsFixed(2)} each',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryTerracotta,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Quantity Stepper
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCream,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () {
                        if (_quantity > 1) {
                          setState(() => _quantity--);
                        }
                      },
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        child: Icon(Icons.remove, size: 18, color: AppTheme.textPrimary),
                      ),
                    ),
                    Text(
                      '$_quantity',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        setState(() => _quantity++);
                      },
                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        child: Icon(Icons.add, size: 18, color: AppTheme.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),

              // Add to Cart Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryTerracotta,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: () {
                  widget.onAddToCart({
                    'name': widget.title,
                    'type': 'readymade',
                    'quantity': _quantity,
                    'price': widget.price,
                  });
                },
                icon: const Icon(Icons.shopping_bag_outlined, size: 16),
                label: Text(
                  'Add • \$${totalPrice.toStringAsFixed(2)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CustomMillingItemCard extends StatefulWidget {
  final GrainProduct product;
  final Function(Map<String, dynamic> item) onAddToCart;

  const _CustomMillingItemCard({
    required this.product,
    required this.onAddToCart,
  });

  @override
  State<_CustomMillingItemCard> createState() => _CustomMillingItemCardState();
}

class _CustomMillingItemCardState extends State<_CustomMillingItemCard> {
  int _quantity = 5;

  @override
  Widget build(BuildContext context) {
    const unitPrice = 0.50;
    final totalPrice = unitPrice * _quantity;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  widget.product.imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.product.description,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceWarm,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.primaryTerracotta.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        'Milling Price: \$0.50/kg',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryTerracotta,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Quantity and Add to Cart Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Quantity Stepper
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCream,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () {
                        if (_quantity > 1) {
                          setState(() => _quantity--);
                        }
                      },
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        child: Icon(Icons.remove, size: 18, color: AppTheme.textPrimary),
                      ),
                    ),
                    Text(
                      '$_quantity kg',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        setState(() => _quantity++);
                      },
                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        child: Icon(Icons.add, size: 18, color: AppTheme.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),

              // Add to Cart Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryTerracotta,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: () {
                  widget.onAddToCart({
                    'name': '${widget.product.name} (Milling)',
                    'type': 'milling',
                    'source': 'Own Grain',
                    'quantity': _quantity,
                    'price': unitPrice,
                  });
                },
                icon: const Icon(Icons.shopping_bag_outlined, size: 16),
                label: Text(
                  'Add • \$${totalPrice.toStringAsFixed(2)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

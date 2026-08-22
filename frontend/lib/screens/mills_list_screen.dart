import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/app_models.dart';
import 'mill_detail_screen.dart';
import 'profile_screen.dart';

class MillsListScreen extends StatefulWidget {
  final VoidCallback onStartOrder;
  final VoidCallback? onOpenDrawer;
  final bool showBackButton;
  const MillsListScreen({super.key, required this.onStartOrder, this.onOpenDrawer, this.showBackButton = false});

  @override
  State<MillsListScreen> createState() => _MillsListScreenState();
}

class _MillsListScreenState extends State<MillsListScreen> {
  final _searchController = TextEditingController();
  String _selectedCategory = 'All';
  final bool _isOpenNow = false;
  List<FlourMill> _filteredMills = MockData.mills;

  List<Map<String, dynamic>> get _categories => [
    {
      'name': 'All',
      'image': 'assets/images/cat_all.jpg',
    },
    {
      'name': 'Wheat',
      'image': 'assets/images/cat_wheat.jpg',
    },
    {
      'name': 'Rice',
      'image': 'assets/images/cat_rice.jpg',
    },
    {
      'name': 'Millet',
      'image': 'assets/images/cat_millet.jpg',
    },
    {
      'name': 'Spices',
      'image': 'assets/images/cat_spices.jpg',
    },
  ];

  void _filterMills(String query) {
    setState(() {
      _filteredMills = MockData.mills.where((mill) {
        final matchesQuery = mill.name.toLowerCase().contains(query.toLowerCase()) ||
            mill.specialty.toLowerCase().contains(query.toLowerCase());
        final matchesCategory = _selectedCategory == 'All' ||
            mill.specialty.toLowerCase().contains(_selectedCategory.toLowerCase());
        final matchesOpen = !_isOpenNow || mill.isOpen;
        return matchesQuery && matchesCategory && matchesOpen;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppTheme.textPrimary),
                onPressed: () => Navigator.pop(context),
              )
            : IconButton(
                icon: const Icon(Icons.menu, color: AppTheme.textPrimary),
                onPressed: widget.onOpenDrawer,
              ),
        title: Text(
          'Flour Mills Near You',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryTerracotta,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfileScreen()),
                  );
                },
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.borderLight, width: 2),
                    image: const DecorationImage(
                      image: NetworkImage(
                        'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=200&q=80',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Input and Toggle Row
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _filterMills,
                      style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryTerracotta),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_searchController.text.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.clear_rounded, color: AppTheme.textMuted),
                                onPressed: () {
                                  _searchController.clear();
                                  _filterMills('');
                                },
                              ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: VerticalDivider(width: 1, color: AppTheme.borderLight),
                            ),
                            IconButton(
                              icon: const Icon(Icons.mic_none_rounded, color: AppTheme.primaryTerracotta),
                              onPressed: () {},
                            ),
                          ],
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        hintText: 'Search mills or grain...',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppTheme.borderLight),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppTheme.primaryTerracotta, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Categories List (Horizontal)
              SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final isSelected = category['name'] == _selectedCategory;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategory = category['name'];
                          _filterMills(_searchController.text);
                        });
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(40),
                            child: Image.asset(
                              category['image'],
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: 60,
                                height: 60,
                                color: AppTheme.surfaceWarm,
                                child: const Icon(Icons.grain, color: AppTheme.primaryTerracotta),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            category['name'],
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (isSelected)
                            Container(
                              width: 40,
                              height: 3,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryTerracotta,
                                borderRadius: BorderRadius.circular(1.5),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),

              Text(
                '${_filteredMills.length} Mills Available',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 14),

              // Mills List
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredMills.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final mill = _filteredMills[index];
                  return TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: Duration(milliseconds: 300 + (index * 100)),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: Opacity(
                          opacity: value,
                          child: child,
                        ),
                      );
                    },
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MillDetailScreen(
                              mill: mill,
                              onStartOrder: widget.onStartOrder,
                              heroTag: 'mills_list_mill_${mill.id}',
                            ),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.borderLight),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              children: [
                                Hero(
                                  tag: 'mills_list_mill_${mill.id}',
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                    child: Image.network(
                                      mill.imageUrl,
                                      height: 140,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        MockData.toggleFavorite(mill.id);
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.15),
                                            blurRadius: 6,
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        MockData.isFavorite(mill.id)
                                            ? Icons.favorite_rounded
                                            : Icons.favorite_border_rounded,
                                        color: MockData.isFavorite(mill.id)
                                            ? AppTheme.primaryTerracotta
                                            : AppTheme.textSecondary,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        mill.name,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: mill.isOpen
                                            ? AppTheme.mustardGold.withValues(alpha: 0.2)
                                            : Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        mill.statusText,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: mill.isOpen ? AppTheme.mustardDark : Colors.grey.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  mill.specialty,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.star_rounded, color: AppTheme.mustardGold, size: 18),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${mill.rating} (${mill.reviewCount} reviews)',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text('•', style: TextStyle(color: AppTheme.textMuted)),
                                    const SizedBox(width: 12),
                                    const Icon(Icons.location_on_outlined, color: AppTheme.primaryTerracotta, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${mill.distanceKm} km away',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

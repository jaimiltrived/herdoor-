import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../models/merchant_models.dart';
import '../../services/merchant_api_service.dart';

class MerchantInventoryScreen extends StatefulWidget {
  const MerchantInventoryScreen({super.key});

  @override
  State<MerchantInventoryScreen> createState() => _MerchantInventoryScreenState();
}

class _MerchantInventoryScreenState extends State<MerchantInventoryScreen> {
  int _mainInventoryTab = 0; // 0: Flour Inventory, 1: Raw Grain Vendor Hub
  int _selectedCategory = 0; // 0: All-Purpose, 1: Whole Wheat, 2: Rye
  bool _isLoading = true;
  List<MerchantInventoryItem> _inventoryItems = MerchantMockData.inventoryItems;
  List<MerchantInventoryItem> _lowStockItems = [];

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    setState(() => _isLoading = true);
    final items = await MerchantApiService.instance.getInventory();
    if (items != null) {
      _inventoryItems = items;
    }

    final lowStock = await MerchantApiService.instance.getLowStockInventory();
    _lowStockItems = lowStock ?? _inventoryItems.where((i) => i.stockKg <= i.minimumStockKg).toList();

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showAddProductModal(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final stockCtrl = TextEditingController(text: '100');
    final minStockCtrl = TextEditingController(text: '20');
    final priceCtrl = TextEditingController(text: '45');
    String selectedType = 'FLOUR';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add New Flour / Grain Product',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Add fresh inventory products directly to your mill store catalog.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 18),

              // Product Type Chooser
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: Center(child: Text('Flour Product', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold))),
                      selected: selectedType == 'FLOUR',
                      selectedColor: AppTheme.primaryTerracotta,
                      labelStyle: TextStyle(color: selectedType == 'FLOUR' ? Colors.white : AppTheme.textPrimary),
                      onSelected: (val) => setModalState(() => selectedType = 'FLOUR'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChoiceChip(
                      label: Center(child: Text('Raw Grain', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold))),
                      selected: selectedType == 'GRAIN',
                      selectedColor: const Color(0xFF6E5616),
                      labelStyle: TextStyle(color: selectedType == 'GRAIN' ? Colors.white : AppTheme.textPrimary),
                      onSelected: (val) => setModalState(() => selectedType = 'GRAIN'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  hintText: 'e.g. Premium Sharbati Atta',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: priceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Price / kg (₹)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: stockCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Initial Stock (kg)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              TextField(
                controller: minStockCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Low Stock Alert Threshold (kg)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) return;

                    final double stock = double.tryParse(stockCtrl.text) ?? 100;
                    final double minStock = double.tryParse(minStockCtrl.text) ?? 20;
                    final double price = double.tryParse(priceCtrl.text) ?? 45;

                    final created = await MerchantApiService.instance.createInventoryItem(
                      name: name,
                      productType: selectedType,
                      stockKg: stock,
                      minimumStockKg: minStock,
                      pricePerKg: price,
                    );

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFF2ECC71),
                          content: Text(
                            created != null
                                ? '✅ Product "$name" Added to Inventory on Backend!'
                                : 'Product "$name" added.',
                          ),
                        ),
                      );
                    }
                    _loadInventory();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6E5616),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white),
                  label: Text(
                    'Create Product in Inventory',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAdjustStockDialog(BuildContext context, MerchantInventoryItem item, bool isStockIn) async {
    final qtyCtrl = TextEditingController(text: '20');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isStockIn ? 'Add Stock (+ Stock In)' : 'Deduct Stock (- Stock Out)',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Item: ${item.name}',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Current Stock: ${item.stockKg} kg',
              style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: isStockIn ? 'Quantity to Add (kg)' : 'Quantity to Deduct (kg)',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final double kg = double.tryParse(qtyCtrl.text) ?? 20;
              final numId = item.numericId ?? 1;
              final messenger = ScaffoldMessenger.of(context);
              final nav = Navigator.of(context);

              await MerchantApiService.instance.adjustStock(numId, kg, isStockIn);

              if (!mounted) return;
              nav.pop();
              messenger.showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF2ECC71),
                  content: Text(
                    '✅ ${isStockIn ? "Added" : "Deducted"} $kg kg stock for ${item.name}!',
                  ),
                ),
              );
              _loadInventory();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isStockIn ? const Color(0xFF2ECC71) : AppTheme.primaryTerracotta,
            ),
            child: Text(
              isStockIn ? 'Confirm Stock In' : 'Confirm Stock Out',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteItemDialog(BuildContext context, MerchantInventoryItem item) async {
    final numId = item.numericId;
    if (numId == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete ${item.name}?',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to remove this product from your mill inventory?',
          style: GoogleFonts.plusJakartaSans(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final nav = Navigator.of(context);
              await MerchantApiService.instance.deleteInventoryItem(numId);

              if (!mounted) return;
              nav.pop();
              messenger.showSnackBar(
                SnackBar(content: Text('Product ${item.name} removed from inventory.')),
              );
              _loadInventory();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
            child: const Text('Delete Item', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadInventory,
      color: AppTheme.primaryTerracotta,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Inventory & Supplies',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Manage store flour & raw grain inventory.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddProductModal(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6E5616),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  icon: const Icon(Icons.add, color: Colors.white, size: 18),
                  label: Text(
                    'Add Item',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Low Stock Warning Alert Banner (if any)
            if (_lowStockItems.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFECEB),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFFFC0BD)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFB3AC),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.warning_amber_rounded, color: AppTheme.primaryTerracotta, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Low Stock Alert (${_lowStockItems.length} items)',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryTerracotta,
                            ),
                          ),
                          Text(
                            _lowStockItems.map((i) => '${i.name} (${i.stockKg}kg)').join(', '),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (_lowStockItems.isNotEmpty) {
                          _showAdjustStockDialog(context, _lowStockItems.first, true);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryTerracotta,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                      child: const Text('Restock', style: TextStyle(fontSize: 11, color: Colors.white)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
            ],

            // Main Sub-Tab Switcher (Flour Inventory vs Raw Grain Vendor Hub)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF3ECE1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _mainInventoryTab = 0),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _mainInventoryTab == 0 ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: _mainInventoryTab == 0
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.bakery_dining_rounded,
                              size: 18,
                              color: _mainInventoryTab == 0
                                  ? AppTheme.primaryTerracotta
                                  : AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Flour Products',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _mainInventoryTab == 0
                                    ? AppTheme.textPrimary
                                    : AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _mainInventoryTab = 1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _mainInventoryTab == 1 ? const Color(0xFF6E5616) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: _mainInventoryTab == 1
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.store_mall_directory_rounded,
                              size: 18,
                              color: _mainInventoryTab == 1 ? Colors.white : AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Grain Vendor Hub',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _mainInventoryTab == 1 ? Colors.white : AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (_mainInventoryTab == 0) ...[
              // Category Chips for Flour
              Row(
                children: [
                  _buildCategoryChip(0, 'All Products'),
                  const SizedBox(width: 10),
                  _buildCategoryChip(1, 'Flour'),
                  const SizedBox(width: 10),
                  _buildCategoryChip(2, 'Grains'),
                ],
              ),
              const SizedBox(height: 20),

              // Inventory Items List
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Center(child: CircularProgressIndicator(color: AppTheme.primaryTerracotta)),
                )
              else
                for (final item in _inventoryItems) _buildInventoryCard(context, item),
            ] else ...[
              // Raw Grain Vendor Hub View
              _buildRawGrainVendorHub(context),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(int index, String label) {
    final isSelected = _selectedCategory == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryTerracotta : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? AppTheme.primaryTerracotta : const Color(0xFFCBA034),
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildInventoryCard(BuildContext context, MerchantInventoryItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Image.network(
                  item.imageUrl,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 160,
                    color: AppTheme.surfaceWarm,
                    child: const Icon(Icons.grain_rounded, size: 50, color: AppTheme.primaryTerracotta),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6E5616),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item.productType,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    item.inStock ? '${item.stockKg} kg in stock' : 'Low Stock (${item.stockKg}kg)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: item.inStock ? AppTheme.textPrimary : Colors.red[700],
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.name,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (item.numericId != null)
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                        onPressed: () => _showDeleteItemDialog(context, item),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item.description,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F5EF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Category',
                            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.grind,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Min Threshold',
                            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${item.minimumStockKg} kg',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '₹${item.price.toStringAsFixed(2)} / kg',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: item.inStock ? AppTheme.textPrimary : AppTheme.textMuted,
                      ),
                    ),
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: () => _showAdjustStockDialog(context, item, true),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF2ECC71),
                            side: const BorderSide(color: Color(0xFF2ECC71)),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          ),
                          child: const Text('+ Stock In', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () => _showAdjustStockDialog(context, item, false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryTerracotta,
                            side: const BorderSide(color: AppTheme.primaryTerracotta),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          ),
                          child: const Text('- Stock Out', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRawGrainVendorHub(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6E5616), Color(0xFF4A3A0E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'UPCOMING FEATURE',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Raw Grain Vendor Procurement',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Directly buy bulk raw wheat, barley, and organic grains from verified regional agricultural vendors & farmers.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: Colors.white70,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Preview Grain Vendor List
        _buildVendorGrainCard(
          title: 'Premium Sharbati Raw Wheat',
          vendor: 'SunRipe Organic Farms',
          priceKg: '₹36.00 / kg (Min 50kg)',
          status: 'Vendor Certified',
        ),
        _buildVendorGrainCard(
          title: 'Cold-Climate Rye Grain',
          vendor: 'Highland Grains Co-op',
          priceKg: '₹48.00 / kg (Min 25kg)',
          status: 'Vendor Certified',
        ),
      ],
    );
  }

  Widget _buildVendorGrainCard({
    required String title,
    required String vendor,
    required String priceKg,
    required String status,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFF3ECE1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.grass_rounded, color: Color(0xFF6E5616), size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  'Supplier: $vendor',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  priceKg,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryTerracotta,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Raw Grain Vendor Ordering will be active in next update!')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6E5616),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              elevation: 0,
            ),
            child: const Text('Pre-Order', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

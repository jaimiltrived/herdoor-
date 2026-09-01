import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../models/merchant_models.dart';
import '../../services/delivery_api_service.dart';

class DeliveryEarningsScreen extends StatefulWidget {
  const DeliveryEarningsScreen({super.key});

  @override
  State<DeliveryEarningsScreen> createState() => _DeliveryEarningsScreenState();
}

class _DeliveryEarningsScreenState extends State<DeliveryEarningsScreen> {
  bool _isLoading = true;
  RiderEarnings? _earnings;
  List<RiderCashoutTransaction> _cashouts = [];
  List<RiderExpenseItem> _expenses = [];
  String _selectedPeriod = 'Today'; // 'Today' | 'This Week' | 'This Month'
  final _customUpiController = TextEditingController(text: 'vikram.rider@oksbi');
  final _expenseAmountController = TextEditingController();
  final _expenseNoteController = TextEditingController();

  final List<Map<String, dynamic>> _tripHistory = [
    {
      'orderNumber': '#HD-101',
      'millName': 'Shree Ganesh Flour Mill',
      'customerName': 'Ananya Sharma',
      'time': '02:45 PM',
      'distance': '2.3 km',
      'basePay': 35.0,
      'surge': 15.0,
      'tip': 5.0,
      'total': 55.0,
      'grainType': '5kg Sharbati Atta',
      'rating': 5.0,
    },
    {
      'orderNumber': '#HD-98',
      'millName': 'Navrang Quality Atta',
      'customerName': 'Devang Mehta',
      'time': '01:15 PM',
      'distance': '3.8 km',
      'basePay': 45.0,
      'surge': 20.0,
      'tip': 10.0,
      'total': 75.0,
      'grainType': '10kg Besan & Bajra',
      'rating': 5.0,
    },
    {
      'orderNumber': '#HD-94',
      'millName': 'Ganga Pure Chakki',
      'customerName': 'Sneha Trivedi',
      'time': '11:50 AM',
      'distance': '1.9 km',
      'basePay': 35.0,
      'surge': 10.0,
      'tip': 15.0,
      'total': 60.0,
      'grainType': '3.5kg Multigrain Flour',
      'rating': 4.9,
    },
    {
      'orderNumber': '#HD-91',
      'millName': 'Shree Ganesh Flour Mill',
      'customerName': 'Bhavin Shah',
      'time': '10:10 AM',
      'distance': '4.2 km',
      'basePay': 50.0,
      'surge': 15.0,
      'tip': 0.0,
      'total': 65.0,
      'grainType': '15kg Wheat & Chana',
      'rating': 5.0,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadEarningsData();
  }

  @override
  void dispose() {
    _customUpiController.dispose();
    _expenseAmountController.dispose();
    _expenseNoteController.dispose();
    super.dispose();
  }

  Future<void> _loadEarningsData() async {
    setState(() => _isLoading = true);
    final earnings = await DeliveryApiService.instance.getEarnings();
    final cashouts = await DeliveryApiService.instance.getCashouts();
    final expenses = await DeliveryApiService.instance.getExpenses();

    if (mounted) {
      setState(() {
        _earnings = earnings;
        _cashouts = cashouts;
        _expenses = expenses;
        _isLoading = false;
      });
    }
  }

  double get _totalExpensesAmount {
    return _expenses.fold(0.0, (sum, item) => sum + item.amount);
  }

  double get _netProfit {
    final gross = _earnings?.todayEarnings ?? 525.0;
    return (gross - _totalExpensesAmount).clamp(0.0, 99999.0);
  }

  void _handleInstantCashout() {
    final availableBal = _earnings?.totalPayout ?? 525.0;
    String selectedMethod = 'Google Pay UPI';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            top: 24,
            left: 24,
            right: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Instant Bank & UPI Payout',
                    style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F8F5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('0% Fee ⚡ Instant', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF1E8449))),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Available Balance Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3ECE1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Transferable Balance', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondary)),
                        Text(
                          '₹${availableBal.toStringAsFixed(2)}',
                          style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w900, color: const Color(0xFF1E8449)),
                        ),
                      ],
                    ),
                    const Icon(Icons.account_balance_rounded, size: 32, color: Color(0xFF6E5616)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Text('Select Payout Method:', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),

              Material(
                color: Colors.transparent,
                child: RadioGroup<String>(
                  groupValue: selectedMethod,
                  onChanged: (val) => setModalState(() => selectedMethod = val ?? selectedMethod),
                  child: Column(
                    children: [
                      RadioListTile<String>(
                        value: 'Google Pay UPI',
                        dense: true,
                        title: Text('Google Pay (GPay) UPI', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600)),
                        subtitle: Text('vikram.rider@oksbi', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondary)),
                      ),
                      RadioListTile<String>(
                        value: 'PhonePe UPI',
                        dense: true,
                        title: Text('PhonePe UPI', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600)),
                        subtitle: Text('vikram.rider@ybl', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondary)),
                      ),
                      RadioListTile<String>(
                        value: 'HDFC Direct Bank Transfer',
                        dense: true,
                        title: Text('HDFC Bank A/c (XX8421)', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600)),
                        subtitle: Text('IMPS Instant Settlement', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondary)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final res = await DeliveryApiService.instance.requestInstantCashout(
                      amount: availableBal,
                      method: selectedMethod,
                    );
                    if (mounted) {
                      _loadEarningsData();
                      _showPayoutSuccessModal(availableBal, selectedMethod, res['data']?['transaction']?['referenceNo'] ?? 'UPI/2026/89412');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E8449),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    'TRANSFER ₹${availableBal.toStringAsFixed(0)} INSTANTLY',
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showPayoutSuccessModal(double amount, String method, String ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFE8F8F5)),
              child: const Icon(Icons.check_circle_rounded, size: 48, color: Color(0xFF1E8449)),
            ),
            const SizedBox(height: 14),
            Text('Payout Successful!', style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('₹${amount.toStringAsFixed(2)} transferred to $method.', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textSecondary), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFFF3ECE1), borderRadius: BorderRadius.circular(10)),
              child: Text('Ref: $ref', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF6E5616))),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryTerracotta),
                child: const Text('Done', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openAddExpenseModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, top: 20, left: 20, right: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Log Daily Trip Expense', style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _expenseAmountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount (₹)',
                hintText: 'e.g. 50',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _expenseNoteController,
              decoration: InputDecoration(
                labelText: 'Expense Note / Location',
                hintText: 'e.g. EV Charging Station Satellite',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () async {
                  final amt = double.tryParse(_expenseAmountController.text.trim()) ?? 50.0;
                  final note = _expenseNoteController.text.trim();
                  Navigator.pop(ctx);
                  await DeliveryApiService.instance.addExpense('EV / Fuel Charge', amt, note.isNotEmpty ? note : 'Trip fuel expense');
                  _expenseAmountController.clear();
                  _expenseNoteController.clear();
                  _loadEarningsData();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✅ Expense logged and net profit updated!')),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryTerracotta),
                child: const Text('Save Expense', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Earnings & Wallet',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryTerracotta,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _openAddExpenseModal,
            icon: const Icon(Icons.receipt_long_outlined, color: AppTheme.primaryTerracotta),
            tooltip: 'Log Fuel/EV Expense',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryTerracotta))
          : RefreshIndicator(
              color: AppTheme.primaryTerracotta,
              onRefresh: _loadEarningsData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Period Selector
                    _buildPeriodSelector(),
                    const SizedBox(height: 16),

                    // Main Earnings Hero Card
                    _buildEarningsHeroCard(),
                    const SizedBox(height: 18),

                    // Net Profit & Expense Breakdown HUD
                    _buildNetProfitHUD(),
                    const SizedBox(height: 18),

                    // Daily Milestone Quests Card
                    _buildMilestoneQuestCard(),
                    const SizedBox(height: 18),

                    // Earnings Breakdown Itemizer
                    _buildBreakdownCard(),
                    const SizedBox(height: 18),

                    // Recent Trips Ledger
                    _buildTripHistorySection(),
                    const SizedBox(height: 20),

                    // Cashouts & Withdrawal Ledger
                    if (_cashouts.isNotEmpty) ...[
                      _buildCashoutLedgerSection(),
                      const SizedBox(height: 20),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPeriodSelector() {
    final periods = ['Today', 'This Week', 'This Month'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        children: periods.map((p) {
          final isSelected = _selectedPeriod == p;
          return Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedPeriod = p),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryTerracotta : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  p,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEarningsHeroCard() {
    final displayAmount = _selectedPeriod == 'Today'
        ? (_earnings?.todayEarnings ?? 525.0)
        : (_earnings?.weeklyEarnings ?? 3840.0);

    final displayTrips = _selectedPeriod == 'Today'
        ? (_earnings?.todayTrips ?? 7)
        : 48;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E8449), Color(0xFF145A32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E8449).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$_selectedPeriod Gross Earnings',
                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w600),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$displayTrips Trips Done',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '₹${displayAmount.toStringAsFixed(2)}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          // Cashout Button
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: _handleInstantCashout,
              icon: const Icon(Icons.flash_on_rounded, size: 18, color: Color(0xFF1E8449)),
              label: Text(
                'INSTANT CASHOUT VIA UPI / BANK',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w900, color: const Color(0xFF1E8449)),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetProfitHUD() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text('₹${(_earnings?.todayEarnings ?? 525.0).toStringAsFixed(0)}', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF1E8449))),
              Text('Gross Pay', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppTheme.textSecondary)),
            ],
          ),
          const Text('—', style: TextStyle(color: Colors.grey, fontSize: 18)),
          Column(
            children: [
              Text('₹${_totalExpensesAmount.toStringAsFixed(0)}', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFFC0392B))),
              Text('EV / Fuel Exp', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppTheme.textSecondary)),
            ],
          ),
          const Text('=', style: TextStyle(color: Colors.grey, fontSize: 18)),
          Column(
            children: [
              Text('₹${_netProfit.toStringAsFixed(0)}', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFF6E5616))),
              Text('Net Take-Home', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF6E5616))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneQuestCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF9E7),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF1C40F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.military_tech_rounded, color: Color(0xFFB7791F)),
                  const SizedBox(width: 6),
                  Text(
                    'Silver Rider Milestone',
                    style: GoogleFonts.playfairDisplay(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF6E5616)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFB7791F),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '+₹150 Cash Bonus',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Complete 8 flour delivery trips today to unlock your ₹150 daily cash reward.',
            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF6E5616)),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: 7 / 8,
            backgroundColor: Colors.white,
            color: const Color(0xFFB7791F),
            minHeight: 8,
            borderRadius: BorderRadius.circular(6),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Progress: 7 of 8 completed', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF6E5616))),
              Text('1 more needed!', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF1E8449))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Earnings Breakdown',
            style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 14),
          _buildBreakdownRow('Base Distance Delivery Pay', '₹440.00'),
          _buildBreakdownRow('Peak Hour Surge Bonus', '₹60.00'),
          _buildBreakdownRow('Heavy Bag Incentive (>10kg)', '₹20.00'),
          _buildBreakdownRow('Customer Doorstep Tips', '₹25.00'),
          const Divider(height: 20),
          _buildBreakdownRow('Total Payout Accrued', '₹545.00', isBold: true, isGreen: true),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String label, String val, {bool isBold = false, bool isGreen = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: isBold ? AppTheme.textPrimary : AppTheme.textSecondary,
            ),
          ),
          Text(
            val,
            style: GoogleFonts.plusJakartaSans(
              fontSize: isBold ? 14 : 12,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
              color: isGreen ? const Color(0xFF1E8449) : AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Completed Trips Today (${_tripHistory.length})',
          style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _tripHistory.length,
          separatorBuilder: (ctx, i) => const SizedBox(height: 10),
          itemBuilder: (ctx, i) {
            final t = _tripHistory[i];
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(t['orderNumber'] as String, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primaryTerracotta)),
                          const SizedBox(width: 8),
                          Text('• ${t['time']}', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondary)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('${t['grainType']} (${t['distance']})', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                      Text('${t['millName']} ➔ ${t['customerName']}', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondary)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('+₹${(t['total'] as double).toStringAsFixed(0)}', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w900, color: const Color(0xFF1E8449))),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 12, color: Color(0xFFF1C40F)),
                          Text(' ${t['rating']}', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCashoutLedgerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent UPI & Bank Payouts',
          style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _cashouts.length,
          separatorBuilder: (ctx, i) => const SizedBox(height: 10),
          itemBuilder: (ctx, i) {
            final c = _cashouts[i];
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F8F5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.account_balance_rounded, size: 20, color: Color(0xFF1E8449)),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.method, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('${c.timestamp} • ${c.referenceNo}', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                  Text(
                    '₹${c.amount.toStringAsFixed(0)}',
                    style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w900, color: const Color(0xFF1E8449)),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/package_model.dart';

class PackageScannerWidget extends StatefulWidget {
  final String title;
  final String subtitle;
  final String orderNumber;
  final List<PackageModel> packages;
  final String scanType; // PICKUP, MILL_INTAKE, MILL_DISPATCH, DELIVERY
  final Future<PackageScanResult> Function(String qrToken, String scanType) onPackageScanned;
  final VoidCallback onAllPackagesVerified;

  const PackageScannerWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.orderNumber,
    required this.packages,
    required this.scanType,
    required this.onPackageScanned,
    required this.onAllPackagesVerified,
  });

  @override
  State<PackageScannerWidget> createState() => _PackageScannerWidgetState();
}

class _PackageScannerWidgetState extends State<PackageScannerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _laserController;
  late Animation<double> _laserAnimation;
  bool _isTorchOn = false;
  bool _isProcessingScan = false;
  final Set<String> _verifiedPackageCodes = {};
  String? _feedbackMessage;
  bool _isErrorFeedback = false;

  int get _scannedCount => _verifiedPackageCodes.length;
  bool get _isAllVerified => widget.packages.isNotEmpty && _scannedCount >= widget.packages.length;

  @override
  void initState() {
    super.initState();
    _laserController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _laserAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _laserController, curve: Curves.easeInOut),
    );

    // Pre-populate already scanned packages
    for (final p in widget.packages) {
      if (p.isScanned) {
        _verifiedPackageCodes.add(p.packageCode);
      }
    }
  }

  @override
  void dispose() {
    _laserController.dispose();
    super.dispose();
  }

  Future<void> _handleScanInput(String qrInput) async {
    if (_isProcessingScan || qrInput.trim().isEmpty) return;

    setState(() {
      _isProcessingScan = true;
      _feedbackMessage = null;
    });

    try {
      final result = await widget.onPackageScanned(qrInput.trim(), widget.scanType);

      setState(() {
        _isProcessingScan = false;
        if (result.isSuccess) {
          if (result.package != null) {
            _verifiedPackageCodes.add(result.package!.packageCode);
          }
          _isErrorFeedback = false;
          _feedbackMessage = result.isDuplicate
              ? '⚠️ Package already verified!'
              : '✓ Package ${result.package?.packageCode ?? qrInput} Verified!';

          if (_isAllVerified) {
            widget.onAllPackagesVerified();
          }
        } else {
          _isErrorFeedback = true;
          _feedbackMessage = '❌ ${result.message}';
        }
      });
    } catch (e) {
      setState(() {
        _isProcessingScan = false;
        _isErrorFeedback = true;
        _feedbackMessage = '❌ Scan failed: ${e.toString()}';
      });
    }
  }

  void _showManualEntryDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Enter Package QR / Code',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter the printed code on the package label (e.g. PKG-${widget.orderNumber.replaceAll('#', '')}-01):',
              style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[700]),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'e.g. PKG-${widget.orderNumber.replaceAll('#', '')}-01',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppTheme.primaryEmerald, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryEmerald,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              final code = controller.text.trim();
              Navigator.pop(ctx);
              if (code.isNotEmpty) {
                _handleScanInput(code);
              }
            },
            child: Text('Verify Code', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF101827),
      child: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Order ${widget.orderNumber} • ${widget.subtitle}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isTorchOn ? Icons.flash_on : Icons.flash_off,
                      color: _isTorchOn ? Colors.amber : Colors.grey[400],
                    ),
                    onPressed: () => setState(() => _isTorchOn = !_isTorchOn),
                  ),
                ],
              ),
            ),

            // Progress Banner
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _isAllVerified
                    ? AppTheme.primaryEmerald.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isAllVerified ? AppTheme.primaryEmerald : Colors.white24,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        _isAllVerified ? Icons.check_circle : Icons.qr_code_scanner,
                        color: _isAllVerified ? AppTheme.primaryEmerald : Colors.amber,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Verified Packages',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '$_scannedCount / ${widget.packages.length}',
                    style: GoogleFonts.outfit(
                      color: _isAllVerified ? AppTheme.primaryEmerald : Colors.amber,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            // Scanner Viewfinder Area
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _isAllVerified
                        ? AppTheme.primaryEmerald
                        : AppTheme.primaryEmerald.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Viewfinder Box Frame
                    Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _isAllVerified ? AppTheme.primaryEmerald : Colors.white70,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),

                    // Animated Laser Line
                    AnimatedBuilder(
                      animation: _laserAnimation,
                      builder: (context, child) {
                        return Positioned(
                          top: 40 + (_laserAnimation.value * 180),
                          child: Container(
                            width: 220,
                            height: 3,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryEmerald,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryEmerald.withValues(alpha: 0.8),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    // Feedback Banner overlay
                    if (_feedbackMessage != null)
                      Positioned(
                        top: 20,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: _isErrorFeedback ? Colors.red.shade900 : AppTheme.primaryEmerald,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _feedbackMessage!,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),

                    if (_isProcessingScan)
                      const CircularProgressIndicator(color: Colors.amber),

                    // Instruction at bottom of camera frame
                    Positioned(
                      bottom: 20,
                      child: Text(
                        _isAllVerified
                            ? 'All Packages Verified!'
                            : 'Align package QR inside frame',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Package List Cards
            Container(
              height: 110,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: widget.packages.length,
                itemBuilder: (context, index) {
                  final pkg = widget.packages[index];
                  final isVerified = _verifiedPackageCodes.contains(pkg.packageCode) || pkg.isScanned;

                  return GestureDetector(
                    onTap: () {
                      // Tap package to auto-scan in demo / test mode
                      _handleScanInput(pkg.qrToken.isNotEmpty ? pkg.qrToken : pkg.packageCode);
                    },
                    child: Container(
                      width: 170,
                      margin: const EdgeInsets.only(right: 12, bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isVerified
                            ? AppTheme.primaryEmerald.withValues(alpha: 0.15)
                            : const Color(0xFF1F2937),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isVerified ? AppTheme.primaryEmerald : Colors.white12,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                pkg.packageCode,
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              Icon(
                                isVerified ? Icons.check_circle : Icons.radio_button_unchecked,
                                color: isVerified ? AppTheme.primaryEmerald : Colors.grey,
                                size: 18,
                              ),
                            ],
                          ),
                          Text(
                            pkg.productName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: Colors.grey[300],
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '${pkg.expectedWeight.toStringAsFixed(1)} ${pkg.unit}',
                            style: GoogleFonts.inter(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Bottom Actions Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white30),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _showManualEntryDialog,
                    icon: const Icon(Icons.keyboard, size: 18),
                    label: Text('Manual Code', style: GoogleFonts.inter(fontSize: 13)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isAllVerified ? AppTheme.primaryEmerald : Colors.grey[700],
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isAllVerified
                          ? () {
                              widget.onAllPackagesVerified();
                              Navigator.pop(context);
                            }
                          : null,
                      child: Text(
                        _isAllVerified ? 'COMPLETE SCAN' : 'SCAN ALL PACKAGES',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

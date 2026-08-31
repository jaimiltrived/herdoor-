import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../models/merchant_models.dart';
import '../../services/delivery_api_service.dart';

enum TripStage {
  headingToMill,
  atMillPickup,
  headingToCustomer,
  atCustomerDelivery,
  completed,
}

class ActiveTripScreen extends StatefulWidget {
  final DeliveryTrip trip;
  final VoidCallback? onTripCompleted;

  const ActiveTripScreen({
    super.key,
    required this.trip,
    this.onTripCompleted,
  });

  @override
  State<ActiveTripScreen> createState() => _ActiveTripScreenState();
}

class _ActiveTripScreenState extends State<ActiveTripScreen> with TickerProviderStateMixin {
  TripStage _currentStage = TripStage.headingToMill;
  bool _isProcessing = false;
  bool _isVoiceMuted = false;
  final _pinController = TextEditingController();
  final _otpController = TextEditingController();

  late List<DeliveryTripStop> _tripStops;
  int _currentStopIndex = 0;
  bool _isFlashlightOn = false;

  // Real-Time Navigation Simulation State
  Timer? _navSimulationTimer;
  double _routeProgress = 0.15; // 0.0 to 1.0 along the route
  int _distanceMeters = 850;
  int _etaSeconds = 210; // 3 min 30 sec
  int _currentSpeedKmH = 32;
  String _trafficCondition = 'CLEAR'; // 'CLEAR' | 'MODERATE' | 'HEAVY'
  String _currentTurnInstruction = 'In 200m, turn right onto Market Yard Cross Rd';
  IconData _currentTurnIcon = Icons.turn_right_rounded;
  late AnimationController _pulseController;
  late AnimationController _scannerLaserController;

  // Proof of delivery state
  bool _isMoistureChecked = true;
  bool _isBagSealed = true;
  bool _isWeightVerified = true;
  bool _hasDoorstepPhoto = false;
  bool _hasCustomerSignature = false;

  DeliveryTripStop get _activeStop {
    if (_tripStops.isEmpty) {
      return DeliveryTripStop(
        orderId: widget.trip.orderId,
        orderNumber: widget.trip.orderNumber,
        customerName: widget.trip.customerName,
        customerPhone: widget.trip.customerPhone,
        deliveryAddress: widget.trip.deliveryAddress,
        quantityKg: widget.trip.quantityKg,
        grainTypeName: widget.trip.grainTypeName,
        barcodeNumber: widget.trip.barcodeNumber,
        pickupPin: widget.trip.pickupPin,
        deliveryOtp: widget.trip.deliveryOtp,
      );
    }
    return _tripStops[_currentStopIndex.clamp(0, _tripStops.length - 1)];
  }

  @override
  void initState() {
    super.initState();
    _tripStops = List.from(widget.trip.resolvedStops);
    _pinController.text = widget.trip.pickupPin;
    _otpController.text = _activeStop.deliveryOtp;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scannerLaserController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _startRealtimeNavigationSimulation();
  }

  @override
  void dispose() {
    _navSimulationTimer?.cancel();
    _pulseController.dispose();
    _scannerLaserController.dispose();
    _pinController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _startRealtimeNavigationSimulation() {
    _navSimulationTimer?.cancel();
    _navSimulationTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_currentStage == TripStage.headingToMill) {
        setState(() {
          if (_routeProgress < 0.95) {
            _routeProgress += 0.08;
            _distanceMeters = (_distanceMeters - 70).clamp(50, 2000);
            _etaSeconds = (_etaSeconds - 15).clamp(10, 600);
            _currentSpeedKmH = 28 + (_routeProgress * 10).toInt() % 12;

            if (_routeProgress > 0.6) {
              _currentTurnInstruction = 'In 80m, destination on your left (${widget.trip.millName})';
              _currentTurnIcon = Icons.turn_left_rounded;
              _trafficCondition = 'CLEAR';
            } else {
              _currentTurnInstruction = 'Head straight on Ellisbridge Market Road';
              _currentTurnIcon = Icons.straight_rounded;
              _trafficCondition = 'MODERATE';
            }
          } else {
            _distanceMeters = 20;
            _etaSeconds = 0;
            _currentTurnInstruction = 'You have arrived at ${widget.trip.millName}!';
            _currentTurnIcon = Icons.check_circle_rounded;
          }
        });
      } else if (_currentStage == TripStage.headingToCustomer) {
        setState(() {
          if (_routeProgress < 0.95) {
            _routeProgress += 0.07;
            _distanceMeters = (_distanceMeters - 90).clamp(30, 4000);
            _etaSeconds = (_etaSeconds - 18).clamp(10, 900);
            _currentSpeedKmH = 34 + (_routeProgress * 15).toInt() % 14;

            if (_routeProgress > 0.7) {
              _currentTurnInstruction = 'Turn left towards Stop ${_currentStopIndex + 1} (${_activeStop.customerName})';
              _currentTurnIcon = Icons.turn_left_rounded;
            } else if (_routeProgress > 0.4) {
              _currentTurnInstruction = 'Take flyover towards Satellite Road';
              _currentTurnIcon = Icons.fork_right_rounded;
              _trafficCondition = 'CLEAR';
            } else {
              _currentTurnInstruction = 'Continue 800m straight on SG Highway Service Rd';
              _currentTurnIcon = Icons.straight_rounded;
              _trafficCondition = 'HEAVY';
            }
          } else {
            _distanceMeters = 15;
            _etaSeconds = 0;
            _currentTurnInstruction = 'Arrived at Stop ${_currentStopIndex + 1} Doorstep (${_activeStop.customerName})';
            _currentTurnIcon = Icons.check_circle_rounded;
          }
        });
      }

      // Sync Live GPS Coordinates & Telemetry to Backend
      final currentLat = 23.0225 + (0.0150 * _routeProgress);
      final currentLng = 72.5714 - (0.0589 * _routeProgress);
      DeliveryApiService.instance.updateLocation(
        currentLat,
        currentLng,
        orderId: widget.trip.orderId,
        speed: _currentSpeedKmH,
        heading: _routeProgress > 0.5 ? 'NW' : 'NE',
        etaSeconds: _etaSeconds,
        distanceMeters: _distanceMeters,
        stage: _currentStage.name,
        trafficCondition: _trafficCondition,
      );
    });
  }

  void _resetNavigationForCustomerStage() {
    setState(() {
      _routeProgress = 0.10;
      _distanceMeters = 1850;
      _etaSeconds = 480; // 8 minutes
      _currentSpeedKmH = 35;
      _currentTurnInstruction = 'Head west towards Stop ${_currentStopIndex + 1} (${_activeStop.customerName})';
      _currentTurnIcon = Icons.straight_rounded;
      _trafficCondition = 'CLEAR';
      _otpController.text = _activeStop.deliveryOtp;
    });
  }

  Future<void> _launchGoogleMaps() async {
    final destination = _currentStage == TripStage.headingToMill || _currentStage == TripStage.atMillPickup
        ? '${widget.trip.millName}, ${widget.trip.millAddress}'
        : '${_activeStop.customerName}, ${_activeStop.deliveryAddress}';

    final Uri googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(destination)}&travelmode=driving',
    );

    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Opening Navigation in Maps...')),
        );
      }
    }
  }

  Future<void> _callParty(String phone, String name) async {
    final Uri callUri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(callUri)) {
      await launchUrl(callUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Masked Call Connected to $name: $phone')),
        );
      }
    }
  }

  void _openWhatsAppHelper(String name, String phone) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.chat_rounded, color: Color(0xFF2ECC71)),
                const SizedBox(width: 8),
                Text('Quick WhatsApp Message to $name', style: GoogleFonts.playfairDisplay(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 14),
            _buildQuickTemplateTile('🛵 I have reached your society gate. Please allow entry.', name),
            _buildQuickTemplateTile('🌾 Namaste! Your freshly milled flour from ${widget.trip.millName} is arriving in 5 mins.', name),
            _buildQuickTemplateTile('🔑 Main gate par khada hoon, kripya OTP share karein.', name),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickTemplateTile(String msg, String name) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.send_rounded, size: 18, color: AppTheme.primaryTerracotta),
      title: Text(msg, style: GoogleFonts.plusJakartaSans(fontSize: 13)),
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Message sent to $name via WhatsApp!')),
        );
      },
    );
  }

  void _openSOSIncidentModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Color(0xFFC0392B)),
                const SizedBox(width: 8),
                Text('Trip Problem & Emergency SOS', style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            _buildIncidentItem('Customer Unreachable (Wait timer active)', Icons.person_off_outlined),
            _buildIncidentItem('Grain Bag Spilled / Packaging Torn', Icons.inventory_2_outlined),
            _buildIncidentItem('Vehicle Breakdown / Flat Tyre', Icons.build_outlined),
            _buildIncidentItem('Incorrect Delivery Address / Society Blocked', Icons.wrong_location_outlined),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('🚨 Connecting to Rider Safety Priority Dispatcher...')),
                  );
                },
                icon: const Icon(Icons.phone_in_talk_rounded, color: Colors.white),
                label: Text('Call Priority Helpline (1800-437-3667)', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC0392B), padding: const EdgeInsets.symmetric(vertical: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncidentItem(String title, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryTerracotta, size: 20),
      title: Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right_rounded, size: 18),
      onTap: () {
        Navigator.pop(context);
        DeliveryApiService.instance.reportIncident(
          orderId: widget.trip.orderId,
          type: title,
          description: 'Rider reported: $title on active trip #${widget.trip.orderNumber}',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Report logged: $title. Dispatch notified.')),
        );
      },
    );
  }

  /// Per-Order Dedicated QR & Barcode Camera Scanner Modal
  void _openPerOrderBarcodeScanner(DeliveryTripStop stop, {bool isPickup = true}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF14181D),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              height: MediaQuery.of(context).size.height * 0.78,
              child: Column(
                children: [
                  // Modal drag handle & Title
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF2ECC71), size: 24),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isPickup ? 'Verify Mill Bag Barcode' : 'Doorstep Bag Scan',
                                style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              Text(
                                '${stop.orderNumber} • ${stop.customerName}',
                                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.white70),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(modalCtx),
                        icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Camera Viewfinder Box with Laser Sweep
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF2ECC71), width: 2),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Viewfinder corner marks & barcode graphic
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isPickup ? Icons.inventory_2_outlined : Icons.qr_code_2_rounded,
                                size: 90,
                                color: Colors.white38,
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Expected Tag: ${stop.barcodeNumber}',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF2ECC71), fontWeight: FontWeight.w800),
                                ),
                              ),
                            ],
                          ),

                          // Animated Laser Sweep Beam
                          AnimatedBuilder(
                            animation: _scannerLaserController,
                            builder: (context, child) {
                              return Align(
                                alignment: Alignment(0, (_scannerLaserController.value * 2) - 1),
                                child: Container(
                                  height: 3,
                                  width: MediaQuery.of(context).size.width * 0.70,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2ECC71),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF2ECC71).withValues(alpha: 0.9),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                          // Flashlight & Camera Controls Overlay
                          Positioned(
                            top: 12,
                            right: 12,
                            child: IconButton(
                              onPressed: () {
                                setModalState(() => _isFlashlightOn = !_isFlashlightOn);
                              },
                              icon: Icon(
                                _isFlashlightOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                                color: _isFlashlightOn ? const Color(0xFFF1C40F) : Colors.white70,
                              ),
                              style: IconButton.styleFrom(backgroundColor: Colors.black54),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Order Bag Information
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E242B),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.grain_rounded, color: Color(0xFFF1C40F), size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${stop.quantityKg} kg • ${stop.grainTypeName}',
                                style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              Text(
                                'Address: ${stop.deliveryAddress}',
                                style: GoogleFonts.plusJakartaSans(fontSize: 10, color: Colors.white60),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Confirm Scan Action Buttons
                  if (!isPickup) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(modalCtx);
                          setState(() {
                            final idx = _tripStops.indexWhere((s) => s.orderId == stop.orderId);
                            if (idx != -1) {
                              _tripStops[idx] = _tripStops[idx].copyWith(isDelivered: true);
                              _otpController.text = stop.deliveryOtp;
                            }
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('✅ Barcode ${stop.barcodeNumber} Verified! Completing Drop...'),
                              backgroundColor: const Color(0xFF1E8449),
                            ),
                          );
                          _handleConfirmDelivery();
                        },
                        icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
                        label: Text(
                          'SCAN & INSTANTLY COMPLETE DROP',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E8449),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(modalCtx);
                          setState(() {
                            final idx = _tripStops.indexWhere((s) => s.orderId == stop.orderId);
                            if (idx != -1) {
                              _tripStops[idx] = _tripStops[idx].copyWith(isDelivered: true);
                              _otpController.text = stop.deliveryOtp;
                            }
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('✅ Barcode ${stop.barcodeNumber} Verified! Ready to handover.'),
                              backgroundColor: const Color(0xFF1E8449),
                            ),
                          );
                        },
                        icon: const Icon(Icons.qr_code_scanner_rounded, size: 16, color: Colors.white70),
                        label: Text(
                          'Scan & Verify Tag Only',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white24),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ] else ...[
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(modalCtx);
                          setState(() {
                            final idx = _tripStops.indexWhere((s) => s.orderId == stop.orderId);
                            if (idx != -1) {
                              _tripStops[idx] = _tripStops[idx].copyWith(isPickedUp: true);
                              _pinController.text = stop.pickupPin;
                            }
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('✅ Barcode Verified: ${stop.barcodeNumber} matched for ${stop.customerName}!'),
                              backgroundColor: const Color(0xFF1E8449),
                            ),
                          );
                        },
                        icon: const Icon(Icons.document_scanner_rounded, color: Colors.white),
                        label: Text(
                          'SIMULATE SUCCESSFUL BARCODE SCAN',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E8449),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _simulateDoorstepPhoto() {
    setState(() => _hasDoorstepPhoto = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('📸 Proof-of-delivery photo captured with GPS timestamp watermark!')),
    );
  }

  void _simulateCustomerSignature() {
    setState(() => _hasCustomerSignature = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✍️ Customer digital signature captured on canvas!')),
    );
  }

  Future<void> _handleConfirmPickup() async {
    final enteredPin = _pinController.text.trim();
    final effectivePin = enteredPin.isNotEmpty
        ? enteredPin
        : (_activeStop.pickupPin.isNotEmpty
            ? _activeStop.pickupPin
            : (widget.trip.pickupPin.isNotEmpty ? widget.trip.pickupPin : '4821'));

    setState(() {
      _isProcessing = true;
      _pinController.text = effectivePin;
    });

    final res = await DeliveryApiService.instance.confirmPickup(
      widget.trip.orderId,
      pin: effectivePin,
    );

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (res['success'] == true) {
      setState(() {
        _currentStage = TripStage.headingToCustomer;
        // Mark all stops picked up
        _tripStops = _tripStops.map((s) => s.copyWith(isPickedUp: true)).toList();
      });
      _resetNavigationForCustomerStage();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ All flour bags verified & picked up! Navigating to Stop 1 (${_activeStop.customerName}).'),
          backgroundColor: const Color(0xFF1E8449),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Pickup failed'),
          backgroundColor: const Color(0xFFC0392B),
        ),
      );
    }
  }

  Future<void> _handleConfirmDelivery() async {
    final enteredOtp = _otpController.text.trim();
    final effectiveOtp = enteredOtp.isNotEmpty
        ? enteredOtp
        : (_activeStop.deliveryOtp.isNotEmpty
            ? _activeStop.deliveryOtp
            : (widget.trip.deliveryOtp.isNotEmpty ? widget.trip.deliveryOtp : '7391'));

    setState(() {
      _isProcessing = true;
      _otpController.text = effectiveOtp;
    });

    final res = await DeliveryApiService.instance.confirmDelivery(
      _activeStop.orderId,
      otp: effectiveOtp,
    );

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (res['success'] == true) {
      setState(() {
        final idx = _currentStopIndex;
        if (idx < _tripStops.length) {
          _tripStops[idx] = _tripStops[idx].copyWith(isDelivered: true);
        }

        // If more stops exist in grouped trip, advance to next stop
        if (_currentStopIndex < _tripStops.length - 1) {
          _currentStopIndex++;
          _currentStage = TripStage.headingToCustomer;
          _hasDoorstepPhoto = false;
          _hasCustomerSignature = false;
          _resetNavigationForCustomerStage();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Stop $_currentStopIndex Complete! Navigating to Stop ${_currentStopIndex + 1} (${_activeStop.customerName}).'),
              backgroundColor: const Color(0xFF1E8449),
            ),
          );
        } else {
          _currentStage = TripStage.completed;
          _navSimulationTimer?.cancel();
          _showCompletionDialog();
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Delivery confirmation failed'),
          backgroundColor: const Color(0xFFC0392B),
        ),
      );
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFE8F8F5),
              ),
              child: const Icon(Icons.check_circle_rounded, size: 48, color: Color(0xFF1E8449)),
            ),
            const SizedBox(height: 16),
            Text(
              'Trip #${widget.trip.orderNumber} Completed!',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'All ${_tripStops.length} delivery stop(s) successfully handed over. Total payout credited to your wallet.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3ECE1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Trip Payout', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
                  Text(
                    '+₹${widget.trip.deliveryFee.toStringAsFixed(0)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF1E8449),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  if (widget.onTripCompleted != null) {
                    widget.onTripCompleted!();
                  } else if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryTerracotta,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  'Back to Radar Queue',
                  style: GoogleFonts.plusJakartaSans(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (widget.onTripCompleted != null) {
              widget.onTripCompleted!();
            } else if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trip #${widget.trip.orderNumber}',
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryTerracotta,
              ),
            ),
            Text(
              _getStageTitle(),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => setState(() => _isVoiceMuted = !_isVoiceMuted),
            icon: Icon(_isVoiceMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded, color: AppTheme.primaryTerracotta),
            tooltip: _isVoiceMuted ? 'Unmute Audio HUD' : 'Mute Audio HUD',
          ),
          IconButton(
            onPressed: _openSOSIncidentModal,
            icon: const Icon(Icons.warning_amber_rounded, color: Color(0xFFC0392B)),
            tooltip: 'Rider SOS / Issue',
          ),
        ],
      ),
      body: Column(
        children: [
          // Stage Timeline Progress Bar
          _buildStageProgressBar(),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  if (_currentStage == TripStage.completed)
                    _buildCompletedTripCard()
                  else ...[
                    // Real-time Turn-by-Turn Navigation HUD Card
                    _buildNavigationHUDCard(),
                    const SizedBox(height: 16),

                    // Unified Trip Route Map (All Stops on 1 Map)
                    _buildUnifiedTripRouteMap(),
                    const SizedBox(height: 16),

                    // Simulation Fast-Forward / Jump Controls
                    _buildSimulationControlHUD(),
                    const SizedBox(height: 16),

                    // Stage Specific Action Section
                    if (_currentStage == TripStage.headingToMill || _currentStage == TripStage.atMillPickup)
                      _buildMillPickupSection()
                    else if (_currentStage == TripStage.headingToCustomer || _currentStage == TripStage.atCustomerDelivery)
                      _buildCustomerDeliverySection(),
                  ],

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedTripCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFE8F8F5),
            ),
            child: const Icon(Icons.check_circle_rounded, size: 48, color: Color(0xFF1E8449)),
          ),
          const SizedBox(height: 16),
          Text(
            'Trip #${widget.trip.orderNumber} Completed!',
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'All ${_tripStops.length} stop(s) successfully delivered. Payout added to your daily wallet.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF3ECE1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Payout Credited',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  '+₹${widget.trip.deliveryFee.toStringAsFixed(0)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF1E8449),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                if (widget.onTripCompleted != null) {
                  widget.onTripCompleted!();
                } else if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
              icon: const Icon(Icons.radar_rounded, color: Colors.white),
              label: Text(
                'Back to Radar Queue',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryTerracotta,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStageTitle() {
    switch (_currentStage) {
      case TripStage.headingToMill:
        return 'Step 1: Heading to Mill Pickup';
      case TripStage.atMillPickup:
        return 'Step 2: At Mill Handover (Scan Bags)';
      case TripStage.headingToCustomer:
        return 'Step 3: Heading to Stop ${_currentStopIndex + 1} of ${_tripStops.length}';
      case TripStage.atCustomerDelivery:
        return 'Step 4: At Stop ${_currentStopIndex + 1} Doorstep';
      case TripStage.completed:
        return 'Trip Completed';
    }
  }

  Widget _buildStageProgressBar() {
    final stages = [
      {'title': 'Accept', 'done': true},
      {'title': 'Mill', 'done': _currentStage.index >= TripStage.headingToMill.index},
      {'title': 'Pickup', 'done': _currentStage.index >= TripStage.headingToCustomer.index},
      {'title': 'Drop', 'done': _currentStage.index >= TripStage.atCustomerDelivery.index},
      {'title': 'Done', 'done': _currentStage == TripStage.completed},
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: stages.map((s) {
          final isDone = s['done'] as bool;
          return Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone ? const Color(0xFF1E8449) : Colors.grey[300],
                ),
                child: isDone
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 4),
              Text(
                s['title'] as String,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: isDone ? FontWeight.bold : FontWeight.w500,
                  color: isDone ? const Color(0xFF1E8449) : AppTheme.textMuted,
                ),
              ),
              if (s != stages.last) ...[
                const SizedBox(width: 8),
                Container(width: 14, height: 2, color: isDone ? const Color(0xFF1E8449) : Colors.grey[300]),
                const SizedBox(width: 8),
              ],
            ],
          );
        }).toList(),
      ),
    );
  }

  /// Unified Trip Route Map (Shows Entire Multi-Stop Route on One Map)
  Widget _buildUnifiedTripRouteMap() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E242B),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
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
              Row(
                children: [
                  const Icon(Icons.alt_route_rounded, color: Color(0xFF2ECC71), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Unified Multi-Stop Route Map',
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF2ECC71).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_tripStops.length} Stops Active',
                  style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF2ECC71)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Route Visual Timeline Canvas
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF14181D),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              children: [
                // Pickup Node
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF8C4A3E),
                          ),
                          child: const Icon(Icons.storefront_rounded, size: 14, color: Colors.white),
                        ),
                        Container(width: 2, height: 28, color: const Color(0xFF2ECC71)),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('PICKUP: ${widget.trip.millName}', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                              Text(
                                _currentStage.index >= TripStage.headingToCustomer.index ? '✅ PICKED' : 'PENDING',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: _currentStage.index >= TripStage.headingToCustomer.index ? const Color(0xFF2ECC71) : const Color(0xFFF1C40F),
                                ),
                              ),
                            ],
                          ),
                          Text(widget.trip.millAddress, style: GoogleFonts.plusJakartaSans(fontSize: 10, color: Colors.white60), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),

                // Sequential Stops Nodes
                ..._tripStops.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final stop = entry.value;
                  final isCurrent = idx == _currentStopIndex && (_currentStage == TripStage.headingToCustomer || _currentStage == TripStage.atCustomerDelivery);
                  final isDone = stop.isDelivered;
                  final isLast = idx == _tripStops.length - 1;

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDone
                                  ? const Color(0xFF1E8449)
                                  : isCurrent
                                      ? const Color(0xFF2980B9)
                                      : Colors.grey[800],
                              border: Border.all(
                                color: isCurrent ? const Color(0xFF2ECC71) : Colors.transparent,
                                width: isCurrent ? 2 : 0,
                              ),
                            ),
                            child: isDone
                                ? const Icon(Icons.check, size: 12, color: Colors.white)
                                : Text('${idx + 1}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                          if (!isLast)
                            Container(
                              width: 2,
                              height: 28,
                              color: isDone ? const Color(0xFF1E8449) : Colors.white24,
                            ),
                        ],
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'STOP ${idx + 1}: ${stop.customerName}',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: isCurrent ? const Color(0xFF2ECC71) : Colors.white,
                                    fontSize: 11,
                                    fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  isDone ? '✅ DELIVERED' : isCurrent ? '📍 CURRENT' : 'QUEUED',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: isDone
                                        ? const Color(0xFF2ECC71)
                                        : isCurrent
                                            ? const Color(0xFF2980B9)
                                            : Colors.white38,
                                  ),
                                ),
                              ],
                            ),
                            if (stop.homePickupAddress.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                '🏠 Pickup Home: ${stop.homePickupAddress}',
                                style: GoogleFonts.plusJakartaSans(fontSize: 10, color: const Color(0xFF38BDF8), fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 2),
                            Text(
                              '🏡 Drop: ${stop.deliveryAddress}',
                              style: GoogleFonts.plusJakartaSans(fontSize: 10, color: Colors.white60),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                          ],
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationHUDCard() {
    final trafficColor = _trafficCondition == 'CLEAR'
        ? const Color(0xFF2ECC71)
        : _trafficCondition == 'MODERATE'
            ? const Color(0xFFF39C12)
            : const Color(0xFFE74C3C);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Next Turn Banner
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryTerracotta,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_currentTurnIcon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentTurnInstruction,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: trafficColor),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Traffic: $_trafficCondition',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 14),

          // Speedometer & Distance ETA HUD
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(
                    '$_currentSpeedKmH',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF2ECC71),
                    ),
                  ),
                  Text('km/h Speed', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: Colors.white60)),
                ],
              ),
              Container(width: 1, height: 32, color: Colors.white24),
              Column(
                children: [
                  Text(
                    '${(_distanceMeters / 1000).toStringAsFixed(1)} km',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  Text('Distance Left', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: Colors.white60)),
                ],
              ),
              Container(width: 1, height: 32, color: Colors.white24),
              Column(
                children: [
                  Text(
                    '${(_etaSeconds / 60).ceil()} min',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFFF1C40F),
                    ),
                  ),
                  Text('Est. Arrival', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: Colors.white60)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Launch Google Maps Button
          SizedBox(
            width: double.infinity,
            height: 42,
            child: OutlinedButton.icon(
              onPressed: _launchGoogleMaps,
              icon: const Icon(Icons.navigation_outlined, size: 16, color: Colors.white),
              label: Text(
                'Open Turn-by-Turn in Google Maps',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white38),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimulationControlHUD() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
              const Icon(Icons.bolt_rounded, size: 18, color: Color(0xFFB7791F)),
              const SizedBox(width: 6),
              Text(
                'Live Sim Fast-Forward:',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
            ],
          ),
          InkWell(
            onTap: () {
              setState(() {
                if (_currentStage == TripStage.headingToMill) {
                  _currentStage = TripStage.atMillPickup;
                } else if (_currentStage == TripStage.headingToCustomer) {
                  _currentStage = TripStage.atCustomerDelivery;
                }
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFF3ECE1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '⚡ Jump to Arrived',
                style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF6E5616)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMillPickupSection() {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.storefront_rounded, color: AppTheme.primaryTerracotta),
                  const SizedBox(width: 8),
                  Text(
                    'Mill Handover (${_tripStops.length} Bags)',
                    style: GoogleFonts.playfairDisplay(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () => _callParty(widget.trip.millPhone, widget.trip.millName),
                    icon: const Icon(Icons.call_outlined, color: Color(0xFF1E8449), size: 20),
                  ),
                  IconButton(
                    onPressed: () => _openWhatsAppHelper(widget.trip.millName, widget.trip.millPhone),
                    icon: const Icon(Icons.chat_outlined, color: Color(0xFF2ECC71), size: 20),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(widget.trip.millName, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14)),
          Text(widget.trip.millAddress, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary)),
          const SizedBox(height: 14),

          // 1. Home Grain Pickup Addresses (Origin)
          Text('1. Customer Home Grain Pickup Origin:', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 8),
          ..._tripStops.map((stop) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFBAE6FD)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.home_rounded, size: 14, color: Color(0xFF0369A1)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${stop.customerName} (${stop.quantityKg} kg ${stop.grainTypeName})',
                                style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF0369A1)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _callParty(stop.customerPhone, stop.customerName),
                        icon: const Icon(Icons.call_outlined, color: Color(0xFF0369A1), size: 16),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    stop.homePickupAddress,
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                  ),
                  if (stop.homePickupLandmark != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Landmark: ${stop.homePickupLandmark}',
                      style: GoogleFonts.plusJakartaSans(fontSize: 10, color: const Color(0xFF334155), fontWeight: FontWeight.w500),
                    ),
                  ],
                  if (stop.homePickupInstructions != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '📝 Pickup Note: "${stop.homePickupInstructions}"',
                      style: GoogleFonts.plusJakartaSans(fontSize: 10, color: const Color(0xFF475569), fontStyle: FontStyle.italic),
                    ),
                  ],
                ],
              ),
            );
          }),
          const SizedBox(height: 12),

          // 2. Per-Order Specific Bags to Scan & Pick Up
          Text('2. Scan & Verify Mill Flour Bags:', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 8),
          ..._tripStops.map((stop) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: stop.isPickedUp ? const Color(0xFFE8F8F5) : const Color(0xFFFAF6F0),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: stop.isPickedUp ? const Color(0xFF2ECC71) : const Color(0xFFECE4D9),
                  width: stop.isPickedUp ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    stop.isPickedUp ? Icons.check_circle_rounded : Icons.inventory_2_outlined,
                    color: stop.isPickedUp ? const Color(0xFF1E8449) : const Color(0xFF6E5616),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${stop.orderNumber} • ${stop.quantityKg} kg ${stop.grainTypeName}',
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        Text(
                          'For ${stop.customerName} • Tag: ${stop.barcodeNumber}',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _openPerOrderBarcodeScanner(stop, isPickup: true),
                    icon: Icon(stop.isPickedUp ? Icons.check : Icons.qr_code_scanner_rounded, size: 14, color: Colors.white),
                    label: Text(stop.isPickedUp ? 'Scanned' : 'Scan Bag', style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: stop.isPickedUp ? const Color(0xFF1E8449) : const Color(0xFF6E5616),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),

          // Bag Checklist
          Text('Quality & Safety Checklist:', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12)),
          CheckboxListTile(
            value: _isBagSealed,
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text('Eco-friendly Bag Seals Intact', style: GoogleFonts.plusJakartaSans(fontSize: 12)),
            onChanged: (val) => setState(() => _isBagSealed = val ?? true),
          ),
          CheckboxListTile(
            value: _isMoistureChecked,
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text('Moisture Barrier Confirmed Dry', style: GoogleFonts.plusJakartaSans(fontSize: 12)),
            onChanged: (val) => setState(() => _isMoistureChecked = val ?? true),
          ),
          CheckboxListTile(
            value: _isWeightVerified,
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text('Total weight verified (${widget.trip.quantityKg} kg)', style: GoogleFonts.plusJakartaSans(fontSize: 12)),
            onChanged: (val) => setState(() => _isWeightVerified = val ?? true),
          ),
          const SizedBox(height: 10),

          // 4-Digit Mill Pickup PIN
          TextField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: '4-Digit Mill Pickup Master PIN',
              hintText: 'e.g. 4821',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),

          // Confirm Pickup Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _handleConfirmPickup,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E8449),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isProcessing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'CONFIRM PICKUP & START MULTI-STOP ROUTE',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerDeliverySection() {
    final stop = _activeStop;
    final isBagScanned = stop.isDelivered;

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
          // Stop Header & Customer Contact
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.home_work_rounded, color: Color(0xFF1E8449)),
                  const SizedBox(width: 8),
                  Text(
                    'Stop ${_currentStopIndex + 1} of ${_tripStops.length}: Doorstep Drop',
                    style: GoogleFonts.playfairDisplay(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () => _callParty(stop.customerPhone, stop.customerName),
                    icon: const Icon(Icons.call_outlined, color: Color(0xFF1E8449), size: 20),
                    tooltip: 'Call Customer',
                  ),
                  IconButton(
                    onPressed: () => _openWhatsAppHelper(stop.customerName, stop.customerPhone),
                    icon: const Icon(Icons.chat_outlined, color: Color(0xFF2ECC71), size: 20),
                    tooltip: 'WhatsApp Help',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('${stop.orderNumber} • ${stop.customerName}', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14)),
          Text(stop.deliveryAddress, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary)),
          if (stop.customerNotes != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFF6AD55)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.comment_outlined, size: 14, color: Color(0xFFB7791F)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text('Customer Note: "${stop.customerNotes}"', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFFB7791F), fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),

          // STEP 1: Prominent Scan Customer Bag Barcode Card
          Text('Step 1: Scan Bag Barcode at Doorstep:', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isBagScanned ? const Color(0xFFE8F8F5) : const Color(0xFFFAF6F0),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isBagScanned ? const Color(0xFF2ECC71) : const Color(0xFFE2D9CC),
                width: isBagScanned ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isBagScanned ? Icons.check_circle_rounded : Icons.qr_code_scanner_rounded,
                          color: isBagScanned ? const Color(0xFF1E8449) : AppTheme.primaryTerracotta,
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isBagScanned ? '✅ Bag Barcode Verified' : 'Scan Bag to Confirm Drop',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isBagScanned ? const Color(0xFF1E8449) : AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              'Expected Tag: ${stop.barcodeNumber} (${stop.quantityKg} kg)',
                              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: () => _openPerOrderBarcodeScanner(stop, isPickup: false),
                    icon: Icon(isBagScanned ? Icons.check_rounded : Icons.camera_alt_rounded, size: 18, color: Colors.white),
                    label: Text(
                      isBagScanned ? 'RE-SCAN BAG BARCODE' : '📷 OPEN CAMERA TO SCAN BAG',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isBagScanned ? const Color(0xFF1E8449) : AppTheme.primaryTerracotta,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // STEP 2: Proof of Delivery Actions
          Text('Step 2: Proof of Delivery Handover (Optional):', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _simulateDoorstepPhoto,
                  icon: Icon(_hasDoorstepPhoto ? Icons.check_circle : Icons.camera_alt_outlined, size: 16, color: _hasDoorstepPhoto ? const Color(0xFF1E8449) : AppTheme.primaryTerracotta),
                  label: Text(_hasDoorstepPhoto ? 'Photo Added' : 'Take Photo', style: GoogleFonts.plusJakartaSans(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: _hasDoorstepPhoto ? const Color(0xFF1E8449) : AppTheme.borderLight),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _simulateCustomerSignature,
                  icon: Icon(_hasCustomerSignature ? Icons.check_circle : Icons.draw_outlined, size: 16, color: _hasCustomerSignature ? const Color(0xFF1E8449) : const Color(0xFF6E5616)),
                  label: Text(_hasCustomerSignature ? 'Signed' : 'Get Sign', style: GoogleFonts.plusJakartaSans(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: _hasCustomerSignature ? const Color(0xFF1E8449) : AppTheme.borderLight),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // STEP 3: 4-Digit Customer Delivery OTP
          Text('Step 3: Customer Delivery OTP:', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 6),
          TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: '4-Digit Delivery OTP',
              hintText: 'e.g. ${stop.deliveryOtp} (Master: 7391)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),

          // Primary Confirm Drop Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isProcessing
                  ? null
                  : () {
                      if (!isBagScanned) {
                        _openPerOrderBarcodeScanner(stop, isPickup: false);
                      } else {
                        _handleConfirmDelivery();
                      }
                    },
              icon: Icon(isBagScanned ? Icons.check_circle_rounded : Icons.qr_code_scanner_rounded, color: Colors.white, size: 20),
              label: _isProcessing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      !isBagScanned
                          ? '📷 SCAN BAG & CONFIRM DROP'
                          : (_currentStopIndex < _tripStops.length - 1
                              ? 'CONFIRM DROP & PROCEED TO STOP ${_currentStopIndex + 2}'
                              : 'CONFIRM DROP & COMPLETE TRIP'),
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isBagScanned ? const Color(0xFF1E8449) : AppTheme.primaryTerracotta,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../models/merchant_models.dart';
import '../../services/delivery_api_service.dart';
import '../../services/merchant_api_service.dart';

enum TripStage {
  headingToCustomer,
  atCustomerPickup,
  headingToMill,
  atMillPickup,
  atMillDelivery,
  atCustomerDelivery,
  returningToCustomer,
  atCustomerReturn,
  returningToMill,
  atMillReturn,
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
  late List<ProductBagItem> _productBags;
  int _currentStopIndex = 0;
  bool _isFlashlightOn = false;

  // Mill Inspection & Leg 1 Return State
  bool _isRejectedAtMill = false;
  String _millRejectionReason = '';
  Timer? _inspectionPollTimer;
  bool _isCheckingInspectionStatus = false;
  final Set<String> _scannedMillBags = {};

  bool get _allMillBagsScanned =>
      _productBags.isNotEmpty && _scannedMillBags.length >= _productBags.length;

  // Customer Quality Inspection & Leg 2 Return State
  bool _isRejectedAtDoorstep = false;
  String _customerRejectionReason = '';
  final Set<String> _scannedCustomerBags = {};

  bool get _allCustomerBagsScanned {
    final currentStopBags = _productBags.where((b) => b.orderId == _activeStop.orderId).toList();
    return currentStopBags.isNotEmpty && _scannedCustomerBags.length >= currentStopBags.length;
  }

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
    _productBags = List.from(widget.trip.productBags);
    _pinController.text = widget.trip.pickupPin;
    _otpController.text = _activeStop.deliveryOtp;
    _isRejectedAtMill = widget.trip.isReturnToCustomer;
    _millRejectionReason = widget.trip.rejectionReason ?? '';
    _isRejectedAtDoorstep = widget.trip.isReturnToMill;
    _customerRejectionReason = widget.trip.rejectionReason ?? '';

    if (_isRejectedAtMill) {
      _currentStage = TripStage.returningToCustomer;
    } else if (_isRejectedAtDoorstep) {
      _currentStage = TripStage.returningToMill;
    } else if (widget.trip.isLeg1GrainPickup) {
      _currentStage = TripStage.headingToCustomer;
    } else {
      _currentStage = TripStage.headingToMill;
    }

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scannerLaserController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _startRealtimeNavigationSimulation();

    if (widget.trip.isLeg1GrainPickup &&
        (_currentStage == TripStage.atMillDelivery ||
            _currentStage == TripStage.atCustomerDelivery ||
            _currentStage == TripStage.atMillPickup)) {
      _startMerchantInspectionPolling();
    }
  }

  @override
  void dispose() {
    _navSimulationTimer?.cancel();
    _inspectionPollTimer?.cancel();
    _pulseController.dispose();
    _scannerLaserController.dispose();
    _pinController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _startMerchantInspectionPolling() {
    _inspectionPollTimer?.cancel();
    _inspectionPollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_currentStage != TripStage.atCustomerDelivery &&
          _currentStage != TripStage.atMillPickup &&
          _currentStage != TripStage.atMillDelivery) {
        timer.cancel();
        return;
      }
      _checkMerchantInspectionStatus(isAutomaticPoll: true);
    });
  }

  Future<void> _checkMerchantInspectionStatus({bool isAutomaticPoll = false}) async {
    if (_isCheckingInspectionStatus && !isAutomaticPoll) return;
    if (!isAutomaticPoll && mounted) {
      setState(() => _isCheckingInspectionStatus = true);
    }

    try {
      final orderData = await DeliveryApiService.instance.getDeliveryOrderById(_activeStop.orderId);
      if (orderData != null && orderData['order'] != null) {
        final orderMap = orderData['order'] as Map<String, dynamic>;
        final status = (orderMap['status'] ?? '').toString().toUpperCase();
        final intakeStatus = (orderMap['intake_status'] ?? orderMap['intakeStatus'] ?? '').toString().toUpperCase();
        final deliveryStatus = (orderMap['delivery_status'] ?? orderMap['deliveryStatus'] ?? '').toString().toUpperCase();
        final rejectionReason = (orderMap['rejection_reason'] ?? orderMap['rejectionReason'] ?? '').toString();

        if (status == 'REJECTED_AT_MILL' ||
            status == 'RETURN_TO_CUSTOMER' ||
            intakeStatus == 'REJECTED' ||
            deliveryStatus == 'RETURN_TO_CUSTOMER') {
          _inspectionPollTimer?.cancel();
          if (mounted) {
            _resetNavigationForReturnStage(
              rejectionReason.isNotEmpty ? rejectionReason : 'Grain quality inspection rejected at mill',
            );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('⚠️ Mill Rejected Grain! Return leg activated back to Customer Doorstep.'),
                backgroundColor: Color(0xFFC0392B),
                duration: Duration(seconds: 4),
              ),
            );
          }
          return;
        }

        // If merchant verified in backend or marked ready, record bags as scanned
        if (intakeStatus == 'ACCEPTED' || status == 'READY' || status == 'READY_FOR_PICKUP') {
          if (mounted) {
            setState(() {
              _scannedMillBags.addAll(_productBags.map((b) => b.bagId));
            });
          }
        }

        // STRICT REQUIREMENT: Only complete Leg 1 when ALL products are scanned & verified by mill!
        if (_allMillBagsScanned) {
          _inspectionPollTimer?.cancel();
          if (mounted) {
            setState(() {
              _currentStage = TripStage.completed;
              _isProcessing = false;
            });
            _navSimulationTimer?.cancel();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Mill Owner Verified & Accepted All Grain Bags! Leg 1 Complete.'),
                backgroundColor: Color(0xFF1E8449),
                duration: Duration(seconds: 4),
              ),
            );
            _showGrainDropCompletionDialog();
          }
          return;
        }
      }
    } catch (_) {
      // Ignore network flutter
    } finally {
      if (mounted && !isAutomaticPoll) {
        setState(() => _isCheckingInspectionStatus = false);
      }
    }
  }

  Future<void> _simulateMerchantDecision(bool isAccepted, {String? reason}) async {
    setState(() => _isProcessing = true);
    try {
      if (isAccepted) {
        setState(() {
          _scannedMillBags.addAll(_productBags.map((b) => b.bagId));
        });
        await MerchantApiService.instance.submitGrainIntakeInspection(
          _activeStop.orderId,
          isAccepted: true,
          notes: 'Verified and approved at mill intake by shopkeeper',
          bagDecisions: _productBags.map((b) => {'bagId': b.bagId, 'isAccepted': true}).toList(),
        );
        try {
          await DeliveryApiService.instance.confirmGrainDropAtMill(_activeStop.orderId);
          if (widget.trip.isBatch) {
            for (final stop in _tripStops) {
              if (stop.orderId != _activeStop.orderId) {
                await DeliveryApiService.instance.confirmGrainDropAtMill(stop.orderId);
              }
            }
          }
        } catch (_) {}
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Merchant scanned & verified all ${_productBags.length} grain bags! Leg 1 Grain Drop Completed.'),
              backgroundColor: const Color(0xFF1E8449),
              duration: const Duration(seconds: 2),
            ),
          );
        }

        // Leg 1 Grain Drop is Complete! Show completion dialog & pop back to trip sheet
        setState(() {
          _currentStage = TripStage.completed;
          _isProcessing = false;
        });
        _navSimulationTimer?.cancel();
        _inspectionPollTimer?.cancel();
        _showGrainDropCompletionDialog();
        return;
      } else {
        final rejectReason = reason ?? 'Grain moisture > 16% & foreign impurities found';
        await MerchantApiService.instance.submitGrainIntakeInspection(
          _activeStop.orderId,
          isAccepted: false,
          reason: rejectReason,
          notes: 'Rejected by shopkeeper during grain intake quality scan',
        );
        _resetNavigationForReturnStage(rejectReason);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Simulation error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
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
              _currentTurnInstruction = widget.trip.isLeg1GrainPickup
                  ? 'In 80m, arrive at ${widget.trip.millName} to drop raw grain'
                  : 'In 80m, destination on your left (${widget.trip.millName})';
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
              _currentTurnInstruction = widget.trip.isLeg1GrainPickup
                  ? 'Turn left towards Stop ${_currentStopIndex + 1} (${_activeStop.customerName}) for Grain Pickup'
                  : 'Turn left towards Stop ${_currentStopIndex + 1} (${_activeStop.customerName}) for Flour Delivery';
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
      } else if (_currentStage == TripStage.returningToCustomer) {
        setState(() {
          if (_routeProgress < 0.95) {
            _routeProgress += 0.07;
            _distanceMeters = (_distanceMeters - 90).clamp(30, 4000);
            _etaSeconds = (_etaSeconds - 18).clamp(10, 900);
            _currentSpeedKmH = 32 + (_routeProgress * 12).toInt() % 10;

            if (_routeProgress > 0.7) {
              _currentTurnInstruction = 'Turn left towards ${_activeStop.customerName} doorstep for Return Handover';
              _currentTurnIcon = Icons.turn_left_rounded;
            } else if (_routeProgress > 0.4) {
              _currentTurnInstruction = 'Return route: Head back via SG Highway to ${_activeStop.customerName}';
              _currentTurnIcon = Icons.u_turn_left_rounded;
              _trafficCondition = 'CLEAR';
            } else {
              _currentTurnInstruction = 'Returning raw grain: Head straight towards customer address';
              _currentTurnIcon = Icons.straight_rounded;
              _trafficCondition = 'MODERATE';
            }
          } else {
            _distanceMeters = 15;
            _etaSeconds = 0;
            _currentTurnInstruction = 'Arrived back at Customer Doorstep (${_activeStop.customerName}) for Return Handover';
            _currentTurnIcon = Icons.check_circle_rounded;
          }
        });
      } else if (_currentStage == TripStage.returningToMill) {
        setState(() {
          if (_routeProgress < 0.95) {
            _routeProgress += 0.07;
            _distanceMeters = (_distanceMeters - 90).clamp(30, 4000);
            _etaSeconds = (_etaSeconds - 18).clamp(10, 900);
            _currentSpeedKmH = 32 + (_routeProgress * 12).toInt() % 10;

            if (_routeProgress > 0.7) {
              _currentTurnInstruction = 'Turn right towards ${widget.trip.millName} for Return Handover';
              _currentTurnIcon = Icons.turn_right_rounded;
            } else if (_routeProgress > 0.4) {
              _currentTurnInstruction = 'Return route: Head back to ${widget.trip.millName} via Ring Road';
              _currentTurnIcon = Icons.u_turn_left_rounded;
              _trafficCondition = 'CLEAR';
            } else {
              _currentTurnInstruction = 'Returning rejected flour: Head straight towards mill';
              _currentTurnIcon = Icons.straight_rounded;
              _trafficCondition = 'MODERATE';
            }
          } else {
            _distanceMeters = 15;
            _etaSeconds = 0;
            _currentTurnInstruction = 'Arrived back at ${widget.trip.millName} for Return Handover';
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
      _currentTurnInstruction = widget.trip.isLeg1GrainPickup
          ? 'Head towards Stop ${_currentStopIndex + 1} (${_activeStop.customerName}) for Grain Pickup'
          : 'Head towards Stop ${_currentStopIndex + 1} (${_activeStop.customerName}) for Flour Delivery';
      _currentTurnIcon = Icons.straight_rounded;
      _trafficCondition = 'CLEAR';
      _otpController.text = _activeStop.deliveryOtp;
    });
  }

  void _resetNavigationForReturnStage(String reason) {
    setState(() {
      _isRejectedAtMill = true;
      _millRejectionReason = reason;
      _currentStage = TripStage.returningToCustomer;
      _routeProgress = 0.10;
      _distanceMeters = 1750;
      _etaSeconds = 420;
      _currentSpeedKmH = 32;
      _currentTurnInstruction = 'U-Turn from ${widget.trip.millName} - Returning rejected grain to ${_activeStop.customerName}';
      _currentTurnIcon = Icons.u_turn_left_rounded;
      _trafficCondition = 'CLEAR';
    });
  }

  void _resetNavigationForReturnToMillStage(String reason) {
    setState(() {
      _isRejectedAtDoorstep = true;
      _customerRejectionReason = reason;
      _currentStage = TripStage.returningToMill;
      _routeProgress = 0.10;
      _distanceMeters = 1850;
      _etaSeconds = 450;
      _currentSpeedKmH = 32;
      _currentTurnInstruction = 'U-Turn from ${_activeStop.customerName} Doorstep - Returning rejected flour to ${widget.trip.millName}';
      _currentTurnIcon = Icons.u_turn_left_rounded;
      _trafficCondition = 'CLEAR';
    });
  }

  Future<void> _launchGoogleMaps() async {
    final bool isMillDestination =
        _currentStage == TripStage.headingToMill ||
        _currentStage == TripStage.atMillPickup ||
        _currentStage == TripStage.atMillDelivery ||
        _currentStage == TripStage.returningToMill ||
        _currentStage == TripStage.atMillReturn;

    final destination = isMillDestination
        ? '${widget.trip.millName}, ${widget.trip.millAddress}'
        : '${_activeStop.customerName}, ${_activeStop.homePickupAddress.isNotEmpty ? _activeStop.homePickupAddress : _activeStop.deliveryAddress}';

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
            _buildQuickTemplateTile('📦 Main gate par khada hoon, kripya order receive karein.', name),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickTemplateTile(String msg, String name) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.send_rounded, size: 18, color: AppTheme.primaryTerracotta),
        title: Text(msg, style: GoogleFonts.plusJakartaSans(fontSize: 13)),
        onTap: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Message sent to $name via WhatsApp!')),
          );
        },
      ),
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
    return Material(
      color: Colors.transparent,
      child: ListTile(
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
      ),
    );
  }

  /// Product-Specific Dedicated QR & Barcode Camera Scanner Modal
  void _openProductBagBarcodeScanner(ProductBagItem initialBag, {bool isPickup = true}) {
    String selectedBagId = initialBag.bagId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF14181D),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final orderBags = _productBags.where((b) => b.orderId == initialBag.orderId).toList();
            final currentBag = orderBags.firstWhere(
              (b) => b.bagId == selectedBagId,
              orElse: () => orderBags.isNotEmpty ? orderBags.first : initialBag,
            );
            final isCurrentVerified = isPickup ? currentBag.isPickedUp : currentBag.isDelivered;

            return Container(
              padding: const EdgeInsets.all(20),
              height: MediaQuery.of(context).size.height * 0.86,
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
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2ECC71).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF2ECC71), size: 22),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isPickup ? 'Verify Product Flour Bag' : 'Doorstep Product Bag Scan',
                                style: GoogleFonts.playfairDisplay(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              Text(
                                '${currentBag.orderNumber} • ${currentBag.customerName}',
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
                  const SizedBox(height: 12),

                  // Horizontal Unit Bag Tabs (when multiple product bags exist)
                  if (orderBags.length > 1) ...[
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: orderBags.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final b = entry.value;
                          final isSelected = b.bagId == currentBag.bagId;
                          final isDone = isPickup ? b.isPickedUp : b.isDelivered;

                          return GestureDetector(
                            onTap: () {
                              setModalState(() {
                                selectedBagId = b.bagId;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF2ECC71).withValues(alpha: 0.25)
                                    : Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF2ECC71) : (isDone ? const Color(0xFF1E8449) : Colors.white24),
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isDone ? Icons.check_circle_rounded : Icons.inventory_2_outlined,
                                    size: 14,
                                    color: isDone ? const Color(0xFF2ECC71) : Colors.white70,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${idx + 1}. ${b.productName} • ${b.unitText}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isSelected ? Colors.white : Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Camera Viewfinder Box with Product-Specific QR Card
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isCurrentVerified ? const Color(0xFF1E8449) : const Color(0xFF2ECC71),
                          width: 2,
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Product QR Code Display Container
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isCurrentVerified
                                      ? const Color(0xFF1E8449).withValues(alpha: 0.25)
                                      : const Color(0xFF2ECC71).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isCurrentVerified ? 'BAG QR VERIFIED ✓' : 'PRODUCT SPECIFIC QR',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: isCurrentVerified ? const Color(0xFF2ECC71) : const Color(0xFF2ECC71),
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF2ECC71).withValues(alpha: 0.3),
                                      blurRadius: 16,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    const Icon(
                                      Icons.qr_code_2_rounded,
                                      size: 130,
                                      color: Color(0xFF14181D),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: const Color(0xFF2ECC71), width: 1.5),
                                      ),
                                      child: Icon(
                                        isCurrentVerified ? Icons.check_circle_rounded : Icons.grain_rounded,
                                        color: isCurrentVerified ? const Color(0xFF1E8449) : const Color(0xFF8B4513),
                                        size: 18,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      '${currentBag.productName} • ${currentBag.unitText}',
                                      style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Tag: ${currentBag.bagId}',
                                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF2ECC71), fontWeight: FontWeight.w800),
                                    ),
                                  ],
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
                  const SizedBox(height: 12),

                  // Order Product Information Card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E242B),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isCurrentVerified ? Icons.check_circle : Icons.grain_rounded,
                          color: isCurrentVerified ? const Color(0xFF2ECC71) : const Color(0xFFF1C40F),
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${currentBag.productName} • ${currentBag.unitText}',
                                style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              Text(
                                isPickup ? 'Mill: ${widget.trip.millName}' : 'Deliver: ${currentBag.deliveryAddress}',
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
                  const SizedBox(height: 12),

                  // Confirm Scan Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                final bIdx = _productBags.indexWhere((b) => b.bagId == currentBag.bagId);
                                if (bIdx != -1) {
                                  _productBags[bIdx] = isPickup
                                      ? _productBags[bIdx].copyWith(isPickedUp: true)
                                      : _productBags[bIdx].copyWith(isDelivered: true);
                                }
                                final stopBags = _productBags.where((b) => b.orderId == currentBag.orderId).toList();
                                final allDone = isPickup
                                    ? stopBags.every((b) => b.isPickedUp)
                                    : stopBags.every((b) => b.isDelivered);
                                if (allDone) {
                                  final sIdx = _tripStops.indexWhere((s) => s.orderId == currentBag.orderId);
                                  if (sIdx != -1) {
                                    _tripStops[sIdx] = isPickup
                                        ? _tripStops[sIdx].copyWith(isPickedUp: true)
                                        : _tripStops[sIdx].copyWith(isDelivered: true);
                                  }
                                }
                                if (isPickup && currentBag.pickupPin.isNotEmpty) {
                                  _pinController.text = currentBag.pickupPin;
                                } else if (!isPickup && currentBag.deliveryOtp.isNotEmpty) {
                                  _otpController.text = currentBag.deliveryOtp;
                                }
                              });

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('✅ Scanned & Verified: ${currentBag.productName} (${currentBag.bagId})!'),
                                  backgroundColor: const Color(0xFF1E8449),
                                  duration: const Duration(seconds: 2),
                                ),
                              );

                              // Check if there is another unverified bag in this order
                              final remainingBags = _productBags.where((b) {
                                return b.orderId == currentBag.orderId &&
                                    (isPickup ? !b.isPickedUp : !b.isDelivered);
                              }).toList();

                              if (remainingBags.isNotEmpty) {
                                // Automatically switch to next unverified bag so driver can scan it immediately
                                setModalState(() {
                                  selectedBagId = remainingBags.first.bagId;
                                });
                              } else {
                                // All bags verified for this order, close modal
                                Navigator.pop(modalCtx);
                              }
                            },
                            icon: Icon(isCurrentVerified ? Icons.check_circle_rounded : Icons.qr_code_scanner_rounded, color: Colors.white, size: 18),
                            label: Text(
                              isCurrentVerified
                                  ? 'VERIFIED ✓ (${currentBag.bagId})'
                                  : 'SCAN THIS BAG (${currentBag.bagId})',
                              style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isCurrentVerified ? const Color(0xFF1E8449) : const Color(0xFF6E5616),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 4,
                            ),
                          ),
                        ),
                      ),
                      if (orderBags.length > 1) ...[
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                for (final b in orderBags) {
                                  final bIdx = _productBags.indexWhere((x) => x.bagId == b.bagId);
                                  if (bIdx != -1) {
                                    _productBags[bIdx] = isPickup
                                        ? _productBags[bIdx].copyWith(isPickedUp: true)
                                        : _productBags[bIdx].copyWith(isDelivered: true);
                                  }
                                }
                                final sIdx = _tripStops.indexWhere((s) => s.orderId == currentBag.orderId);
                                if (sIdx != -1) {
                                  _tripStops[sIdx] = isPickup
                                      ? _tripStops[sIdx].copyWith(isPickedUp: true)
                                      : _tripStops[sIdx].copyWith(isDelivered: true);
                                }
                                if (isPickup && currentBag.pickupPin.isNotEmpty) {
                                  _pinController.text = currentBag.pickupPin;
                                } else if (!isPickup && currentBag.deliveryOtp.isNotEmpty) {
                                  _otpController.text = currentBag.deliveryOtp;
                                }
                              });
                              Navigator.pop(modalCtx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('✅ Verified all ${orderBags.length} product bags!'),
                                  backgroundColor: const Color(0xFF1E8449),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2ECC71),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                            ),
                            child: Text(
                              'ALL (${orderBags.length})',
                              style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
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
        // Mark all product bags and stops picked up
        _productBags = _productBags.map((b) => b.copyWith(isPickedUp: true)).toList();
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

  Future<void> _handleConfirmLeg1CustomerPickup() async {
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
      _activeStop.orderId,
      pin: effectivePin,
    );

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (res['success'] == true) {
      final idx = _currentStopIndex;
      if (idx < _tripStops.length) {
        _tripStops[idx] = _tripStops[idx].copyWith(isPickedUp: true);
      }
      _productBags = _productBags.map((b) {
        if (b.orderId == _activeStop.orderId) {
          return b.copyWith(isPickedUp: true);
        }
        return b;
      }).toList();

      if (_currentStopIndex < _tripStops.length - 1) {
        // Advance to next customer stop in group batch
        setState(() {
          _currentStopIndex++;
          _currentStage = TripStage.headingToCustomer;
          _resetNavigationForCustomerStage();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Grain collected for Stop $_currentStopIndex! Heading to Stop ${_currentStopIndex + 1} (${_activeStop.customerName}).'),
            backgroundColor: const Color(0xFF1E8449),
          ),
        );
      } else {
        // All customer stops collected -> proceed to mill!
        setState(() {
          _currentStage = TripStage.headingToMill;
          _routeProgress = 0.10;
          _distanceMeters = 1850;
          _etaSeconds = 380;
          _currentSpeedKmH = 34;
          _currentTurnInstruction = 'All grain bags collected! Head towards ${widget.trip.millName}';
          _currentTurnIcon = Icons.straight_rounded;
          _trafficCondition = 'CLEAR';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ All grain bags collected! Navigating to ${widget.trip.millName} for drop-off & inspection.'),
            backgroundColor: const Color(0xFF1E8449),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Customer grain pickup failed'),
          backgroundColor: const Color(0xFFC0392B),
        ),
      );
    }
  }

  Future<void> _handleConfirmDelivery() async {
    final isLeg1GrainDrop = widget.trip.isHomeGrainPickup;

    if (isLeg1GrainDrop) {
      // ── Leg 1: Driver drops raw grain at the mill ──
      // Check live status from merchant app first
      setState(() => _isProcessing = true);
      await _checkMerchantInspectionStatus(isAutomaticPoll: false);
      if (mounted) {
        setState(() => _isProcessing = false);
      }

      // STRICT REQUIREMENT: Hold at this stage until ALL products are scanned by mill owner!
      if (!_allMillBagsScanned) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '⏳ Mill Inspection on Hold: ${_scannedMillBags.length}/${_productBags.length} bags scanned. The mill owner must inspect & scan all products before Leg 1 can be completed.',
              ),
              backgroundColor: const Color(0xFFD97706),
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      // STRICT CHECK PASSED: All bags are verified by merchant! Now confirm grain drop in backend:
      setState(() => _isProcessing = true);
      try {
        await DeliveryApiService.instance.confirmGrainDropAtMill(_activeStop.orderId);
        if (widget.trip.isBatch) {
          for (final stop in _tripStops) {
            if (stop.orderId != _activeStop.orderId) {
              await DeliveryApiService.instance.confirmGrainDropAtMill(stop.orderId);
            }
          }
        }
      } catch (_) {}

      // All bags are verified! Complete Leg 1:
      setState(() {
        _currentStage = TripStage.completed;
        _isProcessing = false;
      });
      _navSimulationTimer?.cancel();
      _inspectionPollTimer?.cancel();
      _showGrainDropCompletionDialog();
      return;
    }

    // ── Leg 2: Driver delivers milled flour to customer home ──
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

    if (res['success'] == true) {
      final idx = _currentStopIndex;
      if (idx < _tripStops.length) {
        _tripStops[idx] = _tripStops[idx].copyWith(isDelivered: true);
      }

      // If more stops exist in grouped trip, advance to next stop
      if (_currentStopIndex < _tripStops.length - 1) {
        setState(() {
          _isProcessing = false;
          _currentStopIndex++;
          _currentStage = TripStage.headingToCustomer;
          _hasDoorstepPhoto = false;
          _hasCustomerSignature = false;
          _resetNavigationForCustomerStage();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Stop $_currentStopIndex Complete! Navigating to Stop ${_currentStopIndex + 1} (${_activeStop.customerName}).'),
            backgroundColor: const Color(0xFF1E8449),
          ),
        );
      } else {
        // Last stop completed — confirm all stops and batch trip so backend removes them completely
        final List<Future> batchConfirmFutures = [];
        for (var stop in _tripStops) {
          batchConfirmFutures.add(
            DeliveryApiService.instance.confirmDelivery(
              stop.orderId,
              otp: effectiveOtp,
            ),
          );
        }
        if (widget.trip.isBatch) {
          batchConfirmFutures.add(
            DeliveryApiService.instance.confirmDelivery(
              widget.trip.orderId,
              otp: effectiveOtp,
            ),
          );
        }

        await Future.wait(batchConfirmFutures);

        if (!mounted) return;
        setState(() {
          _isProcessing = false;
          _currentStage = TripStage.completed;
        });
        _navSimulationTimer?.cancel();
        _showCompletionDialog();
      }
    } else {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Delivery confirmation failed'),
          backgroundColor: const Color(0xFFC0392B),
        ),
      );
    }
  }

  void _showGrainDropCompletionDialog() {
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
              decoration: BoxDecoration(
                color: const Color(0xFFE8F8F5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.grain_rounded, color: Color(0xFF1E8449), size: 38),
            ),
            const SizedBox(height: 16),
            Text(
              '🌾 Grain Delivered to Mill!',
              style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Raw grain has been handed over to the flour mill.\n\nThe shopkeeper will start milling. Once ready, a new delivery trip (Flour → Home) will appear on the radar.',
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFF9F5EF), borderRadius: BorderRadius.circular(12)),
              child: Text(
                '+₹${widget.trip.deliveryFee.toStringAsFixed(0)} Leg 1 Payout Credited',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF1E8449)),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryTerracotta,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              if (widget.onTripCompleted != null) {
                widget.onTripCompleted!();
              } else if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
            child: Text('Done', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleConfirmReturnToCustomer() async {
    setState(() => _isProcessing = true);

    final res = await DeliveryApiService.instance.confirmReturnToCustomer(
      _activeStop.orderId,
      reason: _millRejectionReason.isNotEmpty ? _millRejectionReason : 'Grain returned to customer doorstep by driver',
    );

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (res['success'] == true) {
      setState(() {
        _currentStage = TripStage.completed;
      });
      _navSimulationTimer?.cancel();
      _showReturnCompletionDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Return handover confirmation failed'),
          backgroundColor: const Color(0xFFC0392B),
        ),
      );
    }
  }

  void _showReturnCompletionDialog() {
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
                color: Color(0xFFFDEDEC),
              ),
              child: const Icon(Icons.assignment_return_rounded, size: 40, color: Color(0xFFC0392B)),
            ),
            const SizedBox(height: 16),
            Text(
              '🔄 Grain Returned to Customer!',
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Rejected raw grain has been safely handed back to ${_activeStop.customerName} at their doorstep.\n\nReason: "${_millRejectionReason.isNotEmpty ? _millRejectionReason : 'Quality inspection rejected by mill'}"',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F5EF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2D8C9)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Return Trip Compensation', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12)),
                  Text(
                    '+₹${(widget.trip.deliveryFee * 1.2).toStringAsFixed(0)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: const Color(0xFF1E8449),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryTerracotta,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                if (widget.onTripCompleted != null) {
                  widget.onTripCompleted!();
                } else if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
              child: Text('Close & Back to Radar', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleConfirmReturnToMill() async {
    setState(() => _isProcessing = true);

    final res = await DeliveryApiService.instance.confirmReturnToMill(
      _activeStop.orderId,
      reason: _customerRejectionReason.isNotEmpty ? _customerRejectionReason : 'Flour returned to mill by driver',
    );

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (res['success'] == true) {
      setState(() {
        _currentStage = TripStage.completed;
      });
      _navSimulationTimer?.cancel();
      _showMillReturnCompletionDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Return handover confirmation failed'),
          backgroundColor: const Color(0xFFC0392B),
        ),
      );
    }
  }

  void _showMillReturnCompletionDialog() {
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
                color: Color(0xFFFDEDEC),
              ),
              child: const Icon(Icons.assignment_return_rounded, size: 40, color: Color(0xFFC0392B)),
            ),
            const SizedBox(height: 16),
            Text(
              '🔄 Flour Returned to Mill!',
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Rejected flour has been safely returned to ${widget.trip.millName}.\n\nReason: "${_customerRejectionReason.isNotEmpty ? _customerRejectionReason : 'Quality inspection rejected by customer'}"',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F5EF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2D8C9)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Return Trip Compensation', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12)),
                  Text(
                    '+₹${(widget.trip.deliveryFee * 1.2).toStringAsFixed(0)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: const Color(0xFF1E8449),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryTerracotta,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                if (widget.onTripCompleted != null) {
                  widget.onTripCompleted!();
                } else if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
              child: Text('Close & Back to Radar', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
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
              'Trip ${widget.trip.orderNumber.startsWith('#') ? widget.trip.orderNumber : '#${widget.trip.orderNumber}'} Completed!',
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
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        // Exiting / returning to trip sheet NEVER completes the trip prematurely.
        // It strictly remains in active / on hold state until all products are scanned.
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Return to Trip Sheet',
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Trip ${widget.trip.orderNumber.startsWith('#') ? widget.trip.orderNumber : '#${widget.trip.orderNumber}'}',
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
              onPressed: _openOrderTimelineSheet,
              icon: const Icon(Icons.timeline_rounded, color: AppTheme.primaryTerracotta),
              tooltip: 'Order Timeline',
            ),
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

            // Quick Live Order Timeline Strip
            InkWell(
              onTap: _openOrderTimelineSheet,
              child: Container(
                margin: const EdgeInsets.fromLTRB(18, 10, 18, 2),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.borderLight),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryTerracotta.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.timeline_rounded, size: 16, color: AppTheme.primaryTerracotta),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Track Milestone History & Live Timeline',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          'View',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryTerracotta),
                        ),
                        const Icon(Icons.chevron_right_rounded, size: 16, color: AppTheme.primaryTerracotta),
                      ],
                    ),
                  ],
                ),
              ),
            ),

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
                      if (_currentStage == TripStage.headingToCustomer || _currentStage == TripStage.atCustomerPickup)
                        (widget.trip.isLeg1GrainPickup ? _buildLeg1CustomerPickupSection() : _buildLeg2CustomerDoorstepSection())
                      else if (_currentStage == TripStage.headingToMill || _currentStage == TripStage.atMillPickup)
                        (widget.trip.isLeg1GrainPickup ? _buildLeg1HeadingToMillSection() : _buildLeg2MillPickupSection())
                      else if (_currentStage == TripStage.atMillDelivery)
                        _buildLeg1MillDropSection()
                      else if (_currentStage == TripStage.atCustomerDelivery)
                        _buildLeg2CustomerDoorstepSection()
                      else if (_currentStage == TripStage.returningToCustomer || _currentStage == TripStage.atCustomerReturn)
                        _buildCustomerReturnSection()
                      else if (_currentStage == TripStage.returningToMill || _currentStage == TripStage.atMillReturn)
                        _buildMillReturnSection(),
                    ],

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
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
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (_isRejectedAtMill || _isRejectedAtDoorstep) ? const Color(0xFFFDEDEC) : const Color(0xFFE8F8F5),
            ),
            child: Icon(
              (_isRejectedAtMill || _isRejectedAtDoorstep) ? Icons.assignment_return_rounded : Icons.check_circle_rounded,
              size: 48,
              color: (_isRejectedAtMill || _isRejectedAtDoorstep) ? const Color(0xFFC0392B) : const Color(0xFF1E8449),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _isRejectedAtMill
                ? 'Grain Return Completed!'
                : (_isRejectedAtDoorstep
                    ? 'Flour Return Completed!'
                    : 'Trip ${widget.trip.orderNumber.startsWith('#') ? widget.trip.orderNumber : '#${widget.trip.orderNumber}'} Completed!'),
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _isRejectedAtMill
                ? 'Rejected grain bags safely returned to customer doorstep. Return payout added to your wallet.'
                : (_isRejectedAtDoorstep
                    ? 'Rejected flour bags safely returned to mill. Return payout added to your wallet.'
                    : 'All ${_tripStops.length} stop(s) successfully delivered. Payout added to your daily wallet.'),
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
                  (_isRejectedAtMill || _isRejectedAtDoorstep) ? 'Return Trip Compensation' : 'Total Payout Credited',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  (_isRejectedAtMill || _isRejectedAtDoorstep)
                      ? '+₹${(widget.trip.deliveryFee * 1.2).toStringAsFixed(0)}'
                      : '+₹${widget.trip.deliveryFee.toStringAsFixed(0)}',
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
    final bool isLeg1 = widget.trip.isLeg1GrainPickup;
    switch (_currentStage) {
      case TripStage.headingToCustomer:
        return isLeg1
            ? 'Leg 1: Heading to Stop ${_currentStopIndex + 1} (${_activeStop.customerName}) - Grain Pickup'
            : 'Leg 2: Heading to Stop ${_currentStopIndex + 1} (${_activeStop.customerName}) - Flour Delivery';
      case TripStage.atCustomerPickup:
        return 'Leg 1: At Stop ${_currentStopIndex + 1} (${_activeStop.customerName}) - Pick Up Raw Grain';
      case TripStage.headingToMill:
        return isLeg1
            ? 'Leg 1: Heading to Mill (${widget.trip.millName}) - Drop Grain'
            : 'Leg 2: Heading to Mill (${widget.trip.millName}) - Flour Pickup';
      case TripStage.atMillPickup:
        return 'Leg 2: At Mill (${widget.trip.millName}) - Pick Up Milled Flour';
      case TripStage.atMillDelivery:
        return 'Leg 1: At Mill (${widget.trip.millName}) - Shopkeeper Intake & Scan';
      case TripStage.atCustomerDelivery:
        return 'Leg 2: At Stop ${_currentStopIndex + 1} Doorstep - Drop at Home';
      case TripStage.returningToCustomer:
        return 'Leg 1 Return: Returning Rejected Grain to ${_activeStop.customerName}';
      case TripStage.atCustomerReturn:
        return 'Leg 1 Return: At Customer Doorstep - Return Handover';
      case TripStage.returningToMill:
        return 'Leg 2 Return: Returning Rejected Flour to ${widget.trip.millName}';
      case TripStage.atMillReturn:
        return 'Leg 2 Return: At Mill - Return Handover';
      case TripStage.completed:
        if (_isRejectedAtMill) return 'Leg 1 Return Completed (Grain Handed Back to Customer)';
        if (_isRejectedAtDoorstep) return 'Leg 2 Return Completed (Flour Handed Back to Mill)';
        return isLeg1 ? 'Leg 1 Completed (Grain Handed to Mill)' : 'Leg 2 Completed (Flour Delivered)';
    }
  }

  Widget _buildStageProgressBar() {
    final bool isLeg1 = widget.trip.isLeg1GrainPickup;
    final bool isReturningToCustomer = _isRejectedAtMill ||
        _currentStage == TripStage.returningToCustomer ||
        _currentStage == TripStage.atCustomerReturn;
    final bool isReturningToMill = _isRejectedAtDoorstep ||
        _currentStage == TripStage.returningToMill ||
        _currentStage == TripStage.atMillReturn;
    final bool isReturning = isReturningToCustomer || isReturningToMill;

    final List<Map<String, dynamic>> stages;

    if (isReturningToCustomer) {
      stages = [
        {
          'title': 'Accept',
          'done': true,
          'isHold': false,
          'isCurrent': false,
          'description': 'Trip accepted. Route started.',
        },
        {
          'title': 'Mill Drop',
          'done': true,
          'isHold': false,
          'isCurrent': false,
          'description': 'Arrived at mill and submitted grain bags for intake testing.',
        },
        {
          'title': 'Quality',
          'done': true,
          'isHold': false,
          'isCurrent': false,
          'isRejected': true,
          'description': 'Mill owner rejected grain quality. Return process initiated.',
        },
        {
          'title': 'Return Home',
          'done': _currentStage == TripStage.completed,
          'isHold': _currentStage == TripStage.returningToCustomer || _currentStage == TripStage.atCustomerReturn,
          'isCurrent': _currentStage == TripStage.returningToCustomer || _currentStage == TripStage.atCustomerReturn,
          'description': 'Returning rejected raw grain to customer doorstep.',
        },
        {
          'title': 'Done',
          'done': _currentStage == TripStage.completed,
          'isHold': false,
          'isCurrent': _currentStage == TripStage.completed,
          'description': 'Return leg complete. Grain handed back to customer.',
        },
      ];
    } else if (isReturningToMill) {
      stages = [
        {
          'title': 'Accept',
          'done': true,
          'isHold': false,
          'isCurrent': false,
          'description': 'Trip accepted. Route started.',
        },
        {
          'title': 'Mill Pick',
          'done': true,
          'isHold': false,
          'isCurrent': false,
          'description': 'Flour picked up from mill.',
        },
        {
          'title': 'Doorstep',
          'done': true,
          'isHold': false,
          'isCurrent': false,
          'description': 'Arrived at customer doorstep.',
        },
        {
          'title': 'Quality',
          'done': true,
          'isHold': false,
          'isCurrent': false,
          'isRejected': true,
          'description': 'Customer rejected flour quality. Return initiated.',
        },
        {
          'title': 'Return Mill',
          'done': _currentStage == TripStage.completed,
          'isHold': _currentStage == TripStage.returningToMill || _currentStage == TripStage.atMillReturn,
          'isCurrent': _currentStage == TripStage.returningToMill || _currentStage == TripStage.atMillReturn,
          'description': 'Returning rejected flour bags back to mill.',
        },
        {
          'title': 'Done',
          'done': _currentStage == TripStage.completed,
          'isHold': false,
          'isCurrent': _currentStage == TripStage.completed,
          'description': 'Return complete. Flour handed back to mill shopkeeper.',
        },
      ];
    } else if (isLeg1) {
      final bool pickDone = _currentStage != TripStage.headingToCustomer && _currentStage != TripStage.atCustomerPickup;
      final bool transitDone = pickDone && _currentStage != TripStage.headingToMill;
      final bool dropDone = transitDone && (_allMillBagsScanned || _currentStage == TripStage.completed);

      stages = [
        {
          'title': 'Accept',
          'done': true,
          'isHold': false,
          'isCurrent': false,
          'description': 'Trip accepted. Driver is on duty.',
        },
        {
          'title': 'Pick Grain',
          'done': pickDone,
          'isHold': _currentStage == TripStage.headingToCustomer || _currentStage == TripStage.atCustomerPickup,
          'isCurrent': _currentStage == TripStage.headingToCustomer || _currentStage == TripStage.atCustomerPickup,
          'description': 'Collecting raw grain bags from customer homes.',
        },
        {
          'title': 'To Mill',
          'done': transitDone,
          'isHold': _currentStage == TripStage.headingToMill,
          'isCurrent': _currentStage == TripStage.headingToMill,
          'description': 'Heading to flour mill with raw grain bags.',
        },
        {
          'title': 'Mill Scan',
          'done': dropDone,
          'isHold': _currentStage == TripStage.atMillDelivery && !_allMillBagsScanned,
          'isCurrent': _currentStage == TripStage.atMillDelivery,
          'description': 'At mill. Shopkeeper inspecting & scanning all grain bags.',
          'holdReason': 'Awaiting Shopkeeper Scan (${_scannedMillBags.length}/${_productBags.length} Verified)',
        },
        {
          'title': 'Done',
          'done': _currentStage == TripStage.completed && _allMillBagsScanned,
          'isHold': false,
          'isCurrent': _currentStage == TripStage.completed,
          'description': 'Leg 1 completed. Grain safely accepted at mill for grinding.',
        },
      ];
    } else {
      final bool pickDone = _currentStage != TripStage.headingToMill && _currentStage != TripStage.atMillPickup;
      final bool transitDone = pickDone && _currentStage != TripStage.headingToCustomer;
      final bool deliveryDone = _currentStage == TripStage.completed;

      stages = [
        {
          'title': 'Accept',
          'done': true,
          'isHold': false,
          'isCurrent': false,
          'description': 'Trip accepted. Route started.',
        },
        {
          'title': 'Mill Pick',
          'done': pickDone,
          'isHold': false,
          'isCurrent': _currentStage == TripStage.headingToMill || _currentStage == TripStage.atMillPickup,
          'description': 'Heading to flour mill to pick up milled flour bags.',
        },
        {
          'title': 'To Home',
          'done': transitDone,
          'isHold': false,
          'isCurrent': _currentStage == TripStage.headingToCustomer,
          'description': 'Delivering flour bags to customer doorstep.',
        },
        {
          'title': 'Doorstep',
          'done': deliveryDone,
          'isHold': false,
          'isCurrent': _currentStage == TripStage.atCustomerDelivery,
          'description': 'Drop off flour bags at customer doorstep.',
        },
        {
          'title': 'Done',
          'done': _currentStage == TripStage.completed,
          'isHold': false,
          'isCurrent': _currentStage == TripStage.completed,
          'description': 'Delivery complete. Customer received fresh flour.',
        },
      ];
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: List.generate(stages.length, (index) {
          final s = stages[index];
          final isDone = s['done'] == true;
          final isHold = s['isHold'] == true;
          final isCurrent = s['isCurrent'] == true;
          final isLast = index == stages.length - 1;

          // Connecting link between this step and the next step
          bool isLinkHold = false;
          bool isLinkDone = false;
          if (!isLast) {
            final nextS = stages[index + 1];
            isLinkHold = (nextS['isHold'] == true) || (isHold && !isDone);
            isLinkDone = isDone && (nextS['done'] == true);
          }

          final Color circleColor = isHold
              ? const Color(0xFFD97706)
              : (isDone
                  ? (isReturning ? const Color(0xFFC0392B) : const Color(0xFF1E8449))
                  : (isCurrent ? const Color(0xFF2563EB) : Colors.grey[200]!));

          final Color textColor = isHold
              ? const Color(0xFFD97706)
              : (isDone
                  ? (isReturning ? const Color(0xFFC0392B) : const Color(0xFF1E8449))
                  : (isCurrent ? const Color(0xFF2563EB) : AppTheme.textMuted));

          final Widget? circleChild = isHold
              ? const Icon(Icons.hourglass_top_rounded, size: 10, color: Colors.white)
              : (isDone
                  ? const Icon(Icons.check, size: 11, color: Colors.white)
                  : (isCurrent
                      ? const Icon(Icons.play_arrow_rounded, size: 11, color: Colors.white)
                      : null));

          final Color linkColor = isLinkHold
              ? const Color(0xFFD97706)
              : (isLinkDone
                  ? (isReturning ? const Color(0xFFC0392B) : const Color(0xFF1E8449))
                  : Colors.grey[300]!);

          return Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _showTimelineStepModal(s, index, stages.length),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 1),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: circleColor,
                              border: isHold
                                  ? Border.all(color: const Color(0xFFF59E0B), width: 1.5)
                                  : (isCurrent ? Border.all(color: const Color(0xFF3B82F6), width: 1.5) : null),
                              boxShadow: isHold
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFFD97706).withValues(alpha: 0.3),
                                        blurRadius: 4,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: circleChild,
                          ),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s['title'] as String,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: (isDone || isHold || isCurrent) ? FontWeight.bold : FontWeight.w500,
                                    color: textColor,
                                  ),
                                ),
                                if (isHold)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 2.5, vertical: 0.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF3C7),
                                      borderRadius: BorderRadius.circular(3),
                                      border: Border.all(color: const Color(0xFFD97706), width: 0.5),
                                    ),
                                    child: Text(
                                      'HOLD',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 6.5,
                                        fontWeight: FontWeight.w900,
                                        color: const Color(0xFFB45309),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 7,
                    height: (isLinkHold || isLinkDone) ? 2.5 : 1.5,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: linkColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  /// Interactive modal shown when user taps any step on the hot timeline
  void _showTimelineStepModal(Map<String, dynamic> step, int index, int totalSteps) {
    final title = step['title'] as String;
    final isDone = step['done'] == true;
    final isHold = step['isHold'] == true;
    final isCurrent = step['isCurrent'] == true;
    final description = step['description'] as String? ?? '';
    final isLeg1 = widget.trip.isLeg1GrainPickup;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header: Step Badge & Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isHold
                                  ? const Color(0xFFFEF3C7)
                                  : (isDone ? const Color(0xFFE8F5E9) : const Color(0xFFF3F4F6)),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isHold
                                  ? Icons.hourglass_top_rounded
                                  : (isDone ? Icons.check_circle_rounded : Icons.info_outline_rounded),
                              color: isHold
                                  ? const Color(0xFFD97706)
                                  : (isDone ? const Color(0xFF1E8449) : AppTheme.textMuted),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Step ${index + 1} of $totalSteps: $title',
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              Text(
                                isHold
                                    ? '⏸️ ON HOLD — Action Required'
                                    : (isDone
                                        ? '✅ Completed'
                                        : (isCurrent ? '📍 In Progress' : '🔒 Pending Next Stage')),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isHold
                                      ? const Color(0xFFD97706)
                                      : (isDone
                                          ? const Color(0xFF1E8449)
                                          : (isCurrent ? const Color(0xFF2563EB) : AppTheme.textMuted)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Description card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F5EF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2D8C9)),
                    ),
                    child: Text(
                      description,
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textPrimary, height: 1.4),
                    ),
                  ),

                  // Stage Specific Details:
                  if (title == 'Mill' && isLeg1) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _allMillBagsScanned ? const Color(0xFFE8F5E9) : const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _allMillBagsScanned ? const Color(0xFF1E8449) : const Color(0xFFFCD34D),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Merchant Bag Inspection Status:',
                                style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${_scannedMillBags.length}/${_productBags.length} Verified',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: _allMillBagsScanned ? const Color(0xFF1E8449) : const Color(0xFFD97706),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: _productBags.isEmpty ? 0 : _scannedMillBags.length / _productBags.length,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _allMillBagsScanned ? const Color(0xFF1E8449) : const Color(0xFFD97706),
                              ),
                              minHeight: 6,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ..._productBags.map((b) {
                            final isScanned = _scannedMillBags.contains(b.bagId);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${b.productName} (${b.quantityKg.toStringAsFixed(1)} kg) • ${b.bagId}',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textPrimary),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isScanned ? const Color(0xFFE8F5E9) : const Color(0xFFFEF3C7),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      isScanned ? '✔ Scanned' : '⏳ Awaiting Scan',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: isScanned ? const Color(0xFF1E8449) : const Color(0xFFD97706),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              Navigator.pop(ctx);
                              await _checkMerchantInspectionStatus();
                            },
                            icon: const Icon(Icons.sync_rounded, size: 16),
                            label: const Text('Check Status'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primaryTerracotta,
                              side: const BorderSide(color: AppTheme.primaryTerracotta),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              Navigator.pop(ctx);
                              await _simulateMerchantDecision(true);
                            },
                            icon: const Icon(Icons.check_circle_outline, size: 16, color: Colors.white),
                            label: const Text('Simulate Scan', style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E8449),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  if (title == 'Done') ...[
                    const SizedBox(height: 14),
                    if (isLeg1 && !_allMillBagsScanned) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFD97706)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.lock_clock_rounded, color: Color(0xFFD97706), size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Completion Locked: All ${_productBags.length} grain bags must be inspected & scanned by mill owner before trip can be completed.',
                                style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFB45309)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _handleConfirmDelivery();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E8449),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text('Confirm & Finish Leg 1', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
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
                  Icon(
                    _isRejectedAtMill ? Icons.assignment_return_rounded : Icons.alt_route_rounded,
                    color: _isRejectedAtMill ? const Color(0xFFE74C3C) : const Color(0xFF2ECC71),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isRejectedAtMill ? 'Return Leg: Mill ➔ Customer Home' : 'Unified Multi-Stop Route Map',
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (_isRejectedAtMill ? const Color(0xFFE74C3C) : const Color(0xFF2ECC71)).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _isRejectedAtMill ? 'Return Active' : '${_tripStops.length} Stops Active',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _isRejectedAtMill ? const Color(0xFFE74C3C) : const Color(0xFF2ECC71),
                  ),
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
                              Text(widget.trip.isLeg1GrainPickup ? 'DESTINATION: ${widget.trip.millName}' : 'PICKUP: ${widget.trip.millName}', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                              Text(
                                (widget.trip.isLeg1GrainPickup
                                    ? (_allMillBagsScanned ? '✅ ACCEPTED' : 'PENDING')
                                    : (_currentStage != TripStage.headingToMill && _currentStage != TripStage.atMillPickup ? '✅ PICKED' : 'PENDING')),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: (widget.trip.isLeg1GrainPickup
                                      ? (_allMillBagsScanned ? const Color(0xFF2ECC71) : const Color(0xFFF1C40F))
                                      : (_currentStage != TripStage.headingToMill && _currentStage != TripStage.atMillPickup ? const Color(0xFF2ECC71) : const Color(0xFFF1C40F))),
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
                  final isCurrent = idx == _currentStopIndex &&
                      (_currentStage == TripStage.headingToCustomer ||
                          _currentStage == TripStage.atCustomerPickup ||
                          _currentStage == TripStage.atCustomerDelivery ||
                          _currentStage == TripStage.returningToCustomer ||
                          _currentStage == TripStage.atCustomerReturn ||
                          _currentStage == TripStage.returningToMill ||
                          _currentStage == TripStage.atMillReturn);
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
                                      ? (_isRejectedAtMill ? const Color(0xFFC0392B) : const Color(0xFF2980B9))
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
                                  isDone
                                      ? '✅ DELIVERED'
                                      : _isRejectedAtMill
                                          ? '🔄 RETURN'
                                          : isCurrent
                                              ? '📍 CURRENT'
                                              : 'QUEUED',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: isDone
                                        ? const Color(0xFF2ECC71)
                                        : _isRejectedAtMill
                                            ? const Color(0xFFE74C3C)
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
                  color: _isRejectedAtMill ? const Color(0xFFC0392B) : AppTheme.primaryTerracotta,
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
                if (_currentStage == TripStage.headingToCustomer) {
                  _currentStage = widget.trip.isLeg1GrainPickup
                      ? TripStage.atCustomerPickup
                      : TripStage.atCustomerDelivery;
                } else if (_currentStage == TripStage.headingToMill) {
                  _currentStage = widget.trip.isLeg1GrainPickup
                      ? TripStage.atMillDelivery
                      : TripStage.atMillPickup;
                } else if (_currentStage == TripStage.returningToCustomer) {
                  _currentStage = TripStage.atCustomerReturn;
                } else if (_currentStage == TripStage.returningToMill) {
                  _currentStage = TripStage.atMillReturn;
                }
              });
              if (widget.trip.isLeg1GrainPickup &&
                  (_currentStage == TripStage.atMillDelivery ||
                      _currentStage == TripStage.atCustomerDelivery ||
                      _currentStage == TripStage.atMillPickup)) {
                _startMerchantInspectionPolling();
              }
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

  Widget _buildLeg1CustomerPickupSection() {
    final stop = _activeStop;
    final stopBags = _productBags.where((b) => b.orderId == stop.orderId).toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stop Header & Contact
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.home_filled, color: AppTheme.primaryTerracotta),
                  const SizedBox(width: 8),
                  Text(
                    'Stop ${_currentStopIndex + 1} of ${_tripStops.length}: Grain Pickup',
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
          Text(
            stop.homePickupAddress.isNotEmpty ? stop.homePickupAddress : stop.deliveryAddress,
            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary),
          ),
          if (stop.homePickupLandmark != null && stop.homePickupLandmark!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '📍 Landmark: ${stop.homePickupLandmark}',
              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF0369A1), fontWeight: FontWeight.w600),
            ),
          ],
          if (stop.homePickupInstructions != null && stop.homePickupInstructions!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Text(
                '📝 Note: "${stop.homePickupInstructions}"',
                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF92400E)),
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Raw Grain Bags for this customer
          Text('Raw Grain Bags to Collect (${stopBags.length} Bags):', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 8),
          ...stopBags.map((bag) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bag.isPickedUp ? const Color(0xFFE8F8F5) : const Color(0xFFFAF6F0),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: bag.isPickedUp ? const Color(0xFF2ECC71) : const Color(0xFFECE4D9),
                  width: bag.isPickedUp ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    bag.isPickedUp ? Icons.check_circle_rounded : Icons.grain_rounded,
                    color: bag.isPickedUp ? const Color(0xFF1E8449) : const Color(0xFF6E5616),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${bag.productName} • ${bag.unitText}',
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        Text(
                          'Tag ID: ${bag.bagId} • Customer: ${bag.customerName}',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _openProductBagBarcodeScanner(bag, isPickup: true),
                    icon: Icon(bag.isPickedUp ? Icons.check : Icons.qr_code_scanner_rounded, size: 14, color: Colors.white),
                    label: Text(bag.isPickedUp ? 'Scanned' : 'Scan Bag', style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: bag.isPickedUp ? const Color(0xFF1E8449) : const Color(0xFF6E5616),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),

          // Quality & Safety Checklist
          Text('Grain Intake Safety Checklist:', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12)),
          Material(
            color: Colors.transparent,
            child: Column(
              children: [
                CheckboxListTile(
                  value: _isBagSealed,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text('Grain bag sealed & labelled with tag', style: GoogleFonts.plusJakartaSans(fontSize: 12)),
                  onChanged: (val) => setState(() => _isBagSealed = val ?? true),
                ),
                CheckboxListTile(
                  value: _isMoistureChecked,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text('Grain dry to touch (no moisture damage)', style: GoogleFonts.plusJakartaSans(fontSize: 12)),
                  onChanged: (val) => setState(() => _isMoistureChecked = val ?? true),
                ),
                CheckboxListTile(
                  value: _isWeightVerified,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text('Weight verified (${stop.quantityKg} kg)', style: GoogleFonts.plusJakartaSans(fontSize: 12)),
                  onChanged: (val) => setState(() => _isWeightVerified = val ?? true),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Customer Pickup PIN
          Text('Customer Pickup PIN:', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 6),
          TextField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: '4-Digit Pickup PIN',
              hintText: 'e.g. ${stop.pickupPin.isNotEmpty ? stop.pickupPin : "4821"}',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),

          // Confirm Grain Pickup Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isProcessing ? null : _handleConfirmLeg1CustomerPickup,
              icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              label: _isProcessing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      _currentStopIndex < _tripStops.length - 1
                          ? 'CONFIRM PICKUP & PROCEED TO STOP ${_currentStopIndex + 2}'
                          : 'CONFIRM PICKUP & HEAD TO MILL',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E8449),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeg1HeadingToMillSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mill Destination Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.storefront_rounded, color: AppTheme.primaryTerracotta),
                  const SizedBox(width: 8),
                  Text(
                    'En-Route to Mill: Drop Raw Grain',
                    style: GoogleFonts.playfairDisplay(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () => _callParty(widget.trip.millPhone, widget.trip.millName),
                    icon: const Icon(Icons.call_outlined, color: Color(0xFF1E8449), size: 20),
                    tooltip: 'Call Mill Owner',
                  ),
                  IconButton(
                    onPressed: () => _openWhatsAppHelper(widget.trip.millName, widget.trip.millPhone),
                    icon: const Icon(Icons.chat_outlined, color: Color(0xFF2ECC71), size: 20),
                    tooltip: 'WhatsApp Help',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(widget.trip.millName, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14)),
          Text(widget.trip.millAddress, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary)),
          const SizedBox(height: 14),

          // In Transit Notice Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF86EFAC)),
            ),
            child: Row(
              children: [
                const Icon(Icons.two_wheeler_rounded, color: Color(0xFF16A34A), size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'All Grain Collected (${_productBags.length} Bags)',
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF166534)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Drive to ${widget.trip.millName}. Upon arrival, hand over bags to shopkeeper for intake inspection & scanning.',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF15803D)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Carrying Grain Bags List
          Text('Carrying Grain Bags on Bike:', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 8),
          ..._productBags.map((bag) {
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF6F0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFECE4D9)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.inventory_2_outlined, size: 18, color: Color(0xFF6E5616)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${bag.productName} (${bag.unitText}) • For ${bag.customerName}',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text('Tag: ${bag.bagId}', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppTheme.textSecondary)),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),

          // Arrive at Mill Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _currentStage = TripStage.atMillDelivery;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('📍 Arrived at ${widget.trip.millName}! Mill owner will inspect & scan all grain bags.'),
                    backgroundColor: const Color(0xFF1E8449),
                  ),
                );
              },
              icon: const Icon(Icons.storefront_rounded, color: Colors.white, size: 20),
              label: Text(
                'ARRIVED AT MILL — START INTAKE & SCAN',
                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryTerracotta,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeg2MillPickupSection() {
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
                    'Leg 2: Mill Flour Pickup (${_productBags.length} Bags)',
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

          // Flour Pickup Notice Banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF16A34A), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Milling Complete! Scan and collect freshly milled flour bags for doorstep delivery.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF166534)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Scan & Verify Mill Bags
          Text('Milled Flour Bags to Pick Up:', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 8),
          ..._productBags.map((bag) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bag.isPickedUp ? const Color(0xFFE8F8F5) : const Color(0xFFFAF6F0),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: bag.isPickedUp ? const Color(0xFF2ECC71) : const Color(0xFFECE4D9),
                  width: bag.isPickedUp ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    bag.isPickedUp ? Icons.check_circle_rounded : Icons.inventory_2_outlined,
                    color: bag.isPickedUp ? const Color(0xFF1E8449) : const Color(0xFF6E5616),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${bag.orderNumber} • ${bag.unitText} ${bag.productName}',
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        Text(
                          'For ${bag.customerName} • Tag: ${bag.bagId}',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _openProductBagBarcodeScanner(bag, isPickup: true),
                    icon: Icon(bag.isPickedUp ? Icons.check : Icons.qr_code_scanner_rounded, size: 14, color: Colors.white),
                    label: Text(bag.isPickedUp ? 'Scanned' : 'Scan Bag', style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: bag.isPickedUp ? const Color(0xFF1E8449) : const Color(0xFF6E5616),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),

          // Quality & Safety Checklist
          Text('Quality & Safety Checklist:', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12)),
          Material(
            color: Colors.transparent,
            child: Column(
              children: [
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
              ],
            ),
          ),
          const SizedBox(height: 14),

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


  Widget _buildLeg1MillDropSection() {
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
          // Mill Handover Header & Mill Owner Contact
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.storefront_rounded, color: AppTheme.primaryTerracotta),
                  const SizedBox(width: 8),
                  Text(
                    'Leg 1 Mill Drop: Raw Grain Handover',
                    style: GoogleFonts.playfairDisplay(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () => _callParty(widget.trip.millPhone, widget.trip.millName),
                    icon: const Icon(Icons.call_outlined, color: Color(0xFF1E8449), size: 20),
                    tooltip: 'Call Mill Owner',
                  ),
                  IconButton(
                    onPressed: () => _openWhatsAppHelper(widget.trip.millName, widget.trip.millPhone),
                    icon: const Icon(Icons.chat_outlined, color: Color(0xFF2ECC71), size: 20),
                    tooltip: 'WhatsApp Help',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(widget.trip.millName, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14)),
          Text(widget.trip.millAddress, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary)),
          const SizedBox(height: 14),

          // Merchant Inspection & Quality Scan Status Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.hourglass_top_rounded, color: Color(0xFFD97706), size: 22),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Awaiting Merchant Inspection & Scan',
                            style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF92400E)),
                          ),
                          Text(
                            'Auto-syncing with mill owner app...',
                            style: GoogleFonts.plusJakartaSans(fontSize: 10, color: const Color(0xFFB45309)),
                          ),
                        ],
                      ),
                    ),
                    if (_isCheckingInspectionStatus)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFD97706)),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'The shopkeeper must inspect and scan each raw grain bag. If accepted, milling starts. If rejected, you must return all grain back to the customer.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF78350F), height: 1.4),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _openShopkeeperScanAndInspectionDialog,
                    icon: const Icon(Icons.qr_code_scanner_rounded, size: 16, color: Color(0xFF92400E)),
                    label: Text(
                      'Open Shopkeeper Scanner & Inspector',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF92400E)),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFF59E0B)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isProcessing ? null : _showShopkeeperRejectReasonDialog,
                        icon: const Icon(Icons.cancel_outlined, size: 14, color: Color(0xFFC0392B)),
                        label: Text('Shopkeeper Rejects', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFC0392B))),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFEF4444)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isProcessing ? null : () => _simulateMerchantDecision(true),
                        icon: const Icon(Icons.check_circle_outline, size: 14, color: Colors.white),
                        label: Text('Shopkeeper Accepts', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E8449),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Grain Bags List for Inspection
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Grain Bags Handed to Mill for Inspection:',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _allMillBagsScanned ? const Color(0xFFE8F8F5) : const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _allMillBagsScanned ? const Color(0xFF2ECC71) : const Color(0xFFF59E0B),
                  ),
                ),
                child: Text(
                  '${_scannedMillBags.length}/${_productBags.length} Scanned',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: _allMillBagsScanned ? const Color(0xFF1E8449) : const Color(0xFF92400E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._productBags.map((bag) {
            final isScanned = _scannedMillBags.contains(bag.bagId);

            return InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                setState(() {
                  if (isScanned) {
                    _scannedMillBags.remove(bag.bagId);
                  } else {
                    _scannedMillBags.add(bag.bagId);
                  }
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      !isScanned
                          ? '✅ Scanned & Verified: ${bag.productName} (${bag.bagId})!'
                          : '⏳ Unmarked: ${bag.productName} (${bag.bagId})',
                    ),
                    backgroundColor: !isScanned ? const Color(0xFF1E8449) : const Color(0xFFD97706),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isScanned ? const Color(0xFFE8F8F5) : const Color(0xFFFAF6F0),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isScanned ? const Color(0xFFA3E4D7) : const Color(0xFFECE4D9),
                    width: isScanned ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isScanned ? Icons.check_circle_rounded : Icons.inventory_2_outlined,
                      color: isScanned ? const Color(0xFF1E8449) : const Color(0xFF6E5616),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${bag.productName} • ${bag.unitText}',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: isScanned ? const Color(0xFF145A32) : Colors.black87,
                            ),
                          ),
                          Text(
                            'Tag: ${bag.bagId} • Customer: ${bag.customerName}',
                            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isScanned
                            ? const Color(0xFF1E8449).withValues(alpha: 0.12)
                            : const Color(0xFFD97706).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isScanned ? Icons.check_circle_rounded : Icons.hourglass_empty_rounded,
                            size: 12,
                            color: isScanned ? const Color(0xFF1E8449) : const Color(0xFFD97706),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isScanned ? 'Scanned & Verified' : 'Awaiting Mill Scan',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isScanned ? const Color(0xFF1E8449) : const Color(0xFFD97706),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 14),

          // Check Status / Confirm Drop Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isProcessing || _isCheckingInspectionStatus
                  ? null
                  : () => _handleConfirmDelivery(),
              icon: _isCheckingInspectionStatus
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Icon(
                      _allMillBagsScanned ? Icons.check_circle_outline_rounded : Icons.sync_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
              label: Text(
                _isCheckingInspectionStatus
                    ? 'CHECKING MERCHANT STATUS...'
                    : (_allMillBagsScanned
                        ? '✅ ALL ${_productBags.length} BAGS VERIFIED — CONFIRM GRAIN DROP'
                        : 'CHECK MERCHANT VERIFICATION STATUS (${_scannedMillBags.length}/${_productBags.length} SCANNED)'),
                style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _allMillBagsScanned
                    ? const Color(0xFF1E8449)
                    : const Color(0xFFD97706),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeg2CustomerDoorstepSection() {
    final stop = _activeStop;

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

          // Order Items to Deliver
          Text('Order Items to Deliver:', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          ..._productBags.where((b) => b.orderId == stop.orderId).map((bag) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF6F0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFECE4D9)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.inventory_2_outlined,
                    color: Color(0xFF6E5616),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${bag.productName} • ${bag.unitText}',
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12.5),
                        ),
                        Text(
                          'Tag: ${bag.bagId}',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 18),

          // Primary DROP AT HOME Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _isProcessing ? null : () => _handleConfirmDelivery(),
              icon: const Icon(Icons.home_rounded, color: Colors.white, size: 22),
              label: _isProcessing
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : Text(
                      _currentStopIndex < _tripStops.length - 1
                          ? 'DROP AT HOME & PROCEED TO NEXT STOP'
                          : 'DROP AT HOME',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E8449),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerReturnSection() {
    final stop = _activeStop;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFCA5A5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Return Leg Header & Reason
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFF87171)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Grain Rejected at Mill Quality Check',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF991B1B)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Reason: "${_millRejectionReason.isNotEmpty ? _millRejectionReason : 'Quality parameters (moisture/purity) failed inspection at mill'}"',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF7F1D1D)),
                ),
                const SizedBox(height: 6),
                Text(
                  'Return action required: Deliver all raw grain bags back to customer doorstep.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF991B1B)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Return Customer Contact
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.home_rounded, color: Color(0xFFDC2626)),
                  const SizedBox(width: 8),
                  Text(
                    'Return to Customer Doorstep',
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
          Text(
            stop.homePickupAddress.isNotEmpty ? stop.homePickupAddress : stop.deliveryAddress,
            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),

          // Grain Bags to Return
          Text('Grain Bags Being Returned:', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 8),
          ..._productBags.where((b) => b.orderId == stop.orderId).map((bag) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFECDD3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.inventory_2_outlined, color: Color(0xFFE11D48), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${bag.productName} • ${bag.unitText}',
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        Text(
                          'Tag: ${bag.bagId} • Returning to ${bag.customerName}',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE11D48).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'RETURN',
                      style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFFE11D48)),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 14),

          // Return Proof Handover
          Text('Proof of Return Handover:', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _simulateDoorstepPhoto,
                  icon: Icon(_hasDoorstepPhoto ? Icons.check_circle : Icons.camera_alt_outlined, size: 16, color: _hasDoorstepPhoto ? const Color(0xFF1E8449) : const Color(0xFFE11D48)),
                  label: Text(_hasDoorstepPhoto ? 'Photo Added' : 'Return Photo', style: GoogleFonts.plusJakartaSans(fontSize: 12)),
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
                  icon: Icon(_hasCustomerSignature ? Icons.check_circle : Icons.draw_outlined, size: 16, color: _hasCustomerSignature ? const Color(0xFF1E8449) : const Color(0xFFE11D48)),
                  label: Text(_hasCustomerSignature ? 'Signed' : 'Customer Sign', style: GoogleFonts.plusJakartaSans(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: _hasCustomerSignature ? const Color(0xFF1E8449) : AppTheme.borderLight),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Confirm Return Handover Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isProcessing ? null : _handleConfirmReturnToCustomer,
              icon: const Icon(Icons.assignment_return_rounded, color: Colors.white, size: 20),
              label: _isProcessing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'CONFIRM RETURN HANDOVER & COMPLETE',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC0392B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMillReturnSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFCA5A5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Return Leg Header & Reason
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFF87171)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.assignment_return_rounded, color: Color(0xFFDC2626), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Flour Rejected by Customer at Doorstep',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF991B1B)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Reason: "${_customerRejectionReason.isNotEmpty ? _customerRejectionReason : 'Flour failed doorstep quality inspection'}"',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF7F1D1D)),
                ),
                const SizedBox(height: 6),
                Text(
                  'Return action required: Deliver rejected flour back to ${widget.trip.millName}.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF991B1B)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Return Mill Contact
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.storefront_rounded, color: Color(0xFFDC2626)),
                  const SizedBox(width: 8),
                  Text(
                    'Return to Flour Mill',
                    style: GoogleFonts.playfairDisplay(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () => _callParty(widget.trip.millPhone, widget.trip.millName),
                    icon: const Icon(Icons.call_outlined, color: Color(0xFF1E8449), size: 20),
                    tooltip: 'Call Mill Owner',
                  ),
                  IconButton(
                    onPressed: () => _openWhatsAppHelper(widget.trip.millName, widget.trip.millPhone),
                    icon: const Icon(Icons.chat_outlined, color: Color(0xFF2ECC71), size: 20),
                    tooltip: 'WhatsApp Help',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(widget.trip.millName, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14)),
          Text(widget.trip.millAddress, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary)),
          const SizedBox(height: 16),

          // Flour Bags Being Returned
          Text('Flour Bags Being Returned to Mill:', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 8),
          ..._productBags.where((b) => b.orderId == _activeStop.orderId).map((bag) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFECDD3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.inventory_2_outlined, color: Color(0xFFE11D48), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${bag.productName} • ${bag.unitText}',
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        Text(
                          'Tag: ${bag.bagId} • Customer: ${bag.customerName}',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE11D48).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'RETURN',
                      style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFFE11D48)),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 14),

          // Return Proof Handover
          Text('Proof of Return Handover at Mill:', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _simulateDoorstepPhoto,
                  icon: Icon(_hasDoorstepPhoto ? Icons.check_circle : Icons.camera_alt_outlined, size: 16, color: _hasDoorstepPhoto ? const Color(0xFF1E8449) : const Color(0xFFE11D48)),
                  label: Text(_hasDoorstepPhoto ? 'Photo Added' : 'Handover Photo', style: GoogleFonts.plusJakartaSans(fontSize: 12)),
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
                  icon: Icon(_hasCustomerSignature ? Icons.check_circle : Icons.draw_outlined, size: 16, color: _hasCustomerSignature ? const Color(0xFF1E8449) : const Color(0xFFE11D48)),
                  label: Text(_hasCustomerSignature ? 'Signed' : 'Shopkeeper Sign', style: GoogleFonts.plusJakartaSans(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: _hasCustomerSignature ? const Color(0xFF1E8449) : AppTheme.borderLight),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Confirm Return Handover Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isProcessing ? null : _handleConfirmReturnToMill,
              icon: const Icon(Icons.assignment_return_rounded, color: Colors.white, size: 20),
              label: _isProcessing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'CONFIRM RETURN HANDOVER AT MILL & COMPLETE',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC0392B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _simulateCustomerDecision(bool isAccepted, {String? reason}) async {
    setState(() => _isProcessing = true);
    final stopOrderId = _activeStop.orderId;
    try {
      if (isAccepted) {
        final currentStopBags = _productBags.where((b) => b.orderId == stopOrderId).toList();
        setState(() {
          _scannedCustomerBags.addAll(currentStopBags.map((b) => b.bagId));
        });
        await DeliveryApiService.instance.submitCustomerVerification(
          stopOrderId,
          isAccepted: true,
          notes: 'Customer scanned and approved flour quality at doorstep',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Customer verified & approved all flour bags! Tap Confirm Drop to complete.'),
              backgroundColor: Color(0xFF1E8449),
            ),
          );
        }
      } else {
        final rejectReason = reason ?? 'Flour texture coarse and packaging damaged';
        await DeliveryApiService.instance.submitCustomerVerification(
          stopOrderId,
          isAccepted: false,
          reason: rejectReason,
          notes: 'Customer rejected flour at doorstep during scan/quality check',
        );
        _resetNavigationForReturnToMillStage(rejectReason);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification update failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showShopkeeperRejectReasonDialog() {
    final reasons = [
      'Moisture > 16% / Damp Grain',
      'Foreign Seeds & Weed Contamination',
      'Infestation / Weevil Damage in Grain',
      'Damaged / Non-Milling Quality Grain',
      'Weight Significantly Below Manifest',
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.cancel_rounded, color: Color(0xFFC0392B)),
            const SizedBox(width: 8),
            Text('Shopkeeper Rejection', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select the inspection failure reason for rejecting raw grain:', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary)),
            const SizedBox(height: 12),
            ...reasons.map((r) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.radio_button_unchecked, color: Color(0xFFC0392B), size: 18),
              title: Text(r, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(ctx);
                _simulateMerchantDecision(false, reason: r);
              },
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary)),
          ),
        ],
      ),
    );
  }

  void _openShopkeeperScanAndInspectionDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final allScanned = _productBags.isNotEmpty && _scannedMillBags.length >= _productBags.length;

          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Shopkeeper Intake Inspection', style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: allScanned ? const Color(0xFFE8F8F5) : const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_scannedMillBags.length}/${_productBags.length} Verified',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: allScanned ? const Color(0xFF1E8449) : const Color(0xFFD97706),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Tap each grain bag to scan barcode and verify quality criteria.', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary)),
                const SizedBox(height: 14),

                Expanded(
                  child: ListView.builder(
                    itemCount: _productBags.length,
                    itemBuilder: (context, idx) {
                      final bag = _productBags[idx];
                      final isScanned = _scannedMillBags.contains(bag.bagId);

                      return InkWell(
                        onTap: () {
                          setModalState(() {
                            if (isScanned) {
                              _scannedMillBags.remove(bag.bagId);
                            } else {
                              _scannedMillBags.add(bag.bagId);
                            }
                          });
                          setState(() {});
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isScanned ? const Color(0xFFE8F8F5) : const Color(0xFFFAF6F0),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isScanned ? const Color(0xFFA3E4D7) : const Color(0xFFECE4D9),
                              width: isScanned ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isScanned ? Icons.check_circle_rounded : Icons.crop_free_rounded,
                                color: isScanned ? const Color(0xFF1E8449) : const Color(0xFF6E5616),
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${bag.productName} • ${bag.unitText}', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13)),
                                    Text('Tag: ${bag.bagId} • Customer: ${bag.customerName}', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondary)),
                                  ],
                                ),
                              ),
                              Text(isScanned ? 'PASSED' : 'TAP TO SCAN', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 11, color: isScanned ? const Color(0xFF1E8449) : const Color(0xFFD97706))),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showShopkeeperRejectReasonDialog();
                        },
                        icon: const Icon(Icons.cancel_outlined, color: Color(0xFFC0392B), size: 16),
                        label: Text('Reject Grain', style: GoogleFonts.plusJakartaSans(color: const Color(0xFFC0392B), fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFEF4444)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _simulateMerchantDecision(true);
                        },
                        icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 16),
                        label: Text('Approve All', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E8449),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showCustomerRejectReasonDialog() {
    final reasons = [
      'Flour Texture Too Coarse / Granular',
      'Unpleasant Odor / Damp Smell in Flour',
      'Damaged / Torn Bag Packaging',
      'Foreign Particles / Specks in Flour',
      'Wrong Flour / Grain Variety Delivered',
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.cancel_rounded, color: Color(0xFFC0392B)),
            const SizedBox(width: 8),
            Text('Customer Rejection', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select the reason customer rejected the milled flour at doorstep:', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary)),
            const SizedBox(height: 12),
            ...reasons.map((r) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.radio_button_unchecked, color: Color(0xFFC0392B), size: 18),
              title: Text(r, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(ctx);
                _simulateCustomerDecision(false, reason: r);
              },
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary)),
          ),
        ],
      ),
    );
  }

  void _openCustomerScanAndQualityDialog() {
    final stopOrderId = _activeStop.orderId;
    final currentBags = _productBags.where((b) => b.orderId == stopOrderId).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final allScanned = currentBags.isNotEmpty && _scannedCustomerBags.length >= currentBags.length;

          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Customer Quality Check', style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: allScanned ? const Color(0xFFE8F8F5) : const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_scannedCustomerBags.length}/${currentBags.length} Verified',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: allScanned ? const Color(0xFF1E8449) : const Color(0xFFD97706),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Customer verifies flour texture, packaging seals, and scans barcode tags.', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary)),
                const SizedBox(height: 14),

                Expanded(
                  child: ListView.builder(
                    itemCount: currentBags.length,
                    itemBuilder: (context, idx) {
                      final bag = currentBags[idx];
                      final isScanned = _scannedCustomerBags.contains(bag.bagId);

                      return InkWell(
                        onTap: () {
                          setModalState(() {
                            if (isScanned) {
                              _scannedCustomerBags.remove(bag.bagId);
                            } else {
                              _scannedCustomerBags.add(bag.bagId);
                            }
                          });
                          setState(() {});
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isScanned ? const Color(0xFFE8F8F5) : const Color(0xFFFAF6F0),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isScanned ? const Color(0xFFA3E4D7) : const Color(0xFFECE4D9),
                              width: isScanned ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isScanned ? Icons.check_circle_rounded : Icons.crop_free_rounded,
                                color: isScanned ? const Color(0xFF1E8449) : const Color(0xFF6E5616),
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${bag.productName} • ${bag.unitText}', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13)),
                                    Text('Tag: ${bag.bagId}', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondary)),
                                  ],
                                ),
                              ),
                              Text(isScanned ? 'APPROVED' : 'SCAN BAG', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 11, color: isScanned ? const Color(0xFF1E8449) : const Color(0xFFD97706))),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showCustomerRejectReasonDialog();
                        },
                        icon: const Icon(Icons.cancel_outlined, color: Color(0xFFC0392B), size: 16),
                        label: Text('Reject Flour', style: GoogleFonts.plusJakartaSans(color: const Color(0xFFC0392B), fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFEF4444)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _simulateCustomerDecision(true);
                        },
                        icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 16),
                        label: Text('Accept Quality', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E8449),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _openOrderTimelineSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FutureBuilder<List<OrderTimelineEvent>>(
        future: DeliveryApiService.instance.getOrderTimeline(_activeStop.orderId),
        builder: (context, snapshot) {
          final timelineEvents = (snapshot.hasData && snapshot.data!.isNotEmpty)
              ? snapshot.data!
              : _buildSynthesizedTimeline();

          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.timeline_rounded, color: AppTheme.primaryTerracotta),
                        const SizedBox(width: 8),
                        Text('Order Timeline', style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryTerracotta.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _activeStop.orderNumber,
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.primaryTerracotta),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('End-to-end verified milestone tracking for this order:', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary)),
                const SizedBox(height: 16),

                Expanded(
                  child: ListView.builder(
                    itemCount: timelineEvents.length,
                    itemBuilder: (context, index) {
                      final ev = timelineEvents[index];
                      final isLast = index == timelineEvents.length - 1;
                      final isRejectOrReturn = ev.isReturnOrReject;

                      Color iconColor = const Color(0xFF1E8449);
                      Color dotBg = const Color(0xFFE8F8F5);
                      IconData eventIcon = Icons.check_circle_rounded;

                      if (isRejectOrReturn) {
                        iconColor = const Color(0xFFDC2626);
                        dotBg = const Color(0xFFFEF2F2);
                        eventIcon = Icons.cancel_rounded;
                      } else if (ev.status.contains('ASSIGNED') || ev.status.contains('PICKED') || ev.status.contains('EN_ROUTE')) {
                        iconColor = const Color(0xFFD97706);
                        dotBg = const Color(0xFFFFFBEB);
                        eventIcon = Icons.navigation_rounded;
                      } else if (ev.status.contains('MILLING') || ev.status.contains('INTAKE')) {
                        iconColor = const Color(0xFF2563EB);
                        dotBg = const Color(0xFFEFF6FF);
                        eventIcon = Icons.storefront_rounded;
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Timeline Line and Node
                          Column(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: dotBg,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: iconColor.withValues(alpha: 0.4), width: 1.5),
                                ),
                                child: Icon(eventIcon, color: iconColor, size: 16),
                              ),
                              if (!isLast)
                                Container(
                                  width: 2,
                                  height: 44,
                                  color: Colors.grey.shade200,
                                ),
                            ],
                          ),
                          const SizedBox(width: 14),

                          // Event Details
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          ev.title,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: isRejectOrReturn ? const Color(0xFF991B1B) : AppTheme.textPrimary,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        ev.formattedTime,
                                        style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppTheme.textSecondary),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    ev.description,
                                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondary),
                                  ),
                                  if (ev.performedBy != null && ev.performedBy!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'By ${ev.performedBy}',
                                        style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<OrderTimelineEvent> _buildSynthesizedTimeline() {
    final List<OrderTimelineEvent> list = [];
    final now = DateTime.now();

    list.add(OrderTimelineEvent(
      title: 'Order Placed',
      description: 'Customer booked milling delivery trip',
      status: 'BOOKED',
      createdAt: now.subtract(const Duration(minutes: 45)),
      performedBy: 'Customer',
    ));

    list.add(OrderTimelineEvent(
      title: 'Rider Assigned',
      description: 'Trip accepted by driver. Route navigation initiated.',
      status: 'DRIVER_ASSIGNED',
      createdAt: now.subtract(const Duration(minutes: 35)),
      performedBy: 'Driver',
    ));

    if (widget.trip.isLeg1GrainPickup) {
      if (_currentStage != TripStage.headingToCustomer && _currentStage != TripStage.atCustomerPickup) {
        list.add(OrderTimelineEvent(
          title: 'Grain Bags Collected',
          description: 'Rider picked up grain bags from customer doorstep.',
          status: 'GRAIN_PICKED_UP',
          createdAt: now.subtract(const Duration(minutes: 20)),
          performedBy: 'Driver',
        ));
      }

      if (_currentStage == TripStage.atMillDelivery ||
          _currentStage == TripStage.returningToCustomer ||
          _currentStage == TripStage.atCustomerReturn ||
          _currentStage == TripStage.completed) {
        list.add(OrderTimelineEvent(
          title: 'Arrived at Flour Mill',
          description: 'Grain bags submitted to mill shopkeeper for quality inspection.',
          status: 'MILL_ARRIVED',
          createdAt: now.subtract(const Duration(minutes: 10)),
          performedBy: 'Driver',
        ));
      }

      if (_isRejectedAtMill || _currentStage == TripStage.returningToCustomer || _currentStage == TripStage.atCustomerReturn) {
        list.add(OrderTimelineEvent(
          title: 'Grain Quality Rejected by Mill',
          description: 'Shopkeeper rejected grain: "${_millRejectionReason.isNotEmpty ? _millRejectionReason : 'Quality failed'}"',
          status: 'RETURN_TO_CUSTOMER',
          createdAt: now.subtract(const Duration(minutes: 5)),
          performedBy: 'Merchant',
        ));
        if (_currentStage == TripStage.completed) {
          list.add(OrderTimelineEvent(
            title: 'Returned to Customer Doorstep',
            description: 'Rejected raw grain safely returned to customer.',
            status: 'RETURNED_TO_CUSTOMER',
            createdAt: now,
            performedBy: 'Driver',
          ));
        }
      } else if (_allMillBagsScanned || _currentStage == TripStage.completed) {
        list.add(OrderTimelineEvent(
          title: 'Grain Quality Approved & Milling Started',
          description: 'Shopkeeper scanned all bags and started milling process.',
          status: 'MILLING_IN_PROGRESS',
          createdAt: now.subtract(const Duration(minutes: 3)),
          performedBy: 'Merchant',
        ));
      }
    } else {
      // Leg 2
      list.add(OrderTimelineEvent(
        title: 'Milling Completed by Mill',
        description: 'Flour milled and packed into sealed bags ready for dispatch.',
        status: 'MILLING_COMPLETED',
        createdAt: now.subtract(const Duration(minutes: 25)),
        performedBy: 'Merchant',
      ));

      if (_currentStage != TripStage.headingToMill && _currentStage != TripStage.atMillPickup) {
        list.add(OrderTimelineEvent(
          title: 'Flour Picked Up from Mill',
          description: 'Rider verified all flour bags and started doorstep route.',
          status: 'FLOUR_PICKED_UP',
          createdAt: now.subtract(const Duration(minutes: 15)),
          performedBy: 'Driver',
        ));
      }

      if (_currentStage == TripStage.atCustomerDelivery ||
          _currentStage == TripStage.returningToMill ||
          _currentStage == TripStage.atMillReturn ||
          _currentStage == TripStage.completed) {
        list.add(OrderTimelineEvent(
          title: 'Arrived at Customer Doorstep',
          description: 'Rider arrived at customer address for quality handover.',
          status: 'DOORSTEP_ARRIVED',
          createdAt: now.subtract(const Duration(minutes: 5)),
          performedBy: 'Driver',
        ));
      }

      if (_isRejectedAtDoorstep || _currentStage == TripStage.returningToMill || _currentStage == TripStage.atMillReturn) {
        list.add(OrderTimelineEvent(
          title: 'Flour Quality Rejected by Customer',
          description: 'Customer rejected flour: "${_customerRejectionReason.isNotEmpty ? _customerRejectionReason : 'Quality failed'}"',
          status: 'RETURN_TO_MILL',
          createdAt: now.subtract(const Duration(minutes: 3)),
          performedBy: 'Customer',
        ));
        if (_currentStage == TripStage.completed) {
          list.add(OrderTimelineEvent(
            title: 'Returned to Flour Mill',
            description: 'Rejected flour safely returned to mill shopkeeper.',
            status: 'RETURNED_TO_MILL',
            createdAt: now,
            performedBy: 'Driver',
          ));
        }
      } else if (_currentStage == TripStage.completed) {
        list.add(OrderTimelineEvent(
          title: 'Delivered & OTP Verified',
          description: 'Customer verified flour quality and completed delivery with OTP.',
          status: 'DELIVERED',
          createdAt: now,
          performedBy: 'Driver',
        ));
      }
    }

    return list;
  }
}


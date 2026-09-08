import 'package:flutter/material.dart';

enum StatusLightColor { green, amber, red, blue, grey }

class StatusLightDef {
  final Color color;
  final Color bg;
  final Color text;
  final Color border;
  final Color glow;
  final bool pulse;
  final String label;

  const StatusLightDef({
    required this.color,
    required this.bg,
    required this.text,
    required this.border,
    required this.glow,
    required this.pulse,
    required this.label,
  });
}

const Map<StatusLightColor, StatusLightDef> statusLightDefinitions = {
  StatusLightColor.green: StatusLightDef(
    color: Color(0xFF2ECC71),
    bg: Color(0xFFE8F8F0),
    text: Color(0xFF1E8449),
    border: Color(0xFFA9DFBF),
    glow: Color(0x592ECC71),
    pulse: false,
    label: 'Good',
  ),
  StatusLightColor.amber: StatusLightDef(
    color: Color(0xFFF39C12),
    bg: Color(0xFFFFF8E7),
    text: Color(0xFFB7791F),
    border: Color(0xFFF6AD55),
    glow: Color(0x59F39C12),
    pulse: true,
    label: 'Attention',
  ),
  StatusLightColor.red: StatusLightDef(
    color: Color(0xFFE74C3C),
    bg: Color(0xFFFDEDEC),
    text: Color(0xFFC0392B),
    border: Color(0xFFF1948A),
    glow: Color(0x59E74C3C),
    pulse: true,
    label: 'Problem',
  ),
  StatusLightColor.blue: StatusLightDef(
    color: Color(0xFF3498DB),
    bg: Color(0xFFEBF5FB),
    text: Color(0xFF21618C),
    border: Color(0xFF85C1E9),
    glow: Color(0x593498DB),
    pulse: false,
    label: 'In Transit',
  ),
  StatusLightColor.grey: StatusLightDef(
    color: Color(0xFF95A5A6),
    bg: Color(0xFFF2F3F4),
    text: Color(0xFF616A6B),
    border: Color(0xFFD5D8DC),
    glow: Color(0x4095A5A6),
    pulse: false,
    label: 'Inactive',
  ),
};

StatusLightDef getStatusLightDef(StatusLightColor color) {
  return statusLightDefinitions[color] ?? statusLightDefinitions[StatusLightColor.grey]!;
}

const Map<String, StatusLightColor> _orderLightMap = {
  'PENDING': StatusLightColor.amber,
  'PLACED': StatusLightColor.amber,
  'NEW': StatusLightColor.amber,
  'CONFIRMED': StatusLightColor.amber,
  'ACCEPTED': StatusLightColor.green,
  'MILLING': StatusLightColor.amber,
  'PROCESSING': StatusLightColor.amber,
  'PACKING': StatusLightColor.amber,
  'READY': StatusLightColor.green,
  'READY_FOR_PICKUP': StatusLightColor.green,
  'OUT_FOR_DELIVERY': StatusLightColor.blue,
  'PICKED_UP': StatusLightColor.blue,
  'DELIVERED': StatusLightColor.green,
  'COMPLETED': StatusLightColor.green,
  'CANCELLED': StatusLightColor.red,
  'REJECTED': StatusLightColor.red,
  'PAYMENT_FAILED': StatusLightColor.red,
  'DELIVERY_FAILED': StatusLightColor.red,
  'RETURNED': StatusLightColor.red,
  'IN PROGRESS': StatusLightColor.amber,
  'NEW REQUESTS PENDING': StatusLightColor.red,
  'BATCH IN PROGRESS': StatusLightColor.amber,
  'ALL STOPS DELIVERED': StatusLightColor.green,
};

const Map<String, StatusLightColor> _paymentLightMap = {
  'PENDING': StatusLightColor.amber,
  'PAID': StatusLightColor.green,
  'FAILED': StatusLightColor.red,
  'REFUNDED': StatusLightColor.grey,
  'CREATED': StatusLightColor.amber,
};

const Map<String, StatusLightColor> _deliveryLightMap = {
  'ASSIGNED': StatusLightColor.amber,
  'PICKED_UP_FROM_MILL': StatusLightColor.blue,
  'OUT_FOR_DELIVERY': StatusLightColor.blue,
  'ARRIVED': StatusLightColor.amber,
  'DELIVERED': StatusLightColor.green,
};

const Map<String, StatusLightColor> _millLightMap = {
  'Active': StatusLightColor.green,
  'Maintenance': StatusLightColor.amber,
  'Inactive': StatusLightColor.grey,
  'Offline': StatusLightColor.red,
};

const Map<String, StatusLightColor> _userLightMap = {
  'Active': StatusLightColor.green,
  'VIP': StatusLightColor.green,
  'Inactive': StatusLightColor.grey,
  'Suspended': StatusLightColor.red,
  'Pending': StatusLightColor.amber,
  'APPROVED': StatusLightColor.green,
  'PENDING': StatusLightColor.amber,
  'REJECTED': StatusLightColor.red,
  'Pending Review': StatusLightColor.amber,
  'Approved & Active': StatusLightColor.green,
  'Rejected': StatusLightColor.red,
};

StatusLightColor _resolveFromMap(Map<String, StatusLightColor> map, String? status,
    {StatusLightColor fallback = StatusLightColor.grey}) {
  if (status == null || status.isEmpty) return fallback;
  final normalized = status.trim().toUpperCase();
  if (map.containsKey(normalized)) return map[normalized]!;
  final original = status.trim();
  if (map.containsKey(original)) return map[original]!;
  for (final entry in map.entries) {
    if (entry.key.toUpperCase() == normalized) return entry.value;
  }
  return fallback;
}

StatusLightColor getOrderStatusLight(String? status) =>
    _resolveFromMap(_orderLightMap, status);

StatusLightColor getPaymentStatusLight(String? status) =>
    _resolveFromMap(_paymentLightMap, status);

StatusLightColor getDeliveryStatusLight(String? status) =>
    _resolveFromMap(_deliveryLightMap, status);

StatusLightColor getMillStatusLight(String? status) =>
    _resolveFromMap(_millLightMap, status);

StatusLightColor getUserStatusLight(String? status) =>
    _resolveFromMap(_userLightMap, status);

StatusLightColor getMillLoadLight(num loadKg, num capacityKg) {
  if (capacityKg <= 0) return StatusLightColor.grey;
  final pct = (loadKg / capacityKg) * 100;
  if (pct >= 95) return StatusLightColor.red;
  if (pct >= 80) return StatusLightColor.amber;
  return StatusLightColor.green;
}

StatusLightColor getInventoryStockLight(num stockKg, {num? minimumKg}) {
  if (stockKg <= 0) return StatusLightColor.red;
  if (minimumKg != null && stockKg <= minimumKg) return StatusLightColor.amber;
  return StatusLightColor.green;
}

StatusLightColor getBatteryLight(num? pct) {
  if (pct == null) return StatusLightColor.grey;
  if (pct < 15) return StatusLightColor.red;
  if (pct < 40) return StatusLightColor.amber;
  return StatusLightColor.green;
}

StatusLightColor getDriverOnlineLight(bool? isOnline) =>
    isOnline == true ? StatusLightColor.green : StatusLightColor.grey;

StatusLightColor resolveStatusLight(String? status, {String type = 'order'}) {
  switch (type) {
    case 'order':
      return getOrderStatusLight(status);
    case 'payment':
      return getPaymentStatusLight(status);
    case 'delivery':
      return getDeliveryStatusLight(status);
    case 'mill':
      return getMillStatusLight(status);
    case 'user':
      return getUserStatusLight(status);
    default:
      return getOrderStatusLight(status);
  }
}

class StatusLight extends StatefulWidget {
  final StatusLightColor light;
  final double size;
  final bool showGlow;
  final bool showPulse;
  final String? tooltip;
  final VoidCallback? onTap;

  const StatusLight({
    super.key,
    this.light = StatusLightColor.grey,
    this.size = 10,
    this.showGlow = true,
    this.showPulse = true,
    this.tooltip,
    this.onTap,
  });

  @override
  State<StatusLight> createState() => _StatusLightState();
}

class _StatusLightState extends State<StatusLight>
    with SingleTickerProviderStateMixin {
  AnimationController? _pulseCtrl;
  Animation<double>? _pulseAnim;

  @override
  void initState() {
    super.initState();
    final def = getStatusLightDef(widget.light);
    if (widget.showPulse && def.pulse) {
      _pulseCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1600),
      )..repeat(reverse: false);
      _pulseAnim = Tween<double>(begin: 0.9, end: 1.35).animate(
        CurvedAnimation(parent: _pulseCtrl!, curve: Curves.easeInOut),
      );
    }
  }

  @override
  void dispose() {
    _pulseCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final def = getStatusLightDef(widget.light);
    final shouldPulse = widget.showPulse && def.pulse && _pulseAnim != null;

    final dot = Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: def.color,
        boxShadow: widget.showGlow
            ? [
                BoxShadow(
                  color: def.glow,
                  blurRadius: widget.size * 0.6,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
    );

    Widget inner = SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          if (shouldPulse)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _pulseAnim!,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnim!.value,
                    child: Opacity(
                      opacity: 0.55 - ((_pulseAnim!.value - 0.9) / 0.45) * 0.4,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: def.color, width: 2),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          dot,
        ],
      ),
    );

    if (widget.onTap != null) {
      inner = GestureDetector(onTap: widget.onTap, child: inner);
    }
    if (widget.tooltip != null && widget.tooltip!.isNotEmpty) {
      inner = Tooltip(message: widget.tooltip!, child: inner);
    }
    return inner;
  }
}

class StatusBadge extends StatelessWidget {
  final String? status;
  final String? label;
  final StatusLightColor? light;
  final String type;
  final bool showLight;
  final double lightSize;
  final EdgeInsetsGeometry padding;
  final TextStyle? textStyle;
  final double borderRadius;
  final VoidCallback? onTap;

  const StatusBadge({
    super.key,
    this.status,
    this.label,
    this.light,
    this.type = 'order',
    this.showLight = true,
    this.lightSize = 8,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    this.textStyle,
    this.borderRadius = 999,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedLight = light ?? resolveStatusLight(status, type: type);
    final def = getStatusLightDef(resolvedLight);
    final displayLabel = label ?? status ?? def.label;

    final effectiveTextStyle = textStyle ??
        TextStyle(
          color: def.text,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        );

    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: def.bg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: def.border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showLight) ...[
            StatusLight(light: resolvedLight, size: lightSize),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              displayLabel,
              style: effectiveTextStyle,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: content);
    }
    return content;
  }
}

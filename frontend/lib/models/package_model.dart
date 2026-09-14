class PackageModel {
  final int id;
  final String packageCode;
  final String qrToken;
  final String productName;
  final double expectedWeight;
  final double? actualWeight;
  final String unit;
  final String status;
  final String currentLeg;
  bool isScanned;

  PackageModel({
    required this.id,
    required this.packageCode,
    required this.qrToken,
    required this.productName,
    required this.expectedWeight,
    this.actualWeight,
    this.unit = 'KG',
    required this.status,
    required this.currentLeg,
    this.isScanned = false,
  });

  factory PackageModel.fromJson(Map<String, dynamic> json) {
    return PackageModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      packageCode: json['packageCode'] ?? json['package_code'] ?? 'PKG-01',
      qrToken: json['qrToken'] ?? json['qr_token'] ?? '',
      productName: json['productName'] ?? json['product_name'] ?? 'Grain Package',
      expectedWeight: (json['expectedWeight'] ?? json['expected_weight'] as num?)?.toDouble() ?? 5.0,
      actualWeight: (json['actualWeight'] ?? json['actual_weight'] as num?)?.toDouble(),
      unit: json['unit'] ?? 'KG',
      status: json['status'] ?? 'CREATED',
      currentLeg: json['currentLeg'] ?? json['current_leg'] ?? 'LEG_1',
      isScanned: json['isScanned'] == true || ['PICKED_UP_FROM_CUSTOMER', 'RECEIVED_AT_MILL', 'PICKED_UP_FROM_MILL', 'DELIVERED'].contains(json['status']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'packageCode': packageCode,
      'qrToken': qrToken,
      'productName': productName,
      'expectedWeight': expectedWeight,
      'actualWeight': actualWeight,
      'unit': unit,
      'status': status,
      'currentLeg': currentLeg,
      'isScanned': isScanned,
    };
  }
}

class PackageScanResult {
  final bool isSuccess;
  final bool isDuplicate;
  final String message;
  final PackageModel? package;
  final int scannedCount;
  final int totalPackages;
  final bool isAllScanned;
  final String nextAction;

  PackageScanResult({
    required this.isSuccess,
    required this.isDuplicate,
    required this.message,
    this.package,
    required this.scannedCount,
    required this.totalPackages,
    required this.isAllScanned,
    required this.nextAction,
  });

  factory PackageScanResult.fromJson(Map<String, dynamic> json) {
    final pkgData = json['package'] as Map<String, dynamic>?;
    final progress = json['progress'] as Map<String, dynamic>? ?? {};

    return PackageScanResult(
      isSuccess: json['status'] == 'success',
      isDuplicate: json['isDuplicate'] == true || json['scanResult'] == 'DUPLICATE',
      message: json['message'] ?? 'Scan recorded',
      package: pkgData != null ? PackageModel.fromJson(pkgData) : null,
      scannedCount: (progress['scannedCount'] as num?)?.toInt() ?? 0,
      totalPackages: (progress['totalPackages'] as num?)?.toInt() ?? 1,
      isAllScanned: progress['isAllScanned'] == true,
      nextAction: json['nextAction'] ?? 'SCAN_NEXT_PACKAGE',
    );
  }
}

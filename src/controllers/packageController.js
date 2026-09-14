const { pool } = require('../config/database');

/**
 * @route   POST /api/v1/packages/scan
 * @desc    Idempotent Smart Package QR Scanning API with audit logging
 * @access  Protected (DELIVERY, SHOPKEEPER, ADMIN)
 */
exports.scanPackage = async (req, res) => {
  const connection = await pool.getConnection();
  try {
    const { qrToken, packageCode, taskId, scanType, latitude, longitude, actualWeight } = req.body;
    const userId = req.user.id;
    const userRole = req.user.role;

    if (!qrToken && !packageCode) {
      return res.status(400).json({
        status: 'error',
        code: 'MISSING_QR_DATA',
        message: 'qrToken or packageCode is required.'
      });
    }

    if (!scanType || !['PICKUP', 'MILL_INTAKE', 'MILL_DISPATCH', 'DELIVERY'].includes(scanType)) {
      return res.status(400).json({
        status: 'error',
        code: 'INVALID_SCAN_TYPE',
        message: 'scanType must be one of: PICKUP, MILL_INTAKE, MILL_DISPATCH, DELIVERY.'
      });
    }

    await connection.beginTransaction();

    // 1. Fetch package by QR token or package code
    const [packages] = await connection.query(
      `SELECT p.*, o.order_number, o.mill_id, o.user_id as customer_id, o.status as order_status
       FROM packages p
       JOIN orders o ON p.order_id = o.id
       WHERE p.qr_token = ? OR p.package_code = ?
       FOR UPDATE`,
      [qrToken || packageCode, packageCode || qrToken]
    );

    if (packages.length === 0) {
      await connection.rollback();
      return res.status(404).json({
        status: 'error',
        code: 'INVALID_QR',
        message: 'Invalid QR code. No matching package found.'
      });
    }

    const pkg = packages[0];
    const orderId = pkg.order_id;

    // 2. Validate user role permissions
    if (scanType === 'MILL_INTAKE') {
      if (userRole !== 'SHOPKEEPER' && userRole !== 'ADMIN') {
        await connection.rollback();
        return res.status(403).json({
          status: 'error',
          code: 'UNAUTHORIZED_ACTOR',
          message: 'Only shopkeepers can scan packages for mill intake.'
        });
      }
      // Check mill ownership
      const [mills] = await connection.query('SELECT owner_user_id FROM mills WHERE id = ?', [pkg.mill_id]);
      if (mills.length > 0 && mills[0].owner_user_id !== userId && userRole !== 'ADMIN') {
        await connection.rollback();
        return res.status(403).json({
          status: 'error',
          code: 'WRONG_MILL',
          message: 'This package is assigned to a different mill.'
        });
      }
    } else {
      if (userRole !== 'DELIVERY' && userRole !== 'ADMIN') {
        await connection.rollback();
        return res.status(403).json({
          status: 'error',
          code: 'UNAUTHORIZED_ACTOR',
          message: 'Only delivery riders can scan packages for delivery steps.'
        });
      }
    }

    // 3. Handle Idempotency (Already scanned in target state)
    let isAlreadyScanned = false;
    let targetStatus = pkg.status;
    let nextLeg = pkg.current_leg;

    if (scanType === 'PICKUP') {
      if (pkg.status === 'PICKED_UP_FROM_CUSTOMER' || pkg.status === 'RECEIVED_AT_MILL' || pkg.status === 'PROCESSING') {
        isAlreadyScanned = true;
      } else if (['CREATED', 'READY_FOR_PICKUP'].includes(pkg.status)) {
        targetStatus = 'PICKED_UP_FROM_CUSTOMER';
        nextLeg = 'LEG_1';
      } else {
        await connection.rollback();
        return res.status(400).json({
          status: 'error',
          code: 'INVALID_TRANSITION',
          message: `Package status '${pkg.status}' cannot be transitioned via PICKUP scan.`
        });
      }
    } else if (scanType === 'MILL_INTAKE') {
      if (pkg.status === 'RECEIVED_AT_MILL' || pkg.status === 'PROCESSING') {
        isAlreadyScanned = true;
      } else if (pkg.status === 'PICKED_UP_FROM_CUSTOMER') {
        targetStatus = 'RECEIVED_AT_MILL';
        nextLeg = 'LEG_1';
      } else {
        await connection.rollback();
        return res.status(400).json({
          status: 'error',
          code: 'INVALID_TRANSITION',
          message: `Package status '${pkg.status}' cannot be scanned for mill intake.`
        });
      }
    } else if (scanType === 'MILL_DISPATCH') {
      if (pkg.status === 'PICKED_UP_FROM_MILL' || pkg.status === 'OUT_FOR_DELIVERY') {
        isAlreadyScanned = true;
      } else if (['READY_FOR_DELIVERY', 'PROCESSING'].includes(pkg.status)) {
        targetStatus = 'PICKED_UP_FROM_MILL';
        nextLeg = 'LEG_2';
      } else {
        await connection.rollback();
        return res.status(400).json({
          status: 'error',
          code: 'INVALID_TRANSITION',
          message: `Package status '${pkg.status}' is not ready for dispatch.`
        });
      }
    } else if (scanType === 'DELIVERY') {
      if (pkg.status === 'DELIVERED') {
        isAlreadyScanned = true;
      } else if (['PICKED_UP_FROM_MILL', 'OUT_FOR_DELIVERY'].includes(pkg.status)) {
        targetStatus = 'DELIVERED';
        nextLeg = 'COMPLETED';
      } else {
        await connection.rollback();
        return res.status(400).json({
          status: 'error',
          code: 'INVALID_TRANSITION',
          message: `Package status '${pkg.status}' cannot be completed via delivery scan.`
        });
      }
    }

    // 4. Log Scan Audit Event
    const scanResult = isAlreadyScanned ? 'DUPLICATE' : 'SUCCESS';
    const locationType = (scanType === 'MILL_INTAKE' || scanType === 'MILL_DISPATCH') ? 'MILL' : 'CUSTOMER';

    await connection.query(
      `INSERT INTO package_scan_events (package_id, order_id, scanned_by_user_id, location_type, scan_type, result, latitude, longitude, note)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [pkg.id, orderId, userId, locationType, scanType, scanResult, latitude || null, longitude || null, isAlreadyScanned ? 'Duplicate scan safely handled' : 'Verified scan']
    );

    // 5. Update package status if not duplicate
    if (!isAlreadyScanned) {
      const updateFields = ['status = ?', 'current_leg = ?'];
      const updateParams = [targetStatus, nextLeg];

      if (actualWeight !== undefined && actualWeight !== null) {
        updateFields.push('actual_weight = ?');
        updateParams.push(parseFloat(actualWeight));
      }

      updateParams.push(pkg.id);
      await connection.query(`UPDATE packages SET ${updateFields.join(', ')} WHERE id = ?`, updateParams);
    }

    // 6. Calculate progress for order packages
    const [allOrderPackages] = await connection.query(
      `SELECT id, package_code, product_name, expected_weight, actual_weight, status FROM packages WHERE order_id = ?`,
      [orderId]
    );

    const totalPackages = allOrderPackages.length;
    const scannedInTargetCount = allOrderPackages.filter(p => {
      if (scanType === 'PICKUP') return ['PICKED_UP_FROM_CUSTOMER', 'RECEIVED_AT_MILL', 'PROCESSING', 'READY_FOR_DELIVERY', 'PICKED_UP_FROM_MILL', 'OUT_FOR_DELIVERY', 'DELIVERED'].includes(p.status);
      if (scanType === 'MILL_INTAKE') return ['RECEIVED_AT_MILL', 'PROCESSING', 'READY_FOR_DELIVERY', 'PICKED_UP_FROM_MILL', 'OUT_FOR_DELIVERY', 'DELIVERED'].includes(p.status);
      if (scanType === 'MILL_DISPATCH') return ['PICKED_UP_FROM_MILL', 'OUT_FOR_DELIVERY', 'DELIVERED'].includes(p.status);
      if (scanType === 'DELIVERY') return p.status === 'DELIVERED';
      return false;
    }).length;

    await connection.commit();

    return res.status(200).json({
      status: 'success',
      message: isAlreadyScanned ? 'Package already verified.' : 'Package scanned successfully.',
      isDuplicate: isAlreadyScanned,
      scanResult,
      package: {
        id: pkg.id,
        packageCode: pkg.package_code,
        qrToken: pkg.qr_token,
        productName: pkg.product_name,
        expectedWeight: parseFloat(pkg.expected_weight),
        actualWeight: pkg.actual_weight ? parseFloat(pkg.actual_weight) : parseFloat(pkg.expected_weight),
        unit: pkg.unit,
        status: isAlreadyScanned ? pkg.status : targetStatus
      },
      order: {
        id: orderId,
        orderNumber: pkg.order_number
      },
      progress: {
        scannedCount: scannedInTargetCount,
        totalPackages,
        isAllScanned: scannedInTargetCount >= totalPackages
      },
      nextAction: scannedInTargetCount >= totalPackages ? 'COMPLETE_STEP' : 'SCAN_NEXT_PACKAGE'
    });

  } catch (err) {
    await connection.rollback();
    console.error('Error scanning package QR:', err);
    return res.status(500).json({
      status: 'error',
      message: 'Failed to process package scan: ' + err.message
    });
  } finally {
    connection.release();
  }
};

/**
 * @route   GET /api/v1/packages/order/:orderId
 * @desc    Get all packages for an order
 * @access  Protected
 */
exports.getOrderPackages = async (req, res) => {
  try {
    const { orderId } = req.params;
    const [packages] = await pool.query(
      `SELECT * FROM packages WHERE order_id = ? ORDER BY id ASC`,
      [orderId]
    );

    return res.status(200).json({
      status: 'success',
      data: {
        orderId: parseInt(orderId, 10),
        totalPackages: packages.length,
        packages: packages.map(p => ({
          id: p.id,
          packageCode: p.package_code,
          qrToken: p.qr_token,
          productName: p.product_name,
          expectedWeight: parseFloat(p.expected_weight),
          actualWeight: p.actual_weight ? parseFloat(p.actual_weight) : null,
          unit: p.unit,
          status: p.status,
          currentLeg: p.current_leg
        }))
      }
    });
  } catch (err) {
    console.error('Error fetching order packages:', err);
    return res.status(500).json({
      status: 'error',
      message: 'Failed to fetch packages: ' + err.message
    });
  }
};

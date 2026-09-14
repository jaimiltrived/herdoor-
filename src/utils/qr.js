const crypto = require('crypto');

const JWT_SECRET = process.env.JWT_SECRET || 'herdoor-secret-key';

/**
 * Generate a secure, signed QR token for a package.
 * Format: QR-<ORDER_NUMBER>-<INDEX>-<SIGNATURE>
 */
function generatePackageQrToken(orderNumber, packageIndex) {
  const payload = `PKG-${orderNumber}-${String(packageIndex).padStart(2, '0')}`;
  const hmac = crypto.createHmac('sha256', JWT_SECRET).update(payload).digest('hex').substring(0, 12);
  return `QR-${orderNumber}-${String(packageIndex).padStart(2, '0')}-${hmac.toUpperCase()}`;
}

/**
 * Verify if a QR token string matches expected format
 */
function isValidQrTokenFormat(token) {
  if (!token || typeof token !== 'string') return false;
  return token.startsWith('QR-') || token.startsWith('PKG-');
}

module.exports = {
  generatePackageQrToken,
  isValidQrTokenFormat
};

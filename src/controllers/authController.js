const bcrypt = require('bcryptjs');
const store = require('../store/dataStore');
const { generateToken } = require('../utils/jwt');
const { ROLES } = require('../constants/enums');

// In-memory OTP store: Map of identifier -> { otp, expiresAt, verified }
const otpStore = new Map();

// Helper to reliably find user by email or phone
function findUserByIdentifier(identifier) {
  if (!identifier) return null;
  const trimmed = String(identifier).trim();

  // If it looks like an email
  if (trimmed.includes('@')) {
    const emailLower = trimmed.toLowerCase();
    return store.users.find(u => u.email && u.email.toLowerCase() === emailLower);
  }

  // Otherwise, match by phone
  const digitsOnly = trimmed.replace(/\D/g, '');
  if (digitsOnly.length > 0) {
    return store.users.find(u => {
      if (!u.phone) return false;
      const userPhoneDigits = u.phone.replace(/\D/g, '');
      return userPhoneDigits === digitsOnly || (digitsOnly.length >= 10 && userPhoneDigits.endsWith(digitsOnly));
    });
  }

  return null;
}

/**
 * @desc User / Merchant / Rider Registration
 * @route POST /api/v1/auth/register
 */
exports.register = (req, res) => {
  const { name, email, phone, password, role = ROLES.CUSTOMER, vehicleNumber, vehicleType, millName } = req.body;

  if (!name || (!email && !phone) || !password) {
    return res.status(400).json({
      status: 'error',
      message: 'Name, password, and email or phone are required'
    });
  }

  // Check if user already exists
  const existingUser = store.users.find(u =>
    (email && u.email && u.email.toLowerCase() === email.toLowerCase()) ||
    (phone && u.phone && u.phone === phone)
  );

  if (existingUser) {
    return res.status(409).json({
      status: 'error',
      message: 'User with this email or phone already exists'
    });
  }

  const hashedPassword = bcrypt.hashSync(password, 8);
  const newUserId = store.users.length + 1;

  let millId = null;
  if (role === ROLES.SHOPKEEPER) {
    millId = 100 + store.mills.length + 1;
    store.mills.push({
      id: millId,
      ownerUserId: newUserId,
      name: millName || `${name}'s Flour Mill`,
      phone: phone || '+919876543299',
      address: 'Ahmedabad, Gujarat',
      latitude: 23.0225,
      longitude: 72.5714,
      rating: 5.0,
      totalRatings: 1,
      isOpen: true,
      estimatedTime: '30 min',
      capacityKgPerDay: 500,
      currentLoadKg: 0,
      services: ['Flour Grinding', 'Home Delivery'],
      workingHours: '08:00 AM - 08:00 PM'
    });
  }

  const newUser = {
    id: newUserId,
    name,
    email: email ? email.toLowerCase() : null,
    phone,
    password: hashedPassword,
    role,
    millId,
    vehicleNumber: vehicleNumber || null,
    vehicleType: vehicleType || 'Electric Scooter',
    isOnline: true,
    rating: 5.0,
    totalTrips: 0,
    profileImage: null,
    createdAt: new Date().toISOString()
  };

  store.users.push(newUser);

  const token = generateToken({
    id: newUser.id,
    name: newUser.name,
    email: newUser.email,
    role: newUser.role,
    millId: newUser.millId || null
  });

  res.status(201).json({
    status: 'success',
    message: 'User registered successfully',
    data: {
      user: {
        id: newUser.id,
        name: newUser.name,
        email: newUser.email,
        phone: newUser.phone,
        role: newUser.role,
        millId: newUser.millId || null
      },
      token
    }
  });
};

/**
 * @desc Unified Login for All Users (Customer, Merchant, Delivery, Admin)
 * @route POST /api/v1/auth/login
 */
exports.login = (req, res) => {
  const { email, phone, username, identifier, password, role } = req.body;
  const loginId = email || phone || username || identifier;

  if (!loginId || !password) {
    return res.status(400).json({
      status: 'error',
      message: 'Email/phone and password are required'
    });
  }

  const user = findUserByIdentifier(loginId);
  if (!user) {
    return res.status(401).json({
      status: 'error',
      message: 'Invalid email/phone or password'
    });
  }

  // Validate password
  const isMatch = bcrypt.compareSync(password, user.password);
  if (!isMatch) {
    return res.status(401).json({
      status: 'error',
      message: 'Invalid email/phone or password'
    });
  }

  // Validate requested role if provided
  if (role && user.role !== role && user.role !== ROLES.ADMIN) {
    return res.status(403).json({
      status: 'error',
      message: `Access denied. This account is registered as ${user.role}, not ${role}.`
    });
  }

  const token = generateToken({
    id: user.id,
    name: user.name,
    email: user.email,
    role: user.role,
    millId: user.millId || null
  });

  res.json({
    status: 'success',
    message: 'Logged in successfully',
    data: {
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        role: user.role,
        millId: user.millId || null,
        vehicleNumber: user.vehicleNumber || null,
        vehicleType: user.vehicleType || null,
        isOnline: user.isOnline ?? true,
        rating: user.rating || 4.8
      },
      token
    }
  });
};

/**
 * @desc User Logout
 * @route POST /api/v1/auth/logout
 */
exports.logout = (req, res) => {
  res.json({
    status: 'success',
    message: 'Logged out successfully'
  });
};

/**
 * @desc Refresh JWT Token
 * @route POST /api/v1/auth/refresh-token
 */
exports.refreshToken = (req, res) => {
  if (!req.user) {
    return res.status(401).json({ status: 'error', message: 'Unauthorized' });
  }

  const user = store.users.find(u => u.id === req.user.id);
  const newToken = generateToken({
    id: req.user.id,
    name: user ? user.name : req.user.name,
    email: user ? user.email : req.user.email,
    role: user ? user.role : req.user.role,
    millId: user ? user.millId : null
  });

  res.json({
    status: 'success',
    data: { token: newToken }
  });
};

/**
 * @desc Forgot Password - Send OTP
 * @route POST /api/v1/auth/forgot-password
 */
exports.forgotPassword = (req, res) => {
  const { email, phone, identifier } = req.body;
  const target = email || phone || identifier;

  if (!target) {
    return res.status(400).json({ status: 'error', message: 'Email or phone number is required' });
  }

  const user = findUserByIdentifier(target);
  if (!user) {
    return res.status(404).json({ status: 'error', message: 'No account found with this email or phone' });
  }

  const generatedOtp = '123456';
  const expiresAt = Date.now() + 10 * 60 * 1000; // 10 minutes

  if (user.email) {
    otpStore.set(user.email.toLowerCase(), {
      otp: generatedOtp,
      expiresAt,
      verified: false,
      userId: user.id
    });
  }

  if (user.phone) {
    otpStore.set(user.phone, {
      otp: generatedOtp,
      expiresAt,
      verified: false,
      userId: user.id
    });
  }

  res.json({
    status: 'success',
    message: `Password reset OTP has been sent to ${target}`,
    data: {
      identifier: target,
      otpHint: '123456',
      expiresInMinutes: 10
    }
  });
};

/**
 * @desc Verify OTP
 * @route POST /api/v1/auth/verify-otp
 */
exports.verifyOtp = (req, res) => {
  const { otp, email, phone, identifier } = req.body;
  const target = email || phone || identifier;

  if (!otp) {
    return res.status(400).json({ status: 'error', message: 'OTP is required' });
  }

  if (target) {
    const cleanTarget = String(target).trim().toLowerCase();
    const entry = otpStore.get(cleanTarget) || otpStore.get(target);

    if (!entry) {
      if (otp === '123456') {
        return res.json({
          status: 'success',
          message: 'OTP verified successfully',
          data: { verified: true, resetToken: 'RTKN_HERDOOR_VALIDATED' }
        });
      }
      return res.status(400).json({ status: 'error', message: 'Invalid or expired OTP. Please request a new code.' });
    }

    if (Date.now() > entry.expiresAt) {
      otpStore.delete(cleanTarget);
      return res.status(400).json({ status: 'error', message: 'OTP has expired. Please request a new one.' });
    }

    if (entry.otp !== String(otp).trim() && String(otp).trim() !== '123456') {
      return res.status(400).json({ status: 'error', message: 'Incorrect OTP entered' });
    }

    entry.verified = true;
    return res.json({
      status: 'success',
      message: 'OTP verified successfully',
      data: { verified: true, resetToken: `RTKN_${entry.userId}_${Date.now()}` }
    });
  }

  if (otp === '123456') {
    return res.json({
      status: 'success',
      message: 'OTP verified successfully',
      data: { verified: true }
    });
  }

  res.status(400).json({ status: 'error', message: 'Invalid OTP code' });
};

/**
 * @desc Resend OTP
 * @route POST /api/v1/auth/resend-otp
 */
exports.resendOtp = (req, res) => {
  const { email, phone, identifier } = req.body;
  const target = email || phone || identifier;

  if (!target) {
    return res.status(400).json({ status: 'error', message: 'Email or phone number is required' });
  }

  const generatedOtp = '123456';
  const expiresAt = Date.now() + 10 * 60 * 1000;

  otpStore.set(String(target).trim().toLowerCase(), {
    otp: generatedOtp,
    expiresAt,
    verified: false
  });

  res.json({
    status: 'success',
    message: `A new OTP code has been sent to ${target}`,
    data: { otpHint: '123456', expiresInMinutes: 10 }
  });
};

/**
 * @desc Reset Password with OTP Verification
 * @route POST /api/v1/auth/reset-password
 */
exports.resetPassword = (req, res) => {
  const { email, phone, identifier, otp, newPassword } = req.body;
  const target = email || phone || identifier;

  if (!newPassword || newPassword.length < 6) {
    return res.status(400).json({ status: 'error', message: 'New password must be at least 6 characters' });
  }

  let user = null;
  if (target) {
    user = findUserByIdentifier(target);
  }

  if (!user && target) {
    return res.status(404).json({ status: 'error', message: 'User account not found' });
  }

  if (target) {
    const entry = otpStore.get(String(target).trim().toLowerCase()) || otpStore.get(target);
    if (entry && entry.otp !== otp && otp !== '123456') {
      return res.status(400).json({ status: 'error', message: 'Invalid OTP' });
    }
  } else if (otp !== '123456') {
    return res.status(400).json({ status: 'error', message: 'Invalid OTP' });
  }

  if (!user) {
    user = store.users[0];
  }

  user.password = bcrypt.hashSync(newPassword, 8);
  if (target) {
    otpStore.delete(String(target).trim().toLowerCase());
  }

  res.json({
    status: 'success',
    message: 'Your password has been reset successfully. You can now log in with your new password.',
    data: { user: { id: user.id, email: user.email, phone: user.phone, name: user.name } }
  });
};

/**
 * @desc Send Mobile Login OTP
 * @route POST /api/v1/auth/send-otp
 */
exports.sendLoginOtp = (req, res) => {
  const { phone } = req.body;
  if (!phone) {
    return res.status(400).json({ status: 'error', message: 'Phone number is required' });
  }

  otpStore.set(phone, {
    otp: '123456',
    expiresAt: Date.now() + 10 * 60 * 1000,
    verified: false
  });

  res.json({
    status: 'success',
    message: `Login OTP sent to ${phone}`,
    data: { otpHint: '123456', expiresInMinutes: 10 }
  });
};

/**
 * @desc Login Directly With Mobile OTP
 * @route POST /api/v1/auth/login-otp
 */
exports.loginWithOtp = (req, res) => {
  const { phone, otp, name = 'New User', role = ROLES.CUSTOMER } = req.body;

  if (!phone || !otp) {
    return res.status(400).json({ status: 'error', message: 'Phone number and OTP are required' });
  }

  if (otp !== '123456') {
    const entry = otpStore.get(phone);
    if (!entry || entry.otp !== otp) {
      return res.status(400).json({ status: 'error', message: 'Invalid or expired OTP' });
    }
  }

  let user = findUserByIdentifier(phone);
  if (!user) {
    user = {
      id: store.users.length + 1,
      name,
      email: null,
      phone,
      password: bcrypt.hashSync('Password123!', 8),
      role,
      profileImage: null,
      createdAt: new Date().toISOString()
    };
    store.users.push(user);
  }

  const token = generateToken({
    id: user.id,
    name: user.name,
    email: user.email,
    role: user.role,
    millId: user.millId || null
  });

  res.json({
    status: 'success',
    message: 'Logged in successfully with OTP',
    data: {
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        role: user.role,
        millId: user.millId || null
      },
      token
    }
  });
};

/**
 * @desc Get Authenticated User Profile
 * @route GET /api/v1/auth/me
 */
exports.getMe = (req, res) => {
  const user = store.users.find(u => u.id === req.user.id);
  if (!user) {
    return res.status(404).json({ status: 'error', message: 'User not found' });
  }

  const { password, ...userWithoutPassword } = user;
  res.json({
    status: 'success',
    data: { user: userWithoutPassword }
  });
};

/**
 * @desc Change Password
 * @route PUT /api/v1/auth/change-password
 */
exports.changePassword = (req, res) => {
  const { currentPassword, newPassword } = req.body;
  const user = store.users.find(u => u.id === req.user.id);

  if (!user || !bcrypt.compareSync(currentPassword, user.password)) {
    return res.status(400).json({ status: 'error', message: 'Current password incorrect' });
  }

  user.password = bcrypt.hashSync(newPassword, 8);
  res.json({
    status: 'success',
    message: 'Password changed successfully'
  });
};

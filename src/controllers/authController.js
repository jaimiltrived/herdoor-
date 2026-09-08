const crypto = require('crypto');
const bcrypt = require('bcryptjs');
const store = require('../store/dataStore');
const { query } = require('../config/database');
const { generateToken } = require('../utils/jwt');
const { ROLES } = require('../constants/enums');

// In-memory OTP store: Map of identifier -> { otp, expiresAt, verified, userId }
const otpStore = new Map();

// Generate a secure 6-digit numeric OTP string
function generateSecureOtp() {
  // In development/test if explicitly set via env or fallback
  if (process.env.NODE_ENV === 'test') {
    return '123456';
  }
  return crypto.randomInt(100000, 1000000).toString();
}

// Helper to reliably find user by email or phone in DB first, then memory
async function findUserByIdentifier(identifier) {
  if (!identifier) return null;
  const trimmed = String(identifier).trim();
  const emailLower = trimmed.toLowerCase();
  const digitsOnly = trimmed.replace(/\D/g, '');

  // 1. Query MySQL database FIRST (Source of Truth)
  try {
    const rows = await query(
      'SELECT * FROM users WHERE LOWER(email) = ? OR phone = ? OR phone = ? LIMIT 1',
      [emailLower, trimmed, digitsOnly]
    );
    if (rows && rows.length > 0) {
      const dbUser = {
        id: rows[0].id,
        name: rows[0].name,
        email: rows[0].email,
        phone: rows[0].phone,
        password: rows[0].password,
        role: rows[0].role,
        millId: rows[0].mill_id || null,
        vehicleNumber: rows[0].vehicle_number || null,
        vehicleType: rows[0].vehicle_type || 'Electric Scooter',
        isOnline: Boolean(rows[0].is_online),
        rating: parseFloat(rows[0].rating || 5.0),
        totalTrips: parseInt(rows[0].total_trips || 0),
        profileImage: rows[0].profile_image || null,
        createdAt: rows[0].created_at ? new Date(rows[0].created_at).toISOString() : new Date().toISOString()
      };
      const idx = store.users.findIndex(u => u.id === dbUser.id || (u.email && u.email.toLowerCase() === emailLower));
      if (idx !== -1) {
        store.users[idx] = dbUser;
      } else {
        store.users.push(dbUser);
      }
      return dbUser;
    }
  } catch (err) {
    console.warn('MySQL findUserByIdentifier lookup warning:', err.message);
  }

  // 2. Search in memory store fallback
  if (trimmed.includes('@')) {
    const memUser = store.users.find(u => u.email && u.email.toLowerCase() === emailLower);
    if (memUser) return memUser;
  } else if (digitsOnly.length > 0) {
    const memUser = store.users.find(u => {
      if (!u.phone) return false;
      const userPhoneDigits = u.phone.replace(/\D/g, '');
      return userPhoneDigits === digitsOnly || (digitsOnly.length >= 10 && userPhoneDigits.endsWith(digitsOnly));
    });
    if (memUser) return memUser;
  }

  return null;
}

/**
 * @desc User / Merchant / Rider Registration
 * @route POST /api/v1/auth/register
 */
exports.register = async (req, res) => {
  const { name, email, phone, password, role = ROLES.CUSTOMER, vehicleNumber, vehicleType, millName } = req.body;

  if (!name || (!email && !phone) || !password) {
    return res.status(400).json({
      status: 'error',
      message: 'Name, password, and email or phone are required'
    });
  }

  // Whitelist allowable registration roles (disallow self-registering as ADMIN)
  const allowedRoles = [ROLES.CUSTOMER, ROLES.SHOPKEEPER, ROLES.DELIVERY];
  if (!allowedRoles.includes(role)) {
    return res.status(400).json({
      status: 'error',
      message: 'Invalid registration role. Admin accounts must be provisioned by super-admin.'
    });
  }

  if (password.length < 6) {
    return res.status(400).json({
      status: 'error',
      message: 'Password must be at least 6 characters long'
    });
  }

  // Check if user already exists in memory or DB
  const cleanEmail = email ? email.trim().toLowerCase() : null;
  const cleanPhone = phone ? phone.trim() : null;

  const existingUser = await findUserByIdentifier(cleanEmail || cleanPhone);
  if (existingUser) {
    return res.status(409).json({
      status: 'error',
      message: 'User with this email or phone already exists'
    });
  }

  const hashedPassword = bcrypt.hashSync(password, 10);
  let newUserId = store.users.length ? Math.max(...store.users.map(u => u.id)) + 1 : 10;

  let millId = null;
  if (role === ROLES.SHOPKEEPER) {
    millId = 100 + store.mills.length + 1;
    const newMill = {
      id: millId,
      ownerUserId: newUserId,
      name: millName || `${name}'s Flour Mill`,
      phone: cleanPhone || '+919876543299',
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
    };
    store.mills.push(newMill);

    try {
      const millSql = `
        INSERT INTO mills (name, phone, address, latitude, longitude, rating, total_ratings, is_open, estimated_time, capacity_kg_per_day, current_load_kg, working_hours)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `;
      const millDb = await query(millSql, [
        newMill.name, newMill.phone, newMill.address, newMill.latitude, newMill.longitude,
        5.0, 1, 1, '30 min', 500, 0, '08:00 AM - 08:00 PM'
      ]);
      if (millDb && millDb.insertId) {
        millId = millDb.insertId;
        newMill.id = millId;
      }
    } catch (mErr) {
      console.warn('MySQL Mill Insert Warning:', mErr.message);
    }
  }

  // Insert into MySQL Database
  try {
    const userSql = `
      INSERT INTO users (name, email, phone, password, role, mill_id, vehicle_number, vehicle_type, is_online, rating, total_trips, profile_image)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `;
    const userDb = await query(userSql, [
      name.trim(),
      cleanEmail,
      cleanPhone,
      hashedPassword,
      role,
      millId,
      vehicleNumber || null,
      vehicleType || 'Electric Scooter',
      1,
      5.0,
      0,
      null
    ]);
    if (userDb && userDb.insertId) {
      newUserId = userDb.insertId;
    }
  } catch (uErr) {
    console.error('MySQL User Insert Error:', uErr.message);
    return res.status(500).json({
      status: 'error',
      message: 'Failed to save user in database: ' + uErr.message
    });
  }

  const newUser = {
    id: newUserId,
    name: name.trim(),
    email: cleanEmail,
    phone: cleanPhone,
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
exports.login = async (req, res) => {
  const { email, phone, username, identifier, password, role } = req.body;
  const loginId = email || phone || username || identifier;

  if (!loginId || !password) {
    return res.status(400).json({
      status: 'error',
      message: 'Email/phone and password are required'
    });
  }

  const user = await findUserByIdentifier(loginId);
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
exports.refreshToken = async (req, res) => {
  if (!req.user) {
    return res.status(401).json({ status: 'error', message: 'Unauthorized' });
  }

  let user = store.users.find(u => u.id === req.user.id);
  if (!user) {
    user = await findUserByIdentifier(req.user.email || req.user.phone || req.user.id);
  }

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
exports.forgotPassword = async (req, res) => {
  const { email, phone, identifier } = req.body;
  const target = email || phone || identifier;

  if (!target) {
    return res.status(400).json({ status: 'error', message: 'Email or phone number is required' });
  }

  const user = await findUserByIdentifier(target);
  if (!user) {
    return res.status(404).json({ status: 'error', message: 'No account found with this email or phone' });
  }

  const generatedOtp = generateSecureOtp();
  const expiresAt = Date.now() + 10 * 60 * 1000; // 10 minutes

  const cleanTarget = String(target).trim().toLowerCase();
  const targetKey = cleanTarget.includes('@') ? cleanTarget : target.trim();

  otpStore.set(targetKey, {
    otp: generatedOtp,
    expiresAt,
    verified: false,
    userId: user.id
  });

  if (user.email && user.email.toLowerCase() !== targetKey) {
    otpStore.set(user.email.toLowerCase(), {
      otp: generatedOtp,
      expiresAt,
      verified: false,
      userId: user.id
    });
  }

  if (user.phone && user.phone !== targetKey) {
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
      otpHint: process.env.NODE_ENV === 'production' ? undefined : generatedOtp,
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

  if (!target) {
    return res.status(400).json({ status: 'error', message: 'Email or phone identifier is required' });
  }

  const cleanTarget = String(target).trim().toLowerCase();
  const rawTarget = String(target).trim();
  const entry = otpStore.get(cleanTarget) || otpStore.get(rawTarget);

  if (!entry) {
    return res.status(400).json({ status: 'error', message: 'Invalid or expired OTP. Please request a new code.' });
  }

  if (Date.now() > entry.expiresAt) {
    otpStore.delete(cleanTarget);
    otpStore.delete(rawTarget);
    return res.status(400).json({ status: 'error', message: 'OTP has expired. Please request a new one.' });
  }

  if (entry.otp !== String(otp).trim()) {
    return res.status(400).json({ status: 'error', message: 'Incorrect OTP entered' });
  }

  entry.verified = true;
  return res.json({
    status: 'success',
    message: 'OTP verified successfully',
    data: { verified: true, resetToken: `RTKN_${entry.userId}_${Date.now()}` }
  });
};

/**
 * @desc Resend OTP
 * @route POST /api/v1/auth/resend-otp
 */
exports.resendOtp = async (req, res) => {
  const { email, phone, identifier } = req.body;
  const target = email || phone || identifier;

  if (!target) {
    return res.status(400).json({ status: 'error', message: 'Email or phone number is required' });
  }

  const user = await findUserByIdentifier(target);
  if (!user) {
    return res.status(404).json({ status: 'error', message: 'No account found with this email or phone' });
  }

  const generatedOtp = generateSecureOtp();
  const expiresAt = Date.now() + 10 * 60 * 1000;
  const cleanTarget = String(target).trim().toLowerCase();
  const rawTarget = String(target).trim();

  otpStore.set(cleanTarget, {
    otp: generatedOtp,
    expiresAt,
    verified: false,
    userId: user.id
  });

  if (rawTarget !== cleanTarget) {
    otpStore.set(rawTarget, {
      otp: generatedOtp,
      expiresAt,
      verified: false,
      userId: user.id
    });
  }

  res.json({
    status: 'success',
    message: `A new OTP code has been sent to ${target}`,
    data: {
      otpHint: process.env.NODE_ENV === 'production' ? undefined : generatedOtp,
      expiresInMinutes: 10
    }
  });
};

/**
 * @desc Reset Password with OTP Verification
 * @route POST /api/v1/auth/reset-password
 */
exports.resetPassword = async (req, res) => {
  const { email, phone, identifier, otp, newPassword } = req.body;
  const target = email || phone || identifier;

  if (!target) {
    return res.status(400).json({ status: 'error', message: 'Email or phone identifier is required' });
  }

  if (!newPassword || newPassword.length < 6) {
    return res.status(400).json({ status: 'error', message: 'New password must be at least 6 characters' });
  }

  if (!otp) {
    return res.status(400).json({ status: 'error', message: 'OTP is required' });
  }

  const user = await findUserByIdentifier(target);
  if (!user) {
    return res.status(404).json({ status: 'error', message: 'User account not found' });
  }

  const cleanTarget = String(target).trim().toLowerCase();
  const rawTarget = String(target).trim();
  const entry = otpStore.get(cleanTarget) || otpStore.get(rawTarget);

  if (!entry) {
    return res.status(400).json({ status: 'error', message: 'Invalid or expired OTP. Please request a new code.' });
  }

  if (Date.now() > entry.expiresAt) {
    otpStore.delete(cleanTarget);
    otpStore.delete(rawTarget);
    return res.status(400).json({ status: 'error', message: 'OTP has expired. Please request a new one.' });
  }

  if (entry.otp !== String(otp).trim()) {
    return res.status(400).json({ status: 'error', message: 'Invalid OTP code' });
  }

  const hashedPassword = bcrypt.hashSync(newPassword, 10);
  user.password = hashedPassword;

  // Persist password update to MySQL Database
  try {
    await query('UPDATE users SET password = ? WHERE id = ?', [hashedPassword, user.id]);
  } catch (dbErr) {
    console.warn('MySQL Reset Password Warning:', dbErr.message);
  }

  // Cleanup OTP entries
  otpStore.delete(cleanTarget);
  otpStore.delete(rawTarget);

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

  const generatedOtp = generateSecureOtp();
  otpStore.set(phone.trim(), {
    otp: generatedOtp,
    expiresAt: Date.now() + 10 * 60 * 1000,
    verified: false
  });

  res.json({
    status: 'success',
    message: `Login OTP sent to ${phone}`,
    data: {
      otpHint: process.env.NODE_ENV === 'production' ? undefined : generatedOtp,
      expiresInMinutes: 10
    }
  });
};

/**
 * @desc Login Directly With Mobile OTP
 * @route POST /api/v1/auth/login-otp
 */
exports.loginWithOtp = async (req, res) => {
  const { phone, otp, name = 'New User', role = ROLES.CUSTOMER } = req.body;

  if (!phone || !otp) {
    return res.status(400).json({ status: 'error', message: 'Phone number and OTP are required' });
  }

  const cleanPhone = phone.trim();
  const entry = otpStore.get(cleanPhone);

  if (!entry || entry.otp !== String(otp).trim()) {
    return res.status(400).json({ status: 'error', message: 'Invalid or expired OTP' });
  }

  if (Date.now() > entry.expiresAt) {
    otpStore.delete(cleanPhone);
    return res.status(400).json({ status: 'error', message: 'OTP has expired. Please request a new one.' });
  }

  // Cleanup OTP after successful consumption
  otpStore.delete(cleanPhone);

  let user = await findUserByIdentifier(cleanPhone);
  if (!user) {
    const defaultHashedPassword = bcrypt.hashSync(crypto.randomBytes(16).toString('hex'), 10);
    let newUserId = store.users.length ? Math.max(...store.users.map(u => u.id)) + 1 : 1;

    try {
      const userDb = await query(
        `INSERT INTO users (name, email, phone, password, role, is_online, rating, total_trips)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
        [name.trim(), null, cleanPhone, defaultHashedPassword, role, 1, 5.0, 0]
      );
      if (userDb && userDb.insertId) {
        newUserId = userDb.insertId;
      }
    } catch (uErr) {
      console.warn('MySQL User Insert (OTP Login) Warning:', uErr.message);
    }

    user = {
      id: newUserId,
      name: name.trim(),
      email: null,
      phone: cleanPhone,
      password: defaultHashedPassword,
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
exports.getMe = async (req, res) => {
  let user = store.users.find(u => u.id === req.user.id);
  if (!user) {
    user = await findUserByIdentifier(req.user.email || req.user.phone || req.user.id);
  }

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
exports.changePassword = async (req, res) => {
  const { currentPassword, newPassword } = req.body;

  if (!currentPassword || !newPassword) {
    return res.status(400).json({ status: 'error', message: 'Current password and new password are required' });
  }

  if (newPassword.length < 6) {
    return res.status(400).json({ status: 'error', message: 'New password must be at least 6 characters long' });
  }

  let user = store.users.find(u => u.id === req.user.id);
  if (!user) {
    user = await findUserByIdentifier(req.user.email || req.user.phone || req.user.id);
  }

  if (!user || !bcrypt.compareSync(currentPassword, user.password)) {
    return res.status(400).json({ status: 'error', message: 'Current password incorrect' });
  }

  const hashedPassword = bcrypt.hashSync(newPassword, 10);
  user.password = hashedPassword;

  // Persist password change to MySQL Database
  try {
    await query('UPDATE users SET password = ? WHERE id = ?', [hashedPassword, user.id]);
  } catch (dbErr) {
    console.warn('MySQL Change Password Warning:', dbErr.message);
  }

  res.json({
    status: 'success',
    message: 'Password changed successfully'
  });
};


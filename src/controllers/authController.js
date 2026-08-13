const bcrypt = require('bcryptjs');
const store = require('../store/dataStore');
const { generateToken } = require('../utils/jwt');
const { ROLES } = require('../constants/enums');

exports.register = (req, res) => {
  const { name, email, phone, password, role = ROLES.CUSTOMER } = req.body;

  if (!name || (!email && !phone) || !password) {
    return res.status(400).json({
      status: 'error',
      message: 'Name, password, and email or phone are required'
    });
  }

  const existingUser = store.users.find(u => u.email === email || u.phone === phone);
  if (existingUser) {
    return res.status(409).json({
      status: 'error',
      message: 'User with this email or phone already exists'
    });
  }

  const hashedPassword = bcrypt.hashSync(password, 8);
  const newUser = {
    id: store.users.length + 1,
    name,
    email,
    phone,
    password: hashedPassword,
    role,
    profileImage: null,
    createdAt: new Date().toISOString()
  };

  store.users.push(newUser);

  const token = generateToken({
    id: newUser.id,
    name: newUser.name,
    email: newUser.email,
    role: newUser.role
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
        role: newUser.role
      },
      token
    }
  });
};

exports.login = (req, res) => {
  const { email, phone, password } = req.body;

  if ((!email && !phone) || !password) {
    return res.status(400).json({
      status: 'error',
      message: 'Email/phone and password are required'
    });
  }

  const user = store.users.find(u => (email && u.email === email) || (phone && u.phone === phone));
  if (!user) {
    return res.status(401).json({
      status: 'error',
      message: 'Invalid credentials'
    });
  }

  const isMatch = bcrypt.compareSync(password, user.password);
  if (!isMatch) {
    return res.status(401).json({
      status: 'error',
      message: 'Invalid credentials'
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
        millId: user.millId || null
      },
      token
    }
  });
};

exports.logout = (req, res) => {
  res.json({
    status: 'success',
    message: 'Logged out successfully'
  });
};

exports.refreshToken = (req, res) => {
  if (!req.user) {
    return res.status(401).json({ status: 'error', message: 'Unauthorized' });
  }

  const newToken = generateToken({
    id: req.user.id,
    name: req.user.name,
    email: req.user.email,
    role: req.user.role,
    millId: req.user.millId || null
  });

  res.json({
    status: 'success',
    data: { token: newToken }
  });
};

exports.forgotPassword = (req, res) => {
  const { email, phone } = req.body;
  res.json({
    status: 'success',
    message: `Password reset OTP sent to ${email || phone}`
  });
};

exports.resetPassword = (req, res) => {
  const { otp, newPassword } = req.body;
  res.json({
    status: 'success',
    message: 'Password reset successful'
  });
};

exports.verifyOtp = (req, res) => {
  const { otp } = req.body;
  res.json({
    status: 'success',
    message: 'OTP verified successfully',
    data: { verified: true }
  });
};

exports.resendOtp = (req, res) => {
  res.json({
    status: 'success',
    message: 'OTP resent successfully'
  });
};

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

const store = require('../store/dataStore');
const { query } = require('../config/database');

exports.getProfile = (req, res) => {
  const user = store.users.find(u => u.id === req.user.id);
  if (!user) {
    return res.status(404).json({ status: 'error', message: 'User not found' });
  }
  const { password, ...userWithoutPassword } = user;
  res.json({ status: 'success', data: { user: userWithoutPassword } });
};

exports.updateProfile = (req, res) => {
  const user = store.users.find(u => u.id === req.user.id);
  if (!user) {
    return res.status(404).json({ status: 'error', message: 'User not found' });
  }

  const { name, phone } = req.body;
  if (name) user.name = name;
  if (phone) user.phone = phone;

  const { password, ...updatedUser } = user;
  res.json({ status: 'success', message: 'Profile updated', data: { user: updatedUser } });
};

exports.uploadProfileImage = (req, res) => {
  const user = store.users.find(u => u.id === req.user.id);
  if (!user) {
    return res.status(404).json({ status: 'error', message: 'User not found' });
  }

  const { imageUrl } = req.body;
  user.profileImage = imageUrl || 'https://via.placeholder.com/150';

  res.json({ status: 'success', message: 'Profile image updated', data: { profileImage: user.profileImage } });
};

exports.getFavorites = async (req, res) => {
  const userId = req.user ? req.user.id : 1;
  try {
    const sql = `
      SELECT m.* 
      FROM mills m
      INNER JOIN user_favorites uf ON m.id = uf.mill_id
      WHERE uf.user_id = ?
      ORDER BY uf.created_at DESC
    `;
    const dbMills = await query(sql, [userId]);
    if (dbMills && dbMills.length > 0) {
      const mapped = dbMills.map(row => ({
        id: row.id,
        name: row.name,
        address: row.address,
        latitude: parseFloat(row.latitude || 23.0225),
        longitude: parseFloat(row.longitude || 72.5714),
        phone: row.phone,
        rating: parseFloat(row.rating || 4.9),
        reviewCount: parseInt(row.review_count || 128),
        specialty: row.specialty || 'Specialist in Stone Grounding',
        imageUrl: row.image_url || 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=600&q=80',
        distanceKm: parseFloat(row.distance_km || 0.8),
        isFavorite: true
      }));
      return res.json({
        status: 'success',
        count: mapped.length,
        data: { favorites: mapped }
      });
    }
  } catch (err) {
    console.warn('MySQL getFavorites fallback:', err.message);
  }

  const favIds = store.favorites ? store.favorites.filter(f => f.userId === userId).map(f => f.millId) : [101, 102];
  const favs = store.mills.filter(m => favIds.includes(m.id)).map(m => ({ ...m, isFavorite: true }));
  res.json({
    status: 'success',
    count: favs.length,
    data: { favorites: favs }
  });
};

exports.addFavorite = async (req, res) => {
  const userId = req.user ? req.user.id : 1;
  const millId = parseInt(req.params.millId);

  try {
    await query('INSERT IGNORE INTO user_favorites (user_id, mill_id) VALUES (?, ?)', [userId, millId]);
  } catch (err) {
    console.warn('MySQL addFavorite warning:', err.message);
  }

  if (!store.favorites) store.favorites = [];
  if (!store.favorites.some(f => f.userId === userId && f.millId === millId)) {
    store.favorites.push({ userId, millId });
  }

  res.status(201).json({ status: 'success', message: 'Added to favorites', data: { millId } });
};

exports.removeFavorite = async (req, res) => {
  const userId = req.user ? req.user.id : 1;
  const millId = parseInt(req.params.millId);

  try {
    await query('DELETE FROM user_favorites WHERE user_id = ? AND mill_id = ?', [userId, millId]);
  } catch (err) {
    console.warn('MySQL removeFavorite warning:', err.message);
  }

  if (store.favorites) {
    store.favorites = store.favorites.filter(f => !(f.userId === userId && f.millId === millId));
  }

  res.json({ status: 'success', message: 'Removed from favorites', data: { millId } });
};

exports.getAddresses = (req, res) => {
  const userAddresses = store.addresses.filter(a => a.userId === req.user.id);
  res.json({ status: 'success', data: { addresses: userAddresses } });
};

exports.addAddress = (req, res) => {
  const { addressLine1, addressLine2, city, state, pincode, latitude, longitude, isDefault } = req.body;

  if (!addressLine1 || !city || !pincode) {
    return res.status(400).json({ status: 'error', message: 'Address line 1, city and pincode are required' });
  }

  const newAddress = {
    id: store.addresses.length + 1,
    userId: req.user.id,
    addressLine1,
    addressLine2: addressLine2 || '',
    city,
    state: state || 'Gujarat',
    pincode,
    latitude: latitude || 23.0225,
    longitude: longitude || 72.5714,
    isDefault: !!isDefault
  };

  if (newAddress.isDefault) {
    store.addresses.filter(a => a.userId === req.user.id).forEach(a => a.isDefault = false);
  }

  store.addresses.push(newAddress);
  res.status(201).json({ status: 'success', message: 'Address added', data: { address: newAddress } });
};

exports.updateAddress = (req, res) => {
  const addressId = parseInt(req.params.id);
  const address = store.addresses.find(a => a.id === addressId && a.userId === req.user.id);

  if (!address) {
    return res.status(404).json({ status: 'error', message: 'Address not found' });
  }

  Object.assign(address, req.body);
  res.json({ status: 'success', message: 'Address updated', data: { address } });
};

exports.deleteAddress = (req, res) => {
  const addressId = parseInt(req.params.id);
  const index = store.addresses.findIndex(a => a.id === addressId && a.userId === req.user.id);

  if (index === -1) {
    return res.status(404).json({ status: 'error', message: 'Address not found' });
  }

  store.addresses.splice(index, 1);
  res.json({ status: 'success', message: 'Address deleted' });
};

exports.setDefaultAddress = (req, res) => {
  const addressId = parseInt(req.params.id);
  const userAddresses = store.addresses.filter(a => a.userId === req.user.id);
  const targetAddress = userAddresses.find(a => a.id === addressId);

  if (!targetAddress) {
    return res.status(404).json({ status: 'error', message: 'Address not found' });
  }

  userAddresses.forEach(a => a.isDefault = false);
  targetAddress.isDefault = true;

  res.json({ status: 'success', message: 'Default address updated', data: { address: targetAddress } });
};

/**
 * @desc Apply to become a Shopkeeper / Merchant
 * @route POST /api/v1/users/apply-merchant
 */
exports.applyMerchant = async (req, res) => {
  const userId = req.user ? req.user.id : 1;
  const user = store.users.find(u => u.id === userId);

  const {
    storeName,
    phone,
    email,
    address,
    city,
    state,
    pincode,
    latitude,
    longitude,
    capacityKgPerDay,
    deliveryRadiusKm,
    workingHours,
    services,
    specialty,
    storeImage,
    licenseDocument,
    licenseNumber
  } = req.body;

  if (!storeName || !address) {
    return res.status(400).json({
      status: 'error',
      message: 'Store name and address are required'
    });
  }

  // Ensure merchantApplications list exists
  if (!store.merchantApplications) {
    store.merchantApplications = [];
  }

  // Check if existing pending application exists
  const existingApp = store.merchantApplications.find(
    app => app.userId === userId && app.status === 'PENDING'
  );
  if (existingApp) {
    return res.status(400).json({
      status: 'error',
      message: 'You already have a pending merchant application under review.',
      data: { application: existingApp }
    });
  }

  // Cloudinary upload helper
  const { uploadToCloudinary } = require('../config/cloudinary');
  let finalStoreImage = storeImage || 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=600&q=80';
  let finalLicenseDoc = licenseDocument || 'https://images.unsplash.com/photo-1589829545856-d10d557cf95f?auto=format&fit=crop&w=600&q=80';

  if (storeImage && (storeImage.startsWith('data:') || storeImage.startsWith('file:') || storeImage.length > 200)) {
    const resImg = await uploadToCloudinary(storeImage, 'herdoor/stores');
    finalStoreImage = resImg.url;
  }
  if (licenseDocument && (licenseDocument.startsWith('data:') || licenseDocument.startsWith('file:') || licenseDocument.length > 200)) {
    const resDoc = await uploadToCloudinary(licenseDocument, 'herdoor/licenses');
    finalLicenseDoc = resDoc.url;
  }

  const newApp = {
    id: `APP-${Date.now()}`,
    userId,
    applicantName: user ? user.name : 'Applicant',
    applicantPhone: phone || (user ? user.phone : '+919876543210'),
    applicantEmail: email || (user ? user.email : 'applicant@herdoor.com'),
    storeName,
    phone: phone || (user ? user.phone : '+919876543210'),
    address,
    city: city || 'Ahmedabad',
    state: state || 'Gujarat',
    pincode: pincode || '380015',
    latitude: parseFloat(latitude) || 23.0225,
    longitude: parseFloat(longitude) || 72.5714,
    capacityKgPerDay: parseFloat(capacityKgPerDay) || 500,
    deliveryRadiusKm: parseFloat(deliveryRadiusKm) || 5.0,
    workingHours: workingHours || '08:00 AM - 08:00 PM',
    services: Array.isArray(services) && services.length > 0 ? services : ['Flour Grinding', 'Packing', 'Home Delivery'],
    specialty: specialty || 'Fresh Whole Grain Flour & Custom Milling',
    storeImage: finalStoreImage,
    licenseDocument: finalLicenseDoc,
    licenseNumber: licenseNumber || `FSSAI-${Math.floor(10000000 + Math.random() * 90000000)}`,
    status: 'PENDING',
    adminNotes: 'Application submitted and queued for verification.',
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString()
  };

  store.merchantApplications.unshift(newApp);

  res.status(201).json({
    status: 'success',
    message: 'Merchant application submitted successfully! It is currently under review by admin.',
    data: { application: newApp }
  });
};

/**
 * @desc Get User's Latest Merchant Application Status
 * @route GET /api/v1/users/my-merchant-application
 */
exports.getMyMerchantApplication = (req, res) => {
  const userId = req.user ? req.user.id : 1;
  const applications = (store.merchantApplications || []).filter(app => app.userId === userId);
  
  const latestApp = applications.length > 0 ? applications[0] : null;

  res.json({
    status: 'success',
    data: {
      hasApplied: !!latestApp,
      application: latestApp,
      isShopkeeper: req.user?.role === 'SHOPKEEPER' || (store.users.find(u => u.id === userId)?.role === 'SHOPKEEPER')
    }
  });
};


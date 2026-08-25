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

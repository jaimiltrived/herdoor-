const store = require('../store/dataStore');

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

const store = require('../store/dataStore');
const { calculateDistance } = require('../utils/geo');

exports.getNearbyMills = (req, res) => {
  const { latitude, longitude, radius = 10 } = req.query;

  if (!latitude || !longitude) {
    return res.status(400).json({
      status: 'error',
      message: 'Latitude and longitude parameters are required'
    });
  }

  const userLat = parseFloat(latitude);
  const userLon = parseFloat(longitude);
  const maxRadius = parseFloat(radius);

  const nearby = store.mills
    .map(mill => {
      const distance = calculateDistance(userLat, userLon, mill.latitude, mill.longitude);
      return {
        millId: mill.id,
        name: mill.name,
        address: mill.address,
        distance,
        rating: mill.rating,
        totalRatings: mill.totalRatings,
        isOpen: mill.isOpen,
        estimatedTime: mill.estimatedTime,
        services: mill.services,
        latitude: mill.latitude,
        longitude: mill.longitude
      };
    })
    .filter(m => m.distance <= maxRadius)
    .sort((a, b) => a.distance - b.distance);

  res.json({
    status: 'success',
    count: nearby.length,
    data: { mills: nearby }
  });
};

exports.getMills = (req, res) => {
  const { search, isOpen } = req.query;
  let result = [...store.mills];

  if (search) {
    const term = search.toLowerCase();
    result = result.filter(m => m.name.toLowerCase().includes(term) || m.address.toLowerCase().includes(term));
  }

  if (isOpen !== undefined) {
    const openBool = isOpen === 'true';
    result = result.filter(m => m.isOpen === openBool);
  }

  res.json({
    status: 'success',
    count: result.length,
    data: { mills: result }
  });
};

exports.getMillById = (req, res) => {
  const millId = parseInt(req.params.millId);
  const mill = store.mills.find(m => m.id === millId);

  if (!mill) {
    return res.status(404).json({ status: 'error', message: 'Mill not found' });
  }

  res.json({ status: 'success', data: { mill } });
};

exports.getMillServices = (req, res) => {
  const millId = parseInt(req.params.millId);
  const mill = store.mills.find(m => m.id === millId);

  if (!mill) {
    return res.status(404).json({ status: 'error', message: 'Mill not found' });
  }

  res.json({ status: 'success', data: { services: mill.services } });
};

exports.getMillGrains = (req, res) => {
  const millId = parseInt(req.params.millId);
  const mill = store.mills.find(m => m.id === millId);

  if (!mill) {
    return res.status(404).json({ status: 'error', message: 'Mill not found' });
  }

  res.json({ status: 'success', data: { grains: store.grainTypes } });
};

exports.getMillProducts = (req, res) => {
  const millId = parseInt(req.params.millId);
  const products = store.readymadeProducts || [];
  res.json({
    status: 'success',
    count: products.length,
    data: { products }
  });
};

exports.getMillAvailability = (req, res) => {
  const millId = parseInt(req.params.millId);
  const mill = store.mills.find(m => m.id === millId);

  if (!mill) {
    return res.status(404).json({ status: 'error', message: 'Mill not found' });
  }

  res.json({
    status: 'success',
    data: {
      millId: mill.id,
      isOpen: mill.isOpen,
      estimatedTime: mill.estimatedTime,
      servicesAvailable: mill.services
    }
  });
};

exports.getMillWorkingHours = (req, res) => {
  const millId = parseInt(req.params.millId);
  const mill = store.mills.find(m => m.id === millId);

  if (!mill) {
    return res.status(404).json({ status: 'error', message: 'Mill not found' });
  }

  res.json({
    status: 'success',
    data: {
      millId: mill.id,
      workingHours: mill.workingHours
    }
  });
};

exports.getMillRatings = (req, res) => {
  const millId = parseInt(req.params.millId);
  const mill = store.mills.find(m => m.id === millId);

  if (!mill) {
    return res.status(404).json({ status: 'error', message: 'Mill not found' });
  }

  const millReviews = store.reviews.filter(r => r.millId === millId);

  res.json({
    status: 'success',
    data: {
      millId: mill.id,
      rating: mill.rating,
      totalRatings: mill.totalRatings,
      reviews: millReviews
    }
  });
};

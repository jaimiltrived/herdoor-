const store = require('../store/dataStore');
const { query } = require('../config/database');
const { calculateDistance } = require('../utils/geo');

exports.getNearbyMills = async (req, res) => {
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

  let millsList = [];
  try {
    const dbMills = await query('SELECT * FROM mills');
    if (dbMills && Array.isArray(dbMills)) {
      millsList = dbMills.map(m => ({
        id: m.id,
        name: m.name,
        address: m.address,
        phone: m.phone,
        latitude: parseFloat(m.latitude),
        longitude: parseFloat(m.longitude),
        rating: parseFloat(m.rating) || 4.8,
        totalRatings: parseInt(m.total_ratings) || 100,
        isOpen: Boolean(m.is_open),
        estimatedTime: m.estimated_time || '30-45 min',
        specialty: m.specialty || 'Fresh Stone Ground Flour',
        workingHours: m.working_hours || '08:00 AM - 08:00 PM'
      }));
    }
  } catch (err) {
    console.warn('MySQL getNearbyMills warning:', err.message);
    millsList = store.mills;
  }

  const nearby = millsList
    .map(mill => {
      const distance = calculateDistance(userLat, userLon, mill.latitude, mill.longitude);
      return {
        millId: mill.id,
        id: mill.id,
        name: mill.name,
        address: mill.address,
        distance,
        rating: mill.rating,
        totalRatings: mill.totalRatings,
        isOpen: mill.isOpen,
        estimatedTime: mill.estimatedTime,
        services: mill.services || ['Flour Grinding', 'Home Delivery'],
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

exports.getMills = async (req, res) => {
  const { search, isOpen } = req.query;
  let result = [];
  try {
    let sql = 'SELECT * FROM mills WHERE 1=1';
    const params = [];
    if (isOpen !== undefined) {
      sql += ' AND is_open = ?';
      params.push(isOpen === 'true' ? 1 : 0);
    }
    if (search) {
      sql += ' AND (name LIKE ? OR address LIKE ?)';
      params.push(`%${search}%`, `%${search}%`);
    }
    const dbMills = await query(sql, params);
    if (dbMills && Array.isArray(dbMills)) {
      result = dbMills.map(m => ({
        id: m.id,
        name: m.name,
        address: m.address,
        phone: m.phone,
        latitude: parseFloat(m.latitude),
        longitude: parseFloat(m.longitude),
        rating: parseFloat(m.rating) || 4.8,
        totalRatings: parseInt(m.total_ratings) || 100,
        isOpen: Boolean(m.is_open),
        estimatedTime: m.estimated_time || '30-45 min',
        specialty: m.specialty || 'Fresh Stone Ground Flour',
        workingHours: m.working_hours || '08:00 AM - 08:00 PM'
      }));
    }
  } catch (err) {
    console.warn('MySQL getMills warning:', err.message);
    result = store.mills;
  }

  res.json({
    status: 'success',
    count: result.length,
    data: { mills: result }
  });
};

exports.getMillById = async (req, res) => {
  const millId = parseInt(req.params.millId);
  try {
    const dbMills = await query('SELECT * FROM mills WHERE id = ?', [millId]);
    if (dbMills && dbMills.length > 0) {
      const m = dbMills[0];
      const services = await query('SELECT service_name FROM mill_services WHERE mill_id = ?', [millId]);
      return res.json({
        status: 'success',
        data: {
          mill: {
            id: m.id,
            name: m.name,
            address: m.address,
            phone: m.phone,
            latitude: parseFloat(m.latitude),
            longitude: parseFloat(m.longitude),
            rating: parseFloat(m.rating) || 4.8,
            totalRatings: parseInt(m.total_ratings) || 100,
            isOpen: Boolean(m.is_open),
            estimatedTime: m.estimated_time || '30-45 min',
            specialty: m.specialty || 'Fresh Stone Ground Flour',
            workingHours: m.working_hours || '08:00 AM - 08:00 PM',
            services: services ? services.map(s => s.service_name) : []
          }
        }
      });
    }
  } catch (err) {
    console.warn('MySQL getMillById warning:', err.message);
  }

  const mill = store.mills.find(m => m.id === millId);
  if (!mill) {
    return res.status(404).json({ status: 'error', message: 'Mill not found' });
  }
  res.json({ status: 'success', data: { mill } });
};

exports.getMillServices = async (req, res) => {
  const millId = parseInt(req.params.millId);
  try {
    const services = await query('SELECT service_name FROM mill_services WHERE mill_id = ?', [millId]);
    if (services && Array.isArray(services)) {
      return res.json({ status: 'success', data: { services: services.map(s => s.service_name) } });
    }
  } catch (err) {
    console.warn('MySQL getMillServices warning:', err.message);
  }
  const mill = store.mills.find(m => m.id === millId);
  res.json({ status: 'success', data: { services: mill ? mill.services : [] } });
};

exports.getMillGrains = async (req, res) => {
  try {
    const grains = await query('SELECT * FROM grain_types');
    if (grains && Array.isArray(grains)) {
      return res.json({
        status: 'success',
        data: {
          grains: grains.map(g => ({
            id: g.id,
            name: g.name,
            category: g.category,
            pricePerKg: parseFloat(g.price_per_kg),
            grindingFeePerKg: parseFloat(g.grinding_fee_per_kg)
          }))
        }
      });
    }
  } catch (err) {
    console.warn('MySQL getMillGrains warning:', err.message);
  }
  res.json({ status: 'success', data: { grains: store.grainTypes } });
};

exports.getMillProducts = async (req, res) => {
  const millId = parseInt(req.params.millId);
  try {
    const inv = await query('SELECT * FROM inventory WHERE mill_id = ?', [millId]);
    if (inv && Array.isArray(inv)) {
      return res.json({
        status: 'success',
        count: inv.length,
        data: {
          products: inv.map(i => ({
            id: i.id.toString(),
            millId: i.mill_id,
            name: i.name,
            category: i.product_type,
            price: parseFloat(i.price_per_kg),
            stockQuantity: parseFloat(i.stock_kg)
          }))
        }
      });
    }
  } catch (err) {
    console.warn('MySQL getMillProducts warning:', err.message);
  }
  const products = store.readymadeProducts || [];
  res.json({
    status: 'success',
    count: products.length,
    data: { products }
  });
};

exports.getMillAvailability = async (req, res) => {
  const millId = parseInt(req.params.millId);
  try {
    const dbMills = await query('SELECT is_open, estimated_time FROM mills WHERE id = ?', [millId]);
    if (dbMills && dbMills.length > 0) {
      return res.json({
        status: 'success',
        data: {
          millId,
          isOpen: Boolean(dbMills[0].is_open),
          estimatedTime: dbMills[0].estimated_time || '30-45 min'
        }
      });
    }
  } catch (err) {}
  const mill = store.mills.find(m => m.id === millId);
  res.json({
    status: 'success',
    data: {
      millId,
      isOpen: mill ? mill.isOpen : true,
      estimatedTime: mill ? mill.estimatedTime : '30-45 min'
    }
  });
};

exports.getMillWorkingHours = (req, res) => {
  const millId = parseInt(req.params.millId);
  const mill = store.mills.find(m => m.id === millId);
  res.json({
    status: 'success',
    data: {
      millId,
      workingHours: mill ? mill.workingHours : '08:00 AM - 08:00 PM'
    }
  });
};

exports.getMillRatings = async (req, res) => {
  const millId = parseInt(req.params.millId);
  try {
    const reviews = await query('SELECT * FROM reviews WHERE mill_id = ?', [millId]);
    const millRes = await query('SELECT rating, total_ratings FROM mills WHERE id = ?', [millId]);
    return res.json({
      status: 'success',
      data: {
        millId,
        rating: millRes && millRes[0] ? parseFloat(millRes[0].rating) : 4.8,
        totalRatings: millRes && millRes[0] ? parseInt(millRes[0].total_ratings) : 100,
        reviews: reviews || []
      }
    });
  } catch (err) {
    const millReviews = store.reviews.filter(r => r.millId === millId);
    res.json({
      status: 'success',
      data: {
        millId,
        rating: 4.8,
        totalRatings: 100,
        reviews: millReviews
      }
    });
  }
};

const store = require('../store/dataStore');
const { query } = require('../config/database');
const { calculateDistance } = require('../utils/geo');

exports.getNearbyMills = async (req, res) => {
  const { latitude, longitude, radius = 10, category, search } = req.query;

  if (!latitude || !longitude) {
    return res.status(400).json({
      status: 'error',
      message: 'Latitude and longitude parameters are required'
    });
  }

  const userLat = parseFloat(latitude);
  const userLon = parseFloat(longitude);
  const maxRadius = parseFloat(radius) || 10;
  const latDelta = maxRadius / 111.0;
  const cosLat = Math.cos(userLat * (Math.PI / 180));
  const lonDelta = maxRadius / (111.0 * (cosLat === 0 ? 1 : Math.abs(cosLat)));
  const minLat = userLat - latDelta;
  const maxLat = userLat + latDelta;
  const minLon = userLon - lonDelta;
  const maxLon = userLon + lonDelta;

  let millsList = [];
  try {
    let sql = 'SELECT * FROM mills WHERE latitude BETWEEN ? AND ? AND longitude BETWEEN ? AND ?';
    const params = [minLat, maxLat, minLon, maxLon];

    if (category && category.trim() !== '' && category.trim().toLowerCase() !== 'all') {
      sql += ' AND (LOWER(specialty) LIKE ? OR LOWER(name) LIKE ?)';
      params.push(`%${category.trim().toLowerCase()}%`, `%${category.trim().toLowerCase()}%`);
    }

    if (search && search.trim() !== '') {
      sql += ' AND (LOWER(name) LIKE ? OR LOWER(specialty) LIKE ? OR LOWER(address) LIKE ?)';
      params.push(`%${search.trim().toLowerCase()}%`, `%${search.trim().toLowerCase()}%`, `%${search.trim().toLowerCase()}%`);
    }

    sql += ' LIMIT 50';

    const dbMills = await query(sql, params);
    if (dbMills && Array.isArray(dbMills) && dbMills.length > 0) {
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
    } else {
      // Fallback to all in-memory mills if DB returned 0
      millsList = store.mills;
    }
  } catch (err) {
    console.warn('MySQL getNearbyMills warning:', err.message);
    millsList = store.mills;
  }

  let nearby = millsList
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
        specialty: mill.specialty || 'Fresh Stone Ground Flour',
        latitude: mill.latitude,
        longitude: mill.longitude
      };
    })
    .filter(m => m.distance <= maxRadius)
    .sort((a, b) => a.distance - b.distance);

  if (category && category.trim() !== '' && category.trim().toLowerCase() !== 'all') {
    const catLower = category.trim().toLowerCase();
    nearby = nearby.filter(m => {
      const specialty = (m.specialty || '').toLowerCase();
      const name = (m.name || '').toLowerCase();
      const services = (m.services || []).join(' ').toLowerCase();
      return specialty.includes(catLower) || name.includes(catLower) || services.includes(catLower);
    });
  }

  if (search && search.trim() !== '') {
    const searchLower = search.trim().toLowerCase();
    nearby = nearby.filter(m => {
      const specialty = (m.specialty || '').toLowerCase();
      const name = (m.name || '').toLowerCase();
      const address = (m.address || '').toLowerCase();
      return name.includes(searchLower) || specialty.includes(searchLower) || address.includes(searchLower);
    });
  }

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

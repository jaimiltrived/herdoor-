const store = require('../store/dataStore');
const { query } = require('../config/database');

exports.getGrainSources = async (req, res) => {
  try {
    const sources = await query('SELECT * FROM grain_sources');
    if (sources && Array.isArray(sources)) {
      return res.json({
        status: 'success',
        data: { grainSources: sources }
      });
    }
  } catch (err) {}
  res.json({
    status: 'success',
    data: { grainSources: store.grainSources }
  });
};

exports.getGrainSourceById = async (req, res) => {
  const id = parseInt(req.params.id);
  try {
    const sources = await query('SELECT * FROM grain_sources WHERE id = ?', [id]);
    if (sources && sources.length > 0) {
      return res.json({ status: 'success', data: { grainSource: sources[0] } });
    }
  } catch (err) {}
  const source = store.grainSources.find(s => s.id === id);
  if (!source) {
    return res.status(404).json({ status: 'error', message: 'Grain source not found' });
  }
  res.json({ status: 'success', data: { grainSource: source } });
};

exports.getGrainTypes = async (req, res) => {
  try {
    const grains = await query('SELECT * FROM grain_types');
    if (grains && Array.isArray(grains)) {
      return res.json({
        status: 'success',
        data: {
          grainTypes: grains.map(g => ({
            id: g.id,
            name: g.name,
            category: g.category,
            pricePerKg: parseFloat(g.price_per_kg),
            grindingFeePerKg: parseFloat(g.grinding_fee_per_kg)
          }))
        }
      });
    }
  } catch (err) {}
  res.json({
    status: 'success',
    data: { grainTypes: store.grainTypes }
  });
};

exports.getGrainTypeById = async (req, res) => {
  const id = parseInt(req.params.id);
  try {
    const grains = await query('SELECT * FROM grain_types WHERE id = ?', [id]);
    if (grains && grains.length > 0) {
      const g = grains[0];
      return res.json({
        status: 'success',
        data: {
          grainType: {
            id: g.id,
            name: g.name,
            category: g.category,
            pricePerKg: parseFloat(g.price_per_kg),
            grindingFeePerKg: parseFloat(g.grinding_fee_per_kg)
          }
        }
      });
    }
  } catch (err) {}
  const grain = store.grainTypes.find(g => g.id === id);
  if (!grain) {
    return res.status(404).json({ status: 'error', message: 'Grain type not found' });
  }
  res.json({ status: 'success', data: { grainType: grain } });
};

exports.getMillGrainTypes = async (req, res) => {
  const millId = parseInt(req.params.millId);
  try {
    const grains = await query('SELECT * FROM grain_types');
    if (grains && Array.isArray(grains)) {
      return res.json({
        status: 'success',
        data: {
          millId,
          grainTypes: grains.map(g => ({
            id: g.id,
            name: g.name,
            category: g.category,
            pricePerKg: parseFloat(g.price_per_kg),
            grindingFeePerKg: parseFloat(g.grinding_fee_per_kg)
          }))
        }
      });
    }
  } catch (err) {}
  res.json({
    status: 'success',
    data: {
      millId,
      grainTypes: store.grainTypes
    }
  });
};

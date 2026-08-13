const store = require('../store/dataStore');

exports.getGrainSources = (req, res) => {
  res.json({
    status: 'success',
    data: { grainSources: store.grainSources }
  });
};

exports.getGrainSourceById = (req, res) => {
  const id = parseInt(req.params.id);
  const source = store.grainSources.find(s => s.id === id);

  if (!source) {
    return res.status(404).json({ status: 'error', message: 'Grain source not found' });
  }

  res.json({ status: 'success', data: { grainSource: source } });
};

exports.getGrainTypes = (req, res) => {
  res.json({
    status: 'success',
    data: { grainTypes: store.grainTypes }
  });
};

exports.getGrainTypeById = (req, res) => {
  const id = parseInt(req.params.id);
  const grain = store.grainTypes.find(g => g.id === id);

  if (!grain) {
    return res.status(404).json({ status: 'error', message: 'Grain type not found' });
  }

  res.json({ status: 'success', data: { grainType: grain } });
};

exports.getMillGrainTypes = (req, res) => {
  const millId = parseInt(req.params.millId);
  const mill = store.mills.find(m => m.id === millId);

  if (!mill) {
    return res.status(404).json({ status: 'error', message: 'Mill not found' });
  }

  res.json({
    status: 'success',
    data: {
      millId,
      grainTypes: store.grainTypes
    }
  });
};

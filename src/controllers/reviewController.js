const store = require('../store/dataStore');

exports.submitReview = (req, res) => {
  const orderId = parseInt(req.params.orderId);
  const { rating, review } = req.body;

  if (!rating) {
    return res.status(400).json({ status: 'error', message: 'Rating is required' });
  }

  const order = store.orders.find(o => o.id === orderId);
  if (!order) {
    return res.status(404).json({ status: 'error', message: 'Order not found' });
  }

  const existing = store.reviews.find(r => r.orderId === orderId);
  if (existing) {
    return res.status(409).json({ status: 'error', message: 'Review already submitted for this order' });
  }

  const newReview = {
    id: store.reviews.length + 1,
    orderId,
    userId: req.user.id,
    userName: req.user.name || 'Customer',
    millId: order.millId,
    rating: parseInt(rating),
    review: review || '',
    createdAt: new Date().toISOString()
  };

  store.reviews.push(newReview);

  // Update Mill average rating
  const mill = store.mills.find(m => m.id === order.millId);
  if (mill) {
    const millReviews = store.reviews.filter(r => r.millId === mill.id);
    const sum = millReviews.reduce((acc, r) => acc + r.rating, 0);
    mill.rating = parseFloat((sum / millReviews.length).toFixed(1));
    mill.totalRatings = millReviews.length;
  }

  res.status(201).json({
    status: 'success',
    message: 'Review submitted successfully',
    data: { review: newReview }
  });
};

exports.getOrderReview = (req, res) => {
  const orderId = parseInt(req.params.orderId);
  const review = store.reviews.find(r => r.orderId === orderId);

  if (!review) {
    return res.status(404).json({ status: 'error', message: 'No review found for this order' });
  }

  res.json({ status: 'success', data: { review } });
};

exports.updateReview = (req, res) => {
  const reviewId = parseInt(req.params.reviewId);
  const review = store.reviews.find(r => r.id === reviewId && r.userId === req.user.id);

  if (!review) {
    return res.status(404).json({ status: 'error', message: 'Review not found or unauthorized' });
  }

  if (req.body.rating) review.rating = parseInt(req.body.rating);
  if (req.body.review !== undefined) review.review = req.body.review;

  res.json({ status: 'success', message: 'Review updated', data: { review } });
};

exports.deleteReview = (req, res) => {
  const reviewId = parseInt(req.params.reviewId);
  const index = store.reviews.findIndex(r => r.id === reviewId && r.userId === req.user.id);

  if (index === -1) {
    return res.status(404).json({ status: 'error', message: 'Review not found or unauthorized' });
  }

  store.reviews.splice(index, 1);
  res.json({ status: 'success', message: 'Review deleted' });
};

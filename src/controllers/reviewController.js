const store = require('../store/dataStore');
const { query } = require('../config/database');

exports.submitReview = async (req, res) => {
  const orderId = parseInt(req.params.orderId);
  const { rating, review } = req.body;

  if (!rating) {
    return res.status(400).json({ status: 'error', message: 'Rating is required' });
  }

  let millId = 101;
  try {
    const dbOrders = await query('SELECT * FROM orders WHERE id = ?', [orderId]);
    if (!dbOrders || dbOrders.length === 0) {
      const memOrder = store.orders.find(o => o.id === orderId);
      if (!memOrder) {
        return res.status(404).json({ status: 'error', message: 'Order not found' });
      }
      millId = memOrder.millId;
    } else {
      millId = dbOrders[0].mill_id;
    }

    const existingDb = await query('SELECT id FROM reviews WHERE order_id = ?', [orderId]);
    if (existingDb && existingDb.length > 0) {
      return res.status(409).json({ status: 'error', message: 'Review already submitted for this order' });
    }

    const insertSql = 'INSERT INTO reviews (order_id, user_id, user_name, mill_id, rating, review, created_at) VALUES (?, ?, ?, ?, ?, ?, NOW())';
    const userName = req.user.name || 'Customer';
    const insertRes = await query(insertSql, [orderId, req.user.id || 1, userName, millId, parseInt(rating), review || '']);

    const newReview = {
      id: insertRes ? insertRes.insertId : 1,
      orderId,
      userId: req.user.id || 1,
      userName: userName,
      millId,
      rating: parseInt(rating),
      review: review || '',
      createdAt: new Date().toISOString()
    };

    return res.status(201).json({
      status: 'success',
      message: 'Review submitted successfully in database',
      data: { review: newReview }
    });
  } catch (err) {
    console.warn('MySQL submitReview warning:', err.message);
  }

  const order = store.orders.find(o => o.id === orderId);
  if (!order) {
    return res.status(404).json({ status: 'error', message: 'Order not found' });
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

  res.status(201).json({
    status: 'success',
    message: 'Review submitted successfully',
    data: { review: newReview }
  });
};

exports.getOrderReview = async (req, res) => {
  const orderId = parseInt(req.params.orderId);
  try {
    const dbReviews = await query('SELECT * FROM reviews WHERE order_id = ?', [orderId]);
    if (dbReviews && dbReviews.length > 0) {
      const r = dbReviews[0];
      return res.json({
        status: 'success',
        data: {
          review: {
            id: r.id,
            orderId: r.order_id,
            userId: r.user_id,
            millId: r.mill_id,
            rating: r.rating,
            review: r.review,
            createdAt: r.created_at
          }
        }
      });
    }
  } catch (err) {}

  const review = store.reviews.find(r => r.orderId === orderId);
  if (!review) {
    return res.status(404).json({ status: 'error', message: 'No review found for this order' });
  }

  res.json({ status: 'success', data: { review } });
};

exports.updateReview = async (req, res) => {
  const reviewId = parseInt(req.params.reviewId);
  try {
    await query('UPDATE reviews SET rating = ?, review = ? WHERE id = ? AND user_id = ?', [
      req.body.rating,
      req.body.review,
      reviewId,
      req.user.id
    ]);
  } catch (err) {}

  res.json({ status: 'success', message: 'Review updated' });
};

exports.deleteReview = async (req, res) => {
  const reviewId = parseInt(req.params.reviewId);
  try {
    await query('DELETE FROM reviews WHERE id = ? AND user_id = ?', [reviewId, req.user.id]);
  } catch (err) {}
  res.json({ status: 'success', message: 'Review deleted' });
};

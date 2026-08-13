const store = require('../store/dataStore');

exports.createPayment = (req, res) => {
  const { orderId, amount, paymentMethod = 'UPI' } = req.body;

  if (!orderId || !amount) {
    return res.status(400).json({ status: 'error', message: 'orderId and amount are required' });
  }

  const order = store.orders.find(o => o.id === parseInt(orderId));
  if (!order) {
    return res.status(404).json({ status: 'error', message: 'Order not found' });
  }

  const payment = {
    id: `PAY-${Date.now()}`,
    orderId: parseInt(orderId),
    amount: parseFloat(amount),
    paymentMethod,
    status: 'CREATED',
    transactionId: `TXN_${Math.random().toString(36).substr(2, 9).toUpperCase()}`,
    createdAt: new Date().toISOString()
  };

  store.payments.push(payment);

  res.status(201).json({
    status: 'success',
    message: 'Payment created',
    data: { payment }
  });
};

exports.verifyPayment = (req, res) => {
  const { paymentId, transactionId } = req.body;
  const payment = store.payments.find(p => p.id === paymentId);

  if (!payment) {
    return res.status(404).json({ status: 'error', message: 'Payment not found' });
  }

  payment.status = 'SUCCESS';
  if (transactionId) payment.transactionId = transactionId;

  // Update order status to paid
  const order = store.orders.find(o => o.id === payment.orderId);
  if (order) {
    order.paymentStatus = 'PAID';
  }

  res.json({
    status: 'success',
    message: 'Payment verified successfully',
    data: { payment }
  });
};

exports.getPaymentById = (req, res) => {
  const payment = store.payments.find(p => p.id === req.params.paymentId);
  if (!payment) {
    return res.status(404).json({ status: 'error', message: 'Payment not found' });
  }
  res.json({ status: 'success', data: { payment } });
};

exports.getOrderPayment = (req, res) => {
  const orderId = parseInt(req.params.orderId);
  const payment = store.payments.find(p => p.orderId === orderId);

  if (!payment) {
    return res.status(404).json({ status: 'error', message: 'Payment record not found for this order' });
  }
  res.json({ status: 'success', data: { payment } });
};

exports.refundPayment = (req, res) => {
  const payment = store.payments.find(p => p.id === req.params.paymentId);
  if (!payment) {
    return res.status(404).json({ status: 'error', message: 'Payment not found' });
  }

  payment.status = 'REFUNDED';
  res.json({
    status: 'success',
    message: 'Refund initiated successfully',
    data: { refundId: `REF-${Date.now()}`, payment }
  });
};

exports.getRefundStatus = (req, res) => {
  const payment = store.payments.find(p => p.id === req.params.paymentId);
  if (!payment) {
    return res.status(404).json({ status: 'error', message: 'Payment not found' });
  }

  res.json({
    status: 'success',
    data: {
      paymentId: payment.id,
      status: payment.status === 'REFUNDED' ? 'REFUND_COMPLETED' : 'NO_REFUND'
    }
  });
};

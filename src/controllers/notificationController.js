const store = require('../store/dataStore');

exports.getNotifications = (req, res) => {
  const userNotifications = store.notifications.filter(n => n.userId === req.user.id);
  res.json({ status: 'success', count: userNotifications.length, data: { notifications: userNotifications } });
};

exports.getUnreadNotifications = (req, res) => {
  const unread = store.notifications.filter(n => n.userId === req.user.id && !n.read);
  res.json({ status: 'success', count: unread.length, data: { notifications: unread } });
};

exports.markAsRead = (req, res) => {
  const id = parseInt(req.params.id);
  const notification = store.notifications.find(n => n.id === id && n.userId === req.user.id);

  if (!notification) {
    return res.status(404).json({ status: 'error', message: 'Notification not found' });
  }

  notification.read = true;
  res.json({ status: 'success', message: 'Notification marked read', data: { notification } });
};

exports.markAllAsRead = (req, res) => {
  store.notifications.filter(n => n.userId === req.user.id).forEach(n => n.read = true);
  res.json({ status: 'success', message: 'All notifications marked as read' });
};

exports.deleteNotification = (req, res) => {
  const id = parseInt(req.params.id);
  const index = store.notifications.findIndex(n => n.id === id && n.userId === req.user.id);

  if (index === -1) {
    return res.status(404).json({ status: 'error', message: 'Notification not found' });
  }

  store.notifications.splice(index, 1);
  res.json({ status: 'success', message: 'Notification deleted' });
};

exports.registerDevice = (req, res) => {
  const { fcmToken, deviceType = 'ANDROID' } = req.body;

  if (!fcmToken) {
    return res.status(400).json({ status: 'error', message: 'fcmToken is required' });
  }

  const device = {
    id: store.devices.length + 1,
    userId: req.user.id,
    fcmToken,
    deviceType
  };

  store.devices.push(device);
  res.status(201).json({ status: 'success', message: 'Device token registered', data: { device } });
};

exports.unregisterDevice = (req, res) => {
  const id = parseInt(req.params.id);
  const index = store.devices.findIndex(d => d.id === id && d.userId === req.user.id);

  if (index !== -1) {
    store.devices.splice(index, 1);
  }

  res.json({ status: 'success', message: 'Device token removed' });
};

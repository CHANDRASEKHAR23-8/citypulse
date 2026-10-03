const express = require('express');
const router = express.Router();
const db = require('../config/db');
const { authenticate } = require('../middleware/auth');

router.use(authenticate);

// GET /notifications - Get notifications for logged-in user
router.get('/', (req, res, next) => {
  try {
    const notifications = db.prepare(`
      SELECT n.*, c.category, c.status as complaint_status
      FROM notifications n
      LEFT JOIN complaints c ON n.complaint_id = c.id
      WHERE n.user_id = ?
      ORDER BY n.created_at DESC
    `).all(req.user.id);

    const unreadCount = notifications.filter(n => n.is_read === 0).length;

    res.json({
      success: true,
      unreadCount,
      count: notifications.length,
      notifications
    });
  } catch (err) {
    next(err);
  }
});

// PATCH /notifications/:id/read - Mark notification as read
router.patch('/:id/read', (req, res, next) => {
  try {
    const id = parseInt(req.params.id);

    const notif = db.prepare('SELECT * FROM notifications WHERE id = ? AND user_id = ?').get(id, req.user.id);
    if (!notif) {
      return res.status(404).json({
        success: false,
        error: 'Notification not found.'
      });
    }

    db.prepare('UPDATE notifications SET is_read = 1 WHERE id = ?').run(id);

    res.json({
      success: true,
      message: 'Notification marked as read'
    });
  } catch (err) {
    next(err);
  }
});

// PATCH /notifications/read-all - Mark all notifications as read
router.patch('/read-all', (req, res, next) => {
  try {
    db.prepare('UPDATE notifications SET is_read = 1 WHERE user_id = ?').run(req.user.id);

    res.json({
      success: true,
      message: 'All notifications marked as read'
    });
  } catch (err) {
    next(err);
  }
});

module.exports = router;

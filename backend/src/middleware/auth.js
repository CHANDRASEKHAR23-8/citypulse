const jwt = require('jsonwebtoken');
const { JWT_SECRET } = require('../config/constants');
const db = require('../config/db');

function authenticate(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({
      success: false,
      error: 'Authentication required. Missing or malformed Bearer token.'
    });
  }

  const token = authHeader.split(' ')[1];
  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    const user = db.prepare('SELECT id, name, email, role, department FROM users WHERE id = ?').get(decoded.id);

    if (!user) {
      return res.status(401).json({
        success: false,
        error: 'User account no longer exists.'
      });
    }

    req.user = user;
    next();
  } catch (err) {
    return res.status(401).json({
      success: false,
      error: 'Invalid or expired token.'
    });
  }
}

module.exports = { authenticate };

const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const db = require('../config/db');
const { JWT_SECRET, JWT_EXPIRES_IN, ROLES, DEPARTMENTS } = require('../config/constants');
const { authenticate } = require('../middleware/auth');

// POST /auth/register
router.post('/register', async (req, res, next) => {
  try {
    const { name, email, password, role = ROLES.CITIZEN, department } = req.body;

    if (!name || !email || !password) {
      return res.status(400).json({
        success: false,
        error: 'Name, email, and password are required.'
      });
    }

    if (![ROLES.CITIZEN, ROLES.OFFICER, ROLES.ADMIN].includes(role)) {
      return res.status(400).json({
        success: false,
        error: `Invalid role. Must be one of: ${Object.values(ROLES).join(', ')}`
      });
    }

    if (role === ROLES.OFFICER && (!department || !DEPARTMENTS.includes(department))) {
      return res.status(400).json({
        success: false,
        error: `Valid department is required for officers. Choose from: ${DEPARTMENTS.join(', ')}`
      });
    }

    const existingUser = db.prepare('SELECT id FROM users WHERE email = ?').get(email.toLowerCase().trim());
    if (existingUser) {
      return res.status(400).json({
        success: false,
        error: 'An account with this email address already exists.'
      });
    }

    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(password, salt);

    const result = db.prepare(`
      INSERT INTO users (name, email, password_hash, role, department)
      VALUES (?, ?, ?, ?, ?)
    `).run(
      name.trim(),
      email.toLowerCase().trim(),
      passwordHash,
      role,
      role === ROLES.OFFICER ? department : (department || null)
    );

    const user = {
      id: result.lastInsertRowid,
      name: name.trim(),
      email: email.toLowerCase().trim(),
      role,
      department: role === ROLES.OFFICER ? department : (department || null)
    };

    const token = jwt.sign(
      { id: user.id, email: user.email, role: user.role },
      JWT_SECRET,
      { expiresIn: JWT_EXPIRES_IN }
    );

    return res.status(201).json({
      success: true,
      message: 'Registration successful',
      token,
      user
    });
  } catch (err) {
    next(err);
  }
});

// POST /auth/login
router.post('/login', async (req, res, next) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        success: false,
        error: 'Email and password are required.'
      });
    }

    const userRecord = db.prepare('SELECT * FROM users WHERE email = ?').get(email.toLowerCase().trim());
    if (!userRecord) {
      return res.status(401).json({
        success: false,
        error: 'Invalid email or password.'
      });
    }

    const isMatch = await bcrypt.compare(password, userRecord.password_hash);
    if (!isMatch) {
      return res.status(401).json({
        success: false,
        error: 'Invalid email or password.'
      });
    }

    const user = {
      id: userRecord.id,
      name: userRecord.name,
      email: userRecord.email,
      role: userRecord.role,
      department: userRecord.department
    };

    const token = jwt.sign(
      { id: user.id, email: user.email, role: user.role },
      JWT_SECRET,
      { expiresIn: JWT_EXPIRES_IN }
    );

    return res.json({
      success: true,
      message: 'Login successful',
      token,
      user
    });
  } catch (err) {
    next(err);
  }
});

// GET /auth/me
router.get('/me', authenticate, (req, res) => {
  res.json({
    success: true,
    user: req.user
  });
});

module.exports = router;

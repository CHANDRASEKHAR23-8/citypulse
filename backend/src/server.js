const express = require('express');
const cors = require('cors');
const path = require('path');
const dotenv = require('dotenv');

dotenv.config();

const { initSchema } = require('./db/schema');
const { errorHandler } = require('./middleware/error');

const authRoutes = require('./routes/auth.routes');
const complaintRoutes = require('./routes/complaint.routes');
const officerRoutes = require('./routes/officer.routes');
const adminRoutes = require('./routes/admin.routes');
const notificationRoutes = require('./routes/notification.routes');

// Initialize SQLite schema
initSchema();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PATCH', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Serve static uploaded images
const uploadsDir = path.join(__dirname, '..', 'uploads');
app.use('/uploads', express.static(uploadsDir));

// Root & Health
app.get('/api', (req, res) => {
  res.json({
    name: 'CityPulse Backend API',
    status: 'online',
    version: '1.0.0',
    documentation: {
      auth: ['POST /auth/register', 'POST /auth/login', 'GET /auth/me'],
      complaints: ['POST /complaints', 'GET /complaints', 'GET /complaints/mine', 'GET /complaints/:id', 'POST /complaints/:id/support', 'PATCH /complaints/:id/status'],
      officer: ['GET /officer/complaints'],
      admin: ['GET /admin/complaints', 'PATCH /admin/complaints/:id/assign', 'GET /admin/users', 'PATCH /admin/users/:id', 'GET /admin/stats'],
      notifications: ['GET /notifications', 'PATCH /notifications/:id/read', 'PATCH /notifications/read-all']
    }
  });
});

app.get('/health', (req, res) => {
  res.json({ status: 'healthy', uptime: process.uptime() });
});

// Mount Routes
app.use('/auth', authRoutes);
app.use('/complaints', complaintRoutes);
app.use('/officer', officerRoutes);
app.use('/admin', adminRoutes);
app.use('/notifications', notificationRoutes);

// Serve Flutter Web Frontend if built
const fs = require('fs');
const webDir = path.join(__dirname, '..', '..', 'frontend', 'build', 'web');
if (fs.existsSync(webDir)) {
  app.use(express.static(webDir));
  app.get('*', (req, res, next) => {
    if (req.accepts('html') && fs.existsSync(path.join(webDir, 'index.html'))) {
      res.sendFile(path.join(webDir, 'index.html'));
    } else {
      next();
    }
  });
}

// 404 Route
app.use('*', (req, res) => {
  res.status(404).json({
    success: false,
    error: `Endpoint not found: ${req.method} ${req.originalUrl}`
  });
});

// Centralized error handler
app.use(errorHandler);

if (process.env.NODE_ENV !== 'test') {
  app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 CityPulse API running at http://localhost:${PORT}`);
  });
}

module.exports = app;

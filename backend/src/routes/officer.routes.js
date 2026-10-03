const express = require('express');
const router = express.Router();
const db = require('../config/db');
const { ROLES } = require('../config/constants');
const { authenticate } = require('../middleware/auth');
const { requireRole } = require('../middleware/role');
const { enrichComplaint } = require('../services/priority.service');

// Helper to get photos for a complaint
function getComplaintPhotos(complaintId) {
  return db.prepare('SELECT id, url, type FROM complaint_photos WHERE complaint_id = ?').all(complaintId);
}

// GET /officer/complaints - View complaints for officer's department, sorted by priority
router.get('/complaints', authenticate, requireRole(ROLES.OFFICER, ROLES.ADMIN), (req, res, next) => {
  try {
    const { status, onlyMine } = req.query;
    const department = req.user.department;

    let query = `
      SELECT c.*, u.name as citizen_name, u.email as citizen_email,
        (SELECT name FROM users WHERE id = c.officer_id) as officer_name
      FROM complaints c
      JOIN users u ON c.citizen_id = u.id
      WHERE 1=1
    `;
    const params = [];

    // If officer, scope to their department unless admin
    if (req.user.role === ROLES.OFFICER) {
      query += ` AND c.department = ?`;
      params.push(department);

      if (onlyMine === 'true') {
        query += ` AND c.officer_id = ?`;
        params.push(req.user.id);
      }
    }

    if (status) {
      query += ` AND c.status = ?`;
      params.push(status);
    }

    const rows = db.prepare(query).all(...params);

    // Recompute priority on read and sort descending by priority score
    const enriched = rows.map(r => ({
      ...enrichComplaint(r),
      photos: getComplaintPhotos(r.id)
    }));

    // Sort by priority_score descending, then created_at ascending
    enriched.sort((a, b) => {
      if (b.priority_score !== a.priority_score) {
        return b.priority_score - a.priority_score;
      }
      return new Date(a.created_at) - new Date(b.created_at);
    });

    res.json({
      success: true,
      department: req.user.role === ROLES.OFFICER ? department : 'All',
      count: enriched.length,
      complaints: enriched
    });
  } catch (err) {
    next(err);
  }
});

module.exports = router;

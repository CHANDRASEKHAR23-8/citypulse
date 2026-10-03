const express = require('express');
const router = express.Router();
const db = require('../config/db');
const { CATEGORY_MAP, STATUSES, ROLES } = require('../config/constants');
const { authenticate } = require('../middleware/auth');
const upload = require('../middleware/upload');
const { findDuplicate } = require('../services/duplicate.service');
const { calculatePriority, enrichComplaint } = require('../services/priority.service');
const { haversineDistance } = require('../services/geo.service');

// Helper to get photos for a complaint
function getComplaintPhotos(complaintId) {
  return db.prepare('SELECT id, url, type FROM complaint_photos WHERE complaint_id = ?').all(complaintId);
}

// POST /complaints - Report problem (multipart with photo)
router.post('/', authenticate, upload.single('photo'), async (req, res, next) => {
  try {
    const { category, description, force } = req.body;
    const lat = parseFloat(req.body.lat);
    const lng = parseFloat(req.body.lng);

    if (!category || !CATEGORY_MAP[category]) {
      return res.status(400).json({
        success: false,
        error: `Invalid or missing category. Allowed: ${Object.keys(CATEGORY_MAP).join(', ')}`
      });
    }

    if (!description || description.trim().length === 0) {
      return res.status(400).json({
        success: false,
        error: 'Description is required.'
      });
    }

    if (isNaN(lat) || isNaN(lng) || lat < -90 || lat > 90 || lng < -180 || lng > 180) {
      return res.status(400).json({
        success: false,
        error: 'Valid latitude (-90 to 90) and longitude (-180 to 180) are required.'
      });
    }

    // Duplicate detection (50m radius, same category, open status)
    const isForced = force === true || force === 'true' || force === '1';
    if (!isForced) {
      const duplicate = findDuplicate(category, lat, lng);
      if (duplicate) {
        return res.status(409).json({
          success: false,
          duplicateFound: true,
          error: `A similar open ${category} issue was reported nearby (${duplicate.distanceMeters}m away). Would you like to support it instead?`,
          duplicate
        });
      }
    }

    // Department & initial priority
    const department = CATEGORY_MAP[category].department;
    const { score, priority } = calculatePriority(category, 0, new Date());

    const insertStmt = db.prepare(`
      INSERT INTO complaints (citizen_id, category, description, lat, lng, status, priority, department, support_count)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, 0)
    `);

    const result = insertStmt.run(
      req.user.id,
      category,
      description.trim(),
      lat,
      lng,
      STATUSES.ASSIGNED,
      priority,
      department
    );

    const complaintId = result.lastInsertRowid;

    // Handle photo if uploaded
    let photoUrl = null;
    if (req.file) {
      photoUrl = `/uploads/${req.file.filename}`;
      db.prepare(`
        INSERT INTO complaint_photos (complaint_id, url, type)
        VALUES (?, ?, 'report')
      `).run(complaintId, photoUrl);
    }

    // Log initial status history
    db.prepare(`
      INSERT INTO status_history (complaint_id, status, note, changed_by)
      VALUES (?, ?, ?, ?)
    `).run(
      complaintId,
      STATUSES.ASSIGNED,
      `Report submitted by citizen and auto-assigned to ${department} Department.`,
      req.user.id
    );

    // Create notification for citizen
    db.prepare(`
      INSERT INTO notifications (user_id, complaint_id, message)
      VALUES (?, ?, ?)
    `).run(
      req.user.id,
      complaintId,
      `Your complaint #${complaintId} (${category}) has been submitted and assigned to the ${department} Department.`
    );

    const createdComplaint = db.prepare(`
      SELECT c.*, u.name as citizen_name
      FROM complaints c
      JOIN users u ON c.citizen_id = u.id
      WHERE c.id = ?
    `).get(complaintId);

    return res.status(201).json({
      success: true,
      message: 'Complaint submitted successfully',
      complaint: {
        ...enrichComplaint(createdComplaint),
        photos: getComplaintPhotos(complaintId)
      }
    });
  } catch (err) {
    next(err);
  }
});

// GET /complaints/mine - Citizen's own complaints
router.get('/mine', authenticate, (req, res, next) => {
  try {
    const rows = db.prepare(`
      SELECT c.*, u.name as citizen_name,
        (SELECT name FROM users WHERE id = c.officer_id) as officer_name,
        (SELECT COUNT(*) FROM supports WHERE complaint_id = c.id AND user_id = ?) as has_supported
      FROM complaints c
      JOIN users u ON c.citizen_id = u.id
      WHERE c.citizen_id = ?
      ORDER BY c.created_at DESC
    `).all(req.user.id, req.user.id);

    const enriched = rows.map(r => ({
      ...enrichComplaint(r),
      has_supported: Boolean(r.has_supported),
      photos: getComplaintPhotos(r.id)
    }));

    res.json({
      success: true,
      count: enriched.length,
      complaints: enriched
    });
  } catch (err) {
    next(err);
  }
});

// GET /complaints - Public/citizen list with optional geo/category/status filters
router.get('/', (req, res, next) => {
  try {
    const { lat, lng, radius, category, status, department } = req.query;

    let query = `
      SELECT c.*, u.name as citizen_name,
        (SELECT name FROM users WHERE id = c.officer_id) as officer_name
      FROM complaints c
      JOIN users u ON c.citizen_id = u.id
      WHERE 1=1
    `;
    const params = [];

    if (category) {
      query += ` AND c.category = ?`;
      params.push(category);
    }
    if (status) {
      query += ` AND c.status = ?`;
      params.push(status);
    }
    if (department) {
      query += ` AND c.department = ?`;
      params.push(department);
    }

    query += ` ORDER BY c.created_at DESC`;

    let rows = db.prepare(query).all(...params);

    // Filter by radius if lat, lng, radius (in km) are given
    if (lat && lng && radius) {
      const centerLat = parseFloat(lat);
      const centerLng = parseFloat(lng);
      const radiusMeters = parseFloat(radius) * 1000;

      rows = rows.filter(r => {
        const d = haversineDistance(centerLat, centerLng, r.lat, r.lng);
        r.distance_meters = Math.round(d);
        return d <= radiusMeters;
      });
    }

    // Recompute priority on read
    const enriched = rows.map(r => ({
      ...enrichComplaint(r),
      photos: getComplaintPhotos(r.id)
    }));

    res.json({
      success: true,
      count: enriched.length,
      complaints: enriched
    });
  } catch (err) {
    next(err);
  }
});

// GET /complaints/:id - Single complaint with details, photos, and history
router.get('/:id', (req, res, next) => {
  try {
    const id = parseInt(req.params.id);
    const complaint = db.prepare(`
      SELECT c.*, u.name as citizen_name, u.email as citizen_email,
        (SELECT name FROM users WHERE id = c.officer_id) as officer_name,
        (SELECT email FROM users WHERE id = c.officer_id) as officer_email
      FROM complaints c
      JOIN users u ON c.citizen_id = u.id
      WHERE c.id = ?
    `).get(id);

    if (!complaint) {
      return res.status(404).json({
        success: false,
        error: 'Complaint not found.'
      });
    }

    const photos = getComplaintPhotos(id);
    const history = db.prepare(`
      SELECT sh.*, u.name as changed_by_name, u.role as changed_by_role
      FROM status_history sh
      JOIN users u ON sh.changed_by = u.id
      WHERE sh.complaint_id = ?
      ORDER BY sh.changed_at ASC
    `).all(id);

    res.json({
      success: true,
      complaint: {
        ...enrichComplaint(complaint),
        photos,
        history
      }
    });
  } catch (err) {
    next(err);
  }
});

// POST /complaints/:id/support - Citizen supports an existing complaint
router.post('/:id/support', authenticate, (req, res, next) => {
  try {
    const id = parseInt(req.params.id);
    const userId = req.user.id;

    const complaint = db.prepare('SELECT * FROM complaints WHERE id = ?').get(id);
    if (!complaint) {
      return res.status(404).json({
        success: false,
        error: 'Complaint not found.'
      });
    }

    const existingSupport = db.prepare('SELECT 1 FROM supports WHERE complaint_id = ? AND user_id = ?').get(id, userId);
    if (existingSupport) {
      return res.status(400).json({
        success: false,
        error: 'You have already supported this complaint.'
      });
    }

    db.transaction(() => {
      db.prepare('INSERT INTO supports (complaint_id, user_id) VALUES (?, ?)').run(id, userId);
      db.prepare('UPDATE complaints SET support_count = support_count + 1 WHERE id = ?').run(id);

      const updated = db.prepare('SELECT * FROM complaints WHERE id = ?').get(id);
      const { score, priority } = calculatePriority(updated.category, updated.support_count, updated.created_at);
      db.prepare('UPDATE complaints SET priority = ? WHERE id = ?').run(priority, id);
    })();

    const updatedComplaint = db.prepare('SELECT * FROM complaints WHERE id = ?').get(id);

    res.json({
      success: true,
      message: 'Support recorded successfully! This issue has been boosted in priority.',
      complaint: enrichComplaint(updatedComplaint)
    });
  } catch (err) {
    next(err);
  }
});

// PATCH /complaints/:id/status - Update status with optional resolution photo
router.patch('/:id/status', authenticate, upload.single('photo'), async (req, res, next) => {
  try {
    const id = parseInt(req.params.id);
    const { status, note } = req.body;

    if (!status || !Object.values(STATUSES).includes(status)) {
      return res.status(400).json({
        success: false,
        error: `Invalid status. Allowed values: ${Object.values(STATUSES).join(', ')}`
      });
    }

    const complaint = db.prepare('SELECT * FROM complaints WHERE id = ?').get(id);
    if (!complaint) {
      return res.status(404).json({
        success: false,
        error: 'Complaint not found.'
      });
    }

    // Role check: Officer (must belong to department) or Admin
    if (req.user.role === ROLES.CITIZEN) {
      return res.status(403).json({
        success: false,
        error: 'Citizens are not permitted to change complaint status.'
      });
    }

    if (req.user.role === ROLES.OFFICER && req.user.department !== complaint.department) {
      return res.status(403).json({
        success: false,
        error: `Forbidden: You belong to ${req.user.department} but this complaint is under ${complaint.department}.`
      });
    }

    let resolutionPhotoUrl = null;
    if (req.file) {
      resolutionPhotoUrl = `/uploads/${req.file.filename}`;
    }

    db.transaction(() => {
      // Update complaint status
      db.prepare('UPDATE complaints SET status = ? WHERE id = ?').run(status, id);

      // If resolution photo provided, insert into complaint_photos
      if (resolutionPhotoUrl) {
        db.prepare(`
          INSERT INTO complaint_photos (complaint_id, url, type)
          VALUES (?, ?, 'resolution')
        `).run(id, resolutionPhotoUrl);
      }

      // Add to status_history
      const historyNote = note || `Status updated to ${status} by ${req.user.name} (${req.user.role})`;
      db.prepare(`
        INSERT INTO status_history (complaint_id, status, note, changed_by)
        VALUES (?, ?, ?, ?)
      `).run(id, status, historyNote, req.user.id);

      // Notify citizen
      const notifMessage = `Update on Complaint #${id} (${complaint.category}): Status is now "${status}". ${note ? `Note: ${note}` : ''}`;
      db.prepare(`
        INSERT INTO notifications (user_id, complaint_id, message)
        VALUES (?, ?, ?)
      `).run(complaint.citizen_id, id, notifMessage.trim());
    })();

    const updated = db.prepare(`
      SELECT c.*, u.name as citizen_name,
        (SELECT name FROM users WHERE id = c.officer_id) as officer_name
      FROM complaints c
      JOIN users u ON c.citizen_id = u.id
      WHERE c.id = ?
    `).get(id);

    res.json({
      success: true,
      message: `Status updated to ${status}`,
      complaint: {
        ...enrichComplaint(updated),
        photos: getComplaintPhotos(id)
      }
    });
  } catch (err) {
    next(err);
  }
});

module.exports = router;

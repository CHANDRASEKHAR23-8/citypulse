const express = require('express');
const router = express.Router();
const db = require('../config/db');
const { ROLES, DEPARTMENTS } = require('../config/constants');
const { authenticate } = require('../middleware/auth');
const { requireRole } = require('../middleware/role');
const { enrichComplaint } = require('../services/priority.service');

// All admin routes require ADMIN role
router.use(authenticate, requireRole(ROLES.ADMIN));

function getComplaintPhotos(complaintId) {
  return db.prepare('SELECT id, url, type FROM complaint_photos WHERE complaint_id = ?').all(complaintId);
}

// GET /admin/complaints - View all complaints across all departments
router.get('/complaints', (req, res, next) => {
  try {
    const { department, category, status } = req.query;

    let query = `
      SELECT c.*, u.name as citizen_name, u.email as citizen_email,
        (SELECT name FROM users WHERE id = c.officer_id) as officer_name,
        (SELECT department FROM users WHERE id = c.officer_id) as officer_department
      FROM complaints c
      JOIN users u ON c.citizen_id = u.id
      WHERE 1=1
    `;
    const params = [];

    if (department) {
      query += ` AND c.department = ?`;
      params.push(department);
    }
    if (category) {
      query += ` AND c.category = ?`;
      params.push(category);
    }
    if (status) {
      query += ` AND c.status = ?`;
      params.push(status);
    }

    query += ` ORDER BY c.created_at DESC`;

    const rows = db.prepare(query).all(...params);
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

// PATCH /admin/complaints/:id/assign - Assign or reassign department and officer
router.patch('/complaints/:id/assign', (req, res, next) => {
  try {
    const id = parseInt(req.params.id);
    const { department, officer_id } = req.body;

    const complaint = db.prepare('SELECT * FROM complaints WHERE id = ?').get(id);
    if (!complaint) {
      return res.status(404).json({
        success: false,
        error: 'Complaint not found.'
      });
    }

    let targetDept = complaint.department;
    if (department) {
      if (!DEPARTMENTS.includes(department)) {
        return res.status(400).json({
          success: false,
          error: `Invalid department. Allowed: ${DEPARTMENTS.join(', ')}`
        });
      }
      targetDept = department;
    }

    let targetOfficerId = complaint.officer_id;
    let officerName = null;
    if (officer_id !== undefined) {
      if (officer_id === null || officer_id === '') {
        targetOfficerId = null;
      } else {
        const officer = db.prepare('SELECT id, name, role, department FROM users WHERE id = ?').get(officer_id);
        if (!officer) {
          return res.status(400).json({
            success: false,
            error: 'Specified officer does not exist.'
          });
        }
        if (officer.role !== ROLES.OFFICER && officer.role !== ROLES.ADMIN) {
          return res.status(400).json({
            success: false,
            error: 'Assigned user must have officer or admin role.'
          });
        }
        targetOfficerId = officer.id;
        officerName = officer.name;
      }
    }

    db.transaction(() => {
      db.prepare(`
        UPDATE complaints
        SET department = ?, officer_id = ?
        WHERE id = ?
      `).run(targetDept, targetOfficerId, id);

      const note = `Reassigned by Administrator ${req.user.name}: Department -> ${targetDept}${targetOfficerId ? `, Officer -> ${officerName || targetOfficerId}` : ''}`;
      
      db.prepare(`
        INSERT INTO status_history (complaint_id, status, note, changed_by)
        VALUES (?, ?, ?, ?)
      `).run(id, complaint.status, note, req.user.id);

      db.prepare(`
        INSERT INTO notifications (user_id, complaint_id, message)
        VALUES (?, ?, ?)
      `).run(
        complaint.citizen_id,
        id,
        `Your complaint #${id} department was updated to ${targetDept}${officerName ? ` and assigned to Officer ${officerName}` : ''}.`
      );
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
      message: 'Complaint reassigned successfully',
      complaint: {
        ...enrichComplaint(updated),
        photos: getComplaintPhotos(id)
      }
    });
  } catch (err) {
    next(err);
  }
});

// GET /admin/users - Manage users list
router.get('/users', (req, res, next) => {
  try {
    const users = db.prepare(`
      SELECT u.id, u.name, u.email, u.role, u.department, u.created_at,
        (SELECT COUNT(*) FROM complaints WHERE citizen_id = u.id) as complaints_reported,
        (SELECT COUNT(*) FROM complaints WHERE officer_id = u.id) as complaints_assigned
      FROM users u
      ORDER BY u.id ASC
    `).all();

    res.json({
      success: true,
      count: users.length,
      users
    });
  } catch (err) {
    next(err);
  }
});

// PATCH /admin/users/:id - Update user role / department
router.patch('/users/:id', (req, res, next) => {
  try {
    const id = parseInt(req.params.id);
    const { role, department } = req.body;

    const user = db.prepare('SELECT * FROM users WHERE id = ?').get(id);
    if (!user) {
      return res.status(404).json({
        success: false,
        error: 'User not found.'
      });
    }

    let newRole = user.role;
    if (role) {
      if (![ROLES.CITIZEN, ROLES.OFFICER, ROLES.ADMIN].includes(role)) {
        return res.status(400).json({
          success: false,
          error: `Invalid role. Allowed: ${Object.values(ROLES).join(', ')}`
        });
      }
      newRole = role;
    }

    let newDept = user.department;
    if (department !== undefined) {
      if (department && !DEPARTMENTS.includes(department)) {
        return res.status(400).json({
          success: false,
          error: `Invalid department. Allowed: ${DEPARTMENTS.join(', ')}`
        });
      }
      newDept = department || null;
    }

    db.prepare(`
      UPDATE users
      SET role = ?, department = ?
      WHERE id = ?
    `).run(newRole, newDept, id);

    const updatedUser = db.prepare('SELECT id, name, email, role, department, created_at FROM users WHERE id = ?').get(id);

    res.json({
      success: true,
      message: 'User updated successfully',
      user: updatedUser
    });
  } catch (err) {
    next(err);
  }
});

// GET /admin/stats - Aggregated counts & metrics
router.get('/stats', (req, res, next) => {
  try {
    // Total complaints
    const totalComplaints = db.prepare('SELECT COUNT(*) as count FROM complaints').get().count;

    // Counts by status
    const statusCountsRaw = db.prepare(`
      SELECT status, COUNT(*) as count
      FROM complaints
      GROUP BY status
    `).all();
    const byStatus = {
      SUBMITTED: 0,
      ASSIGNED: 0,
      IN_PROGRESS: 0,
      RESOLVED: 0
    };
    statusCountsRaw.forEach(r => { byStatus[r.status] = r.count; });

    // Counts by category
    const byCategory = db.prepare(`
      SELECT category, COUNT(*) as count
      FROM complaints
      GROUP BY category
    `).all();

    // Counts by department
    const byDepartment = db.prepare(`
      SELECT department, COUNT(*) as count
      FROM complaints
      GROUP BY department
    `).all();

    // Priority breakdown
    const priorityCountsRaw = db.prepare(`
      SELECT priority, COUNT(*) as count
      FROM complaints
      GROUP BY priority
    `).all();
    const byPriority = { LOW: 0, MEDIUM: 0, HIGH: 0 };
    priorityCountsRaw.forEach(r => { byPriority[r.priority] = r.count; });

    // Average resolution time (hours)
    // Compare complaint creation time with the earliest 'RESOLVED' status_history entry for that complaint
    const resolutionTimes = db.prepare(`
      SELECT c.id, c.created_at as created_at,
        MIN(sh.changed_at) as resolved_at
      FROM complaints c
      JOIN status_history sh ON c.id = sh.complaint_id
      WHERE sh.status = 'RESOLVED'
      GROUP BY c.id
    `).all();

    let avgResolutionHours = 0;
    if (resolutionTimes.length > 0) {
      const totalHours = resolutionTimes.reduce((acc, curr) => {
        const start = new Date(curr.created_at).getTime();
        const end = new Date(curr.resolved_at).getTime();
        const hours = Math.max(0, (end - start) / (1000 * 60 * 60));
        return acc + hours;
      }, 0);
      avgResolutionHours = parseFloat((totalHours / resolutionTimes.length).toFixed(1));
    }

    const totalUsers = db.prepare('SELECT COUNT(*) as count FROM users').get().count;

    res.json({
      success: true,
      stats: {
        totalComplaints,
        totalUsers,
        resolvedCount: byStatus.RESOLVED,
        avgResolutionHours,
        byStatus,
        byCategory,
        byDepartment,
        byPriority
      }
    });
  } catch (err) {
    next(err);
  }
});

module.exports = router;

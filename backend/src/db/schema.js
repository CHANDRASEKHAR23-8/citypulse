const db = require('../config/db');

function initSchema() {
  db.exec(`
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      email TEXT UNIQUE NOT NULL,
      password_hash TEXT NOT NULL,
      role TEXT NOT NULL CHECK(role IN ('citizen', 'officer', 'admin')),
      department TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS complaints (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      citizen_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      category TEXT NOT NULL,
      description TEXT NOT NULL,
      lat REAL NOT NULL,
      lng REAL NOT NULL,
      status TEXT NOT NULL DEFAULT 'ASSIGNED' CHECK(status IN ('SUBMITTED', 'ASSIGNED', 'IN_PROGRESS', 'RESOLVED')),
      priority TEXT NOT NULL DEFAULT 'LOW' CHECK(priority IN ('LOW', 'MEDIUM', 'HIGH')),
      department TEXT NOT NULL,
      officer_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
      support_count INTEGER NOT NULL DEFAULT 0,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS complaint_photos (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      complaint_id INTEGER NOT NULL REFERENCES complaints(id) ON DELETE CASCADE,
      url TEXT NOT NULL,
      type TEXT NOT NULL CHECK(type IN ('report', 'resolution'))
    );

    CREATE TABLE IF NOT EXISTS supports (
      complaint_id INTEGER NOT NULL REFERENCES complaints(id) ON DELETE CASCADE,
      user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      PRIMARY KEY (complaint_id, user_id)
    );

    CREATE TABLE IF NOT EXISTS status_history (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      complaint_id INTEGER NOT NULL REFERENCES complaints(id) ON DELETE CASCADE,
      status TEXT NOT NULL,
      note TEXT,
      changed_by INTEGER NOT NULL REFERENCES users(id),
      changed_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS notifications (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      complaint_id INTEGER REFERENCES complaints(id) ON DELETE CASCADE,
      message TEXT NOT NULL,
      is_read INTEGER NOT NULL DEFAULT 0,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );

    CREATE INDEX IF NOT EXISTS idx_complaints_category ON complaints(category);
    CREATE INDEX IF NOT EXISTS idx_complaints_status ON complaints(status);
    CREATE INDEX IF NOT EXISTS idx_complaints_department ON complaints(department);
    CREATE INDEX IF NOT EXISTS idx_complaints_officer ON complaints(officer_id);
    CREATE INDEX IF NOT EXISTS idx_complaints_citizen ON complaints(citizen_id);
    CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id);
  `);
}

module.exports = { initSchema };

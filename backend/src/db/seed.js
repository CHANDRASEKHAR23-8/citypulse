const bcrypt = require('bcryptjs');
const db = require('../config/db');
const { initSchema } = require('./schema');
const { ROLES, STATUSES } = require('../config/constants');
const { calculatePriority } = require('../services/priority.service');

async function seed() {
  console.log('--- Initializing CityPulse Database Schema ---');
  initSchema();

  console.log('--- Seeding Database ---');

  // Check if admin already exists
  const existingAdmin = db.prepare('SELECT id FROM users WHERE email = ?').get('admin@citypulse.gov');
  if (existingAdmin) {
    console.log('Database already seeded. Skipping initial seeding.');
    return;
  }

  const salt = await bcrypt.genSalt(10);
  const adminHash = await bcrypt.hash('AdminPassword123!', salt);
  const officerHash = await bcrypt.hash('OfficerPassword123!', salt);
  const citizenHash = await bcrypt.hash('CitizenPassword123!', salt);

  // 1. Seed Admin
  const adminRes = db.prepare(`
    INSERT INTO users (name, email, password_hash, role, department)
    VALUES (?, ?, ?, ?, ?)
  `).run('City Administrator', 'admin@citypulse.gov', adminHash, ROLES.ADMIN, null);
  const adminId = adminRes.lastInsertRowid;

  // 2. Seed Officers for each Department
  const officerRoads = db.prepare(`
    INSERT INTO users (name, email, password_hash, role, department)
    VALUES (?, ?, ?, ?, ?)
  `).run('Officer John Roads', 'officer.roads@citypulse.gov', officerHash, ROLES.OFFICER, 'Roads');

  const officerElec = db.prepare(`
    INSERT INTO users (name, email, password_hash, role, department)
    VALUES (?, ?, ?, ?, ?)
  `).run('Officer Sarah Sparks', 'officer.electricity@citypulse.gov', officerHash, ROLES.OFFICER, 'Electricity');

  const officerSan = db.prepare(`
    INSERT INTO users (name, email, password_hash, role, department)
    VALUES (?, ?, ?, ?, ?)
  `).run('Officer Mark Clean', 'officer.sanitation@citypulse.gov', officerHash, ROLES.OFFICER, 'Sanitation');

  const officerWater = db.prepare(`
    INSERT INTO users (name, email, password_hash, role, department)
    VALUES (?, ?, ?, ?, ?)
  `).run('Officer David Aqua', 'officer.water@citypulse.gov', officerHash, ROLES.OFFICER, 'Water');

  const officerTraffic = db.prepare(`
    INSERT INTO users (name, email, password_hash, role, department)
    VALUES (?, ?, ?, ?, ?)
  `).run('Officer Lisa Transit', 'officer.traffic@citypulse.gov', officerHash, ROLES.OFFICER, 'Traffic');

  // 3. Seed Citizens
  const citizenAlice = db.prepare(`
    INSERT INTO users (name, email, password_hash, role, department)
    VALUES (?, ?, ?, ?, ?)
  `).run('Alice Johnson', 'citizen.alice@example.com', citizenHash, ROLES.CITIZEN, null);

  const citizenBob = db.prepare(`
    INSERT INTO users (name, email, password_hash, role, department)
    VALUES (?, ?, ?, ?, ?)
  `).run('Bob Smith', 'citizen.bob@example.com', citizenHash, ROLES.CITIZEN, null);

  // 4. Seed Initial Realistic Complaints
  const sampleComplaints = [
    {
      citizenId: citizenAlice.lastInsertRowid,
      category: 'Water Leakage',
      department: 'Water',
      description: 'Major underground pipeline burst on 5th Avenue causing street flooding.',
      lat: 12.9716,
      lng: 77.5946,
      status: STATUSES.IN_PROGRESS,
      officerId: officerWater.lastInsertRowid,
      supports: 8,
      daysAgo: 2
    },
    {
      citizenId: citizenBob.lastInsertRowid,
      category: 'Pothole',
      department: 'Roads',
      description: 'Deep hazardous pothole near metro junction causing severe motorcycle skid risks.',
      lat: 12.9750,
      lng: 77.5990,
      status: STATUSES.ASSIGNED,
      officerId: officerRoads.lastInsertRowid,
      supports: 12,
      daysAgo: 4
    },
    {
      citizenId: citizenAlice.lastInsertRowid,
      category: 'Streetlight',
      department: 'Electricity',
      description: 'Dark alleyway due to 3 dead sodium streetlights for the past week.',
      lat: 12.9680,
      lng: 77.5890,
      status: STATUSES.RESOLVED,
      officerId: officerElec.lastInsertRowid,
      supports: 3,
      daysAgo: 5
    },
    {
      citizenId: citizenBob.lastInsertRowid,
      category: 'Garbage',
      department: 'Sanitation',
      description: 'Commercial waste overflowing near community park entrance.',
      lat: 12.9805,
      lng: 77.6050,
      status: STATUSES.ASSIGNED,
      officerId: officerSan.lastInsertRowid,
      supports: 1,
      daysAgo: 1
    },
    {
      citizenId: citizenAlice.lastInsertRowid,
      category: 'Traffic',
      department: 'Traffic',
      description: 'Traffic signal timer stuck on red at primary high-street roundabout.',
      lat: 12.9640,
      lng: 77.6010,
      status: STATUSES.IN_PROGRESS,
      officerId: officerTraffic.lastInsertRowid,
      supports: 6,
      daysAgo: 1
    }
  ];

  for (const c of sampleComplaints) {
    const createdDate = new Date(Date.now() - (c.daysAgo * 24 * 60 * 60 * 1000)).toISOString();
    const { priority } = calculatePriority(c.category, c.supports, createdDate);

    const compRes = db.prepare(`
      INSERT INTO complaints (citizen_id, category, description, lat, lng, status, priority, department, officer_id, support_count, created_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).run(
      c.citizenId,
      c.category,
      c.description,
      c.lat,
      c.lng,
      c.status,
      priority,
      c.department,
      c.officerId,
      c.supports,
      createdDate
    );

    const complaintId = compRes.lastInsertRowid;

    // Status history
    db.prepare(`
      INSERT INTO status_history (complaint_id, status, note, changed_by, changed_at)
      VALUES (?, ?, ?, ?, ?)
    `).run(
      complaintId,
      c.status,
      `Initial record created and assigned to ${c.department}`,
      adminId,
      createdDate
    );

    if (c.status === STATUSES.RESOLVED) {
      const resolvedDate = new Date(Date.now() - (1 * 24 * 60 * 60 * 1000)).toISOString();
      db.prepare(`
        INSERT INTO status_history (complaint_id, status, note, changed_by, changed_at)
        VALUES (?, ?, ?, ?, ?)
      `).run(
        complaintId,
        STATUSES.RESOLVED,
        'Issue resolved and verified on-site by field officer.',
        c.officerId,
        resolvedDate
      );
    }

    // Citizen notification
    db.prepare(`
      INSERT INTO notifications (user_id, complaint_id, message, created_at)
      VALUES (?, ?, ?, ?)
    `).run(
      c.citizenId,
      complaintId,
      `Complaint #${complaintId} (${c.category}) is currently ${c.status}.`,
      createdDate
    );
  }

  console.log('✅ Seed completed successfully:');
  console.log('   Admin: admin@citypulse.gov / AdminPassword123!');
  console.log('   Officers: officer.<dept>@citypulse.gov / OfficerPassword123!');
  console.log('   Citizens: citizen.alice@example.com / CitizenPassword123!');
}

if (require.main === module) {
  seed()
    .then(() => process.exit(0))
    .catch(err => {
      console.error('Seed error:', err);
      process.exit(1);
    });
}

module.exports = { seed };

require('dotenv').config();
const bcrypt = require('bcryptjs');
const db = require('../config/db');
const { initSchema } = require('./schema');
const { ROLES } = require('../config/constants');

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

  const adminPassword = process.env.SEED_ADMIN_PASSWORD || 'AdminPassword123!';
  const officerPassword = process.env.SEED_OFFICER_PASSWORD || 'OfficerPassword123!';

  const salt = await bcrypt.genSalt(10);
  const adminHash = await bcrypt.hash(adminPassword, salt);
  const officerHash = await bcrypt.hash(officerPassword, salt);

  // 1. Seed Admin
  db.prepare(`
    INSERT INTO users (name, email, password_hash, role, department)
    VALUES (?, ?, ?, ?, ?)
  `).run('City Administrator', 'admin@citypulse.gov', adminHash, ROLES.ADMIN, null);

  // 2. Seed Officers for each Department
  const officerAccounts = [
    { name: 'Roads Officer', email: 'officer.roads@citypulse.gov', dept: 'Roads' },
    { name: 'Electricity Officer', email: 'officer.electricity@citypulse.gov', dept: 'Electricity' },
    { name: 'Sanitation Officer', email: 'officer.sanitation@citypulse.gov', dept: 'Sanitation' },
    { name: 'Water Officer', email: 'officer.water@citypulse.gov', dept: 'Water' },
    { name: 'Traffic Officer', email: 'officer.traffic@citypulse.gov', dept: 'Traffic' },
  ];

  const insertUser = db.prepare(`
    INSERT INTO users (name, email, password_hash, role, department)
    VALUES (?, ?, ?, ?, ?)
  `);

  for (const officer of officerAccounts) {
    insertUser.run(officer.name, officer.email, officerHash, ROLES.OFFICER, officer.dept);
  }

  console.log('✅ Seed completed successfully! Created essential accounts:');
  console.log('   Admin: admin@citypulse.gov');
  console.log('   Officers:');
  for (const officer of officerAccounts) {
    console.log(`    - ${officer.email} (${officer.dept})`);
  }
  console.log('   (Citizens register through the app registration screen)');
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

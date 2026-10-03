require('dotenv').config();

const CATEGORY_MAP = {
  'Pothole': { department: 'Roads', basePriority: 2 },
  'Streetlight': { department: 'Electricity', basePriority: 2 },
  'Garbage': { department: 'Sanitation', basePriority: 1 },
  'Water Leakage': { department: 'Water', basePriority: 3 },
  'Traffic': { department: 'Traffic', basePriority: 2 }
};

const STATUSES = {
  SUBMITTED: 'SUBMITTED',
  ASSIGNED: 'ASSIGNED',
  IN_PROGRESS: 'IN_PROGRESS',
  RESOLVED: 'RESOLVED'
};

const ROLES = {
  CITIZEN: 'citizen',
  OFFICER: 'officer',
  ADMIN: 'admin'
};

const DEPARTMENTS = ['Roads', 'Electricity', 'Sanitation', 'Water', 'Traffic'];

const DUPLICATE_THRESHOLD_METERS = 50;

module.exports = {
  CATEGORY_MAP,
  STATUSES,
  ROLES,
  DEPARTMENTS,
  DUPLICATE_THRESHOLD_METERS,
  JWT_SECRET: process.env.JWT_SECRET || 'citypulse-super-secret-jwt-key-2026',
  JWT_EXPIRES_IN: '7d'
};

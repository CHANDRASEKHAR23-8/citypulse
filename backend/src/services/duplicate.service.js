const db = require('../config/db');
const { haversineDistance } = require('./geo.service');
const { DUPLICATE_THRESHOLD_METERS } = require('../config/constants');
const { enrichComplaint } = require('./priority.service');

/**
 * Searches for any open complaint in the same category within the threshold distance.
 * @param {string} category 
 * @param {number} lat 
 * @param {number} lng 
 * @returns {object|null} The nearest matching duplicate complaint or null
 */
function findDuplicate(category, lat, lng) {
  const openComplaints = db.prepare(`
    SELECT c.*, u.name as citizen_name,
      (SELECT url FROM complaint_photos WHERE complaint_id = c.id AND type = 'report' LIMIT 1) as photo_url
    FROM complaints c
    JOIN users u ON c.citizen_id = u.id
    WHERE c.category = ? AND c.status != 'RESOLVED'
  `).all(category);

  let nearestMatch = null;
  let minDistance = Infinity;

  for (const item of openComplaints) {
    const distanceMeters = haversineDistance(lat, lng, item.lat, item.lng);
    if (distanceMeters <= DUPLICATE_THRESHOLD_METERS) {
      if (distanceMeters < minDistance) {
        minDistance = distanceMeters;
        nearestMatch = {
          ...enrichComplaint(item),
          distanceMeters: Math.round(distanceMeters)
        };
      }
    }
  }

  return nearestMatch;
}

module.exports = { findDuplicate };

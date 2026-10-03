const { CATEGORY_MAP } = require('../config/constants');

/**
 * Calculates priority score and level for a complaint.
 * Formula: score = base_priority + min(support_count, 10) + 0.5 * days_open
 * Level: HIGH if score >= 10, MEDIUM if score >= 5, else LOW.
 */
function calculatePriority(category, supportCount = 0, createdAt = new Date()) {
  const catConfig = CATEGORY_MAP[category] || { basePriority: 1, department: 'General' };
  const basePriority = catConfig.basePriority;

  const createdTime = new Date(createdAt).getTime();
  const now = Date.now();
  const diffMs = Math.max(0, now - createdTime);
  const daysOpen = diffMs / (1000 * 60 * 60 * 24);

  const effectiveSupport = Math.min(Math.max(0, supportCount), 10);
  const score = basePriority + effectiveSupport + (0.5 * daysOpen);

  let priority = 'LOW';
  if (score >= 10) {
    priority = 'HIGH';
  } else if (score >= 5) {
    priority = 'MEDIUM';
  }

  return {
    score: parseFloat(score.toFixed(2)),
    priority,
    basePriority,
    daysOpen: parseFloat(daysOpen.toFixed(2))
  };
}

/**
 * Enriches a complaint record by recomputing its priority and score.
 */
function enrichComplaint(complaint) {
  if (!complaint) return null;
  const { score, priority } = calculatePriority(
    complaint.category,
    complaint.support_count,
    complaint.created_at
  );
  return {
    ...complaint,
    priority_score: score,
    priority
  };
}

module.exports = {
  calculatePriority,
  enrichComplaint
};

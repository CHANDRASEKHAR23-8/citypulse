const http = require('http');
const app = require('../src/server');
const { seed } = require('../src/db/seed');

let server;
const PORT = 3099;
const BASE_URL = `http://localhost:${PORT}`;

async function request(path, options = {}) {
  const url = `${BASE_URL}${path}`;
  const response = await fetch(url, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...(options.headers || {})
    }
  });

  const text = await response.text();
  let json;
  try {
    json = JSON.parse(text);
  } catch (e) {
    json = { raw: text };
  }

  return {
    status: response.status,
    headers: response.headers,
    body: json
  };
}

let passed = 0;
let failed = 0;

function assert(condition, message) {
  if (condition) {
    console.log(`  ✅ PASS: ${message}`);
    passed++;
  } else {
    console.error(`  ❌ FAIL: ${message}`);
    failed++;
  }
}

async function runTests() {
  console.log('\n========================================');
  console.log('   RUNNING CITYPULSE BACKEND API TESTS   ');
  console.log('========================================\n');

  // 1. Seed the DB
  console.log('[Step 1] Seeding database...');
  await seed();
  console.log('Seed step completed.\n');

  // 2. Start Test Server
  server = app.listen(PORT);
  await new Promise(resolve => setTimeout(resolve, 500));

  try {
    // 3. Test Health & Root
    console.log('[Step 2] Testing API Root and Health...');
    const rootRes = await request('/');
    assert(rootRes.status === 200 && rootRes.body.status === 'online', 'GET / returns online status');

    // 4. Test Auth: Login as Admin
    console.log('\n[Step 3] Testing Authentication...');
    const adminLogin = await request('/auth/login', {
      method: 'POST',
      body: JSON.stringify({ email: 'admin@citypulse.gov', password: 'AdminPassword123!' })
    });
    assert(adminLogin.status === 200 && adminLogin.body.token, 'Admin login succeeds with JWT');
    const adminToken = adminLogin.body.token;

    // Login as Citizen
    const citizenLogin = await request('/auth/login', {
      method: 'POST',
      body: JSON.stringify({ email: 'citizen.alice@example.com', password: 'CitizenPassword123!' })
    });
    assert(citizenLogin.status === 200 && citizenLogin.body.token, 'Citizen login succeeds with JWT');
    const aliceToken = citizenLogin.body.token;

    // Register a new citizen
    const newCitizenEmail = `testcitizen_${Date.now()}@example.com`;
    const regRes = await request('/auth/register', {
      method: 'POST',
      body: JSON.stringify({
        name: 'Charlie Test',
        email: newCitizenEmail,
        password: 'Password123!'
      })
    });
    assert(regRes.status === 201 && regRes.body.user.role === 'citizen', 'New citizen registration returns 201');
    const charlieToken = regRes.body.token;

    // 5. Test Complaints Reporting & Auto-Assignment
    console.log('\n[Step 4] Testing Complaint Reporting & Auto-Assignment...');
    const reportLat = 13.0827;
    const reportLng = 80.2707;
    const newComplaint = await request('/complaints', {
      method: 'POST',
      headers: { Authorization: `Bearer ${charlieToken}` },
      body: JSON.stringify({
        category: 'Pothole',
        description: 'Dangerous pothole on arterial road',
        lat: reportLat,
        lng: reportLng
      })
    });
    assert(newComplaint.status === 201, 'Complaint reporting returns 201');
    assert(newComplaint.body.complaint.department === 'Roads', 'Auto-assigned to Roads department');
    assert(newComplaint.body.complaint.status === 'ASSIGNED', 'Initial status is ASSIGNED');
    assert(newComplaint.body.complaint.priority_score !== undefined, 'Priority score calculated on read');
    const testComplaintId = newComplaint.body.complaint.id;

    // 6. Test Duplicate Detection (within 50 meters, same category)
    console.log('\n[Step 5] Testing Duplicate Detection (50m Haversine)...');
    // ~11 meters away: lat delta 0.0001
    const duplicateRes = await request('/complaints', {
      method: 'POST',
      headers: { Authorization: `Bearer ${aliceToken}` },
      body: JSON.stringify({
        category: 'Pothole',
        description: 'Another citizen reporting the same pothole',
        lat: reportLat + 0.0001,
        lng: reportLng + 0.0001
      })
    });
    assert(duplicateRes.status === 409, 'Duplicate report returns 409 Conflict');
    assert(duplicateRes.body.duplicateFound === true, 'Response flags duplicateFound: true');
    assert(duplicateRes.body.duplicate.id === testComplaintId, 'Matching duplicate complaint identified');

    // 7. Test Force Bypass on Duplicate
    console.log('\n[Step 6] Testing Force Flag Bypass on Duplicate...');
    const forcedRes = await request('/complaints', {
      method: 'POST',
      headers: { Authorization: `Bearer ${aliceToken}` },
      body: JSON.stringify({
        category: 'Pothole',
        description: 'Forced submission of adjacent issue',
        lat: reportLat + 0.0001,
        lng: reportLng + 0.0001,
        force: true
      })
    });
    assert(forcedRes.status === 201, 'Submitting with force=true bypasses 409 duplicate check');

    // 8. Test Support Mechanism & Prioritization Boost
    console.log('\n[Step 7] Testing Support Mechanism & Priority Score Calculation...');
    const beforeSupport = await request(`/complaints/${testComplaintId}`);
    const initialScore = beforeSupport.body.complaint.priority_score;
    const initialSupports = beforeSupport.body.complaint.support_count;

    const supportRes = await request(`/complaints/${testComplaintId}/support`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${aliceToken}` }
    });
    assert(supportRes.status === 200, 'Citizen can support an existing complaint');
    assert(supportRes.body.complaint.support_count === initialSupports + 1, 'Support count incremented');
    assert(supportRes.body.complaint.priority_score > initialScore, 'Priority score increased with support');

    // Duplicate support from same citizen should fail
    const dupSupportRes = await request(`/complaints/${testComplaintId}/support`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${aliceToken}` }
    });
    assert(dupSupportRes.status === 400, 'Duplicate support from same user rejected with 400');

    // 9. Test Officer Workflow & Role Permissions
    console.log('\n[Step 8] Testing Officer Workflow & Role Restrictions...');
    // Login as Roads Officer
    const roadsOfficerLogin = await request('/auth/login', {
      method: 'POST',
      body: JSON.stringify({ email: 'officer.roads@citypulse.gov', password: 'OfficerPassword123!' })
    });
    const roadsOfficerToken = roadsOfficerLogin.body.token;

    // Login as Water Officer
    const waterOfficerLogin = await request('/auth/login', {
      method: 'POST',
      body: JSON.stringify({ email: 'officer.water@citypulse.gov', password: 'OfficerPassword123!' })
    });
    const waterOfficerToken = waterOfficerLogin.body.token;

    // Officer complaints view (sorted by priority)
    const officerComplaints = await request('/officer/complaints', {
      headers: { Authorization: `Bearer ${roadsOfficerToken}` }
    });
    assert(officerComplaints.status === 200, 'Officer can fetch department complaints');
    assert(officerComplaints.body.department === 'Roads', 'Scoper correctly to Roads department');

    // Verify priority sorting: each item score >= next item score
    let isSorted = true;
    for (let i = 0; i < officerComplaints.body.complaints.length - 1; i++) {
      if (officerComplaints.body.complaints[i].priority_score < officerComplaints.body.complaints[i + 1].priority_score) {
        isSorted = false;
        break;
      }
    }
    assert(isSorted, 'Complaints are strictly sorted descending by priority score');

    // Water officer trying to update Roads complaint should be 403 Forbidden
    const crossDeptUpdate = await request(`/complaints/${testComplaintId}/status`, {
      method: 'PATCH',
      headers: { Authorization: `Bearer ${waterOfficerToken}` },
      body: JSON.stringify({ status: 'IN_PROGRESS', note: 'Wrong officer attempt' })
    });
    assert(crossDeptUpdate.status === 403, 'Cross-department status modification rejected with 403');

    // Roads officer updates to IN_PROGRESS
    const updateInProgress = await request(`/complaints/${testComplaintId}/status`, {
      method: 'PATCH',
      headers: { Authorization: `Bearer ${roadsOfficerToken}` },
      body: JSON.stringify({ status: 'IN_PROGRESS', note: 'Work crew deployed to site' })
    });
    assert(updateInProgress.status === 200, 'Department officer can update status to IN_PROGRESS');
    assert(updateInProgress.body.complaint.status === 'IN_PROGRESS', 'Status updated to IN_PROGRESS');

    // Roads officer updates to RESOLVED
    const updateResolved = await request(`/complaints/${testComplaintId}/status`, {
      method: 'PATCH',
      headers: { Authorization: `Bearer ${roadsOfficerToken}` },
      body: JSON.stringify({ status: 'RESOLVED', note: 'Asphalt patched and inspected.' })
    });
    assert(updateResolved.status === 200, 'Department officer can update status to RESOLVED');
    assert(updateResolved.body.complaint.status === 'RESOLVED', 'Status updated to RESOLVED');

    // 10. Test Notifications & Audit Trail
    console.log('\n[Step 9] Testing Notifications & Status History...');
    const charlieNotifs = await request('/notifications', {
      headers: { Authorization: `Bearer ${charlieToken}` }
    });
    assert(charlieNotifs.status === 200, 'Citizen can retrieve notifications');
    assert(charlieNotifs.body.count >= 2, 'Notifications generated for assignment and status changes');

    const firstNotifId = charlieNotifs.body.notifications[0].id;
    const readNotif = await request(`/notifications/${firstNotifId}/read`, {
      method: 'PATCH',
      headers: { Authorization: `Bearer ${charlieToken}` }
    });
    assert(readNotif.status === 200, 'Notification marked as read');

    // Check status history on complaint
    const complaintDetail = await request(`/complaints/${testComplaintId}`);
    assert(complaintDetail.body.complaint.history.length >= 3, 'Audit trail tracks ASSIGNED -> IN_PROGRESS -> RESOLVED');

    // 11. Test Admin Management & Analytics
    console.log('\n[Step 10] Testing Admin Management & Analytics...');
    // Citizen attempting admin route should be 403
    const citizenForbidden = await request('/admin/stats', {
      headers: { Authorization: `Bearer ${aliceToken}` }
    });
    assert(citizenForbidden.status === 403, 'Citizen blocked from admin endpoints with 403');

    // Admin stats
    const statsRes = await request('/admin/stats', {
      headers: { Authorization: `Bearer ${adminToken}` }
    });
    assert(statsRes.status === 200, 'Admin can fetch analytics statistics');
    assert(statsRes.body.stats.totalComplaints > 0, 'Total complaints count present');
    assert(statsRes.body.stats.byStatus !== undefined, 'Status breakdown present');
    assert(statsRes.body.stats.byDepartment !== undefined, 'Department breakdown present');
    assert(statsRes.body.stats.avgResolutionHours !== undefined, 'Average resolution hours calculated');

    // Admin user management
    const usersRes = await request('/admin/users', {
      headers: { Authorization: `Bearer ${adminToken}` }
    });
    assert(usersRes.status === 200 && usersRes.body.users.length > 0, 'Admin can list users');

    // Admin reassign complaint
    const reassignRes = await request(`/admin/complaints/${testComplaintId}/assign`, {
      method: 'PATCH',
      headers: { Authorization: `Bearer ${adminToken}` },
      body: JSON.stringify({ department: 'Roads' })
    });
    assert(reassignRes.status === 200, 'Admin can reassign complaint department');

    console.log('\n========================================');
    console.log(`TEST RESULTS: ${passed} PASSED, ${failed} FAILED`);
    console.log('========================================\n');

    if (failed > 0) {
      process.exit(1);
    } else {
      process.exit(0);
    }
  } catch (err) {
    console.error('Fatal test error:', err);
    process.exit(1);
  } finally {
    if (server) server.close();
  }
}

runTests();

-- ============================================================================
-- Query Design Document — Group G01
-- DBMS: Microsoft SQL Server
-- Description: Reporting and operational queries for the Space Booking and
--              Maintenance Management System.
-- ============================================================================

USE SpaceBookingDB;
GO

-- ============================================================================
-- Q1: SPACE AVAILABILITY CHECK
-- ============================================================================
-- Business question:
--   Which bookable spaces are free during a given time window?
-- Target user(s):
--   All users (students, lecturers, TAs, staff) who want to submit a booking.
-- Why this is useful:
--   This is the most fundamental operational query. It filters out spaces that
--   are non-bookable (Under Maintenance, Temporarily Closed, Retired) and
--   spaces that already have an approved/checked-in booking overlapping the
--   desired time window. Users can see only spaces that are genuinely available.
-- ============================================================================

DECLARE @check_start DATETIME2 = '2026-07-15 09:00:00';
DECLARE @check_end   DATETIME2 = '2026-07-15 12:00:00';

SELECT
    s.space_code,
    s.space_name,
    s.space_type,
    s.building,
    s.floor,
    s.room_number,
    s.capacity,
    s.usage_policy,
    (SELECT COUNT(*) FROM Facilities f WHERE f.space_code = s.space_code) AS facility_count
FROM Spaces s
WHERE s.current_status = 'Available'
  AND NOT EXISTS (
      SELECT 1
      FROM Bookings b
      WHERE b.space_code = s.space_code
        AND b.status IN ('Approved', 'Checked In')
        AND b.requested_start_time < @check_end
        AND @check_start < b.requested_end_time
  )
ORDER BY s.space_type, s.capacity;

GO

-- ============================================================================
-- Q2: UPCOMING BOOKINGS DASHBOARD (NEXT 7 DAYS)
-- ============================================================================
-- Business question:
--   What approved or in-progress bookings are scheduled in the next 7 days,
--   and which staff member approved each one?
-- Target user(s):
--   Facility Staff — need to prepare spaces for upcoming sessions.
-- Why this is useful:
--   Provides a concise 7-day lookahead so staff can allocate resources
--   (check-in personnel, cleaning, equipment preparation) efficiently.
-- ============================================================================

SELECT
    b.booking_id,
    b.space_code,
    s.space_name,
    s.space_type,
    u.full_name            AS requester,
    b.requested_start_time,
    b.requested_end_time,
    b.booking_type,
    b.status,
    b.expected_participants,
    au.full_name           AS approved_by,
    b.decision_time        AS approved_at
FROM Bookings b
INNER JOIN Spaces s  ON b.space_code = s.space_code
INNER JOIN Users u   ON b.requester_id = u.user_id
LEFT  JOIN Users au  ON b.approver_id = au.user_id
WHERE b.status IN ('Approved', 'Checked In')
  AND b.requested_start_time >= SYSDATETIME()
  AND b.requested_start_time < DATEADD(DAY, 7, SYSDATETIME())
ORDER BY b.requested_start_time, b.space_code;

GO

-- ============================================================================
-- Q3: ACTIVE MAINTENANCE OVERVIEW
-- ============================================================================
-- Business question:
--   Which spaces are currently under active maintenance, what problems were
--   reported, who is assigned, and how long has the maintenance been open?
-- Target user(s):
--   Facility Manager, Facility Staff — to track and manage ongoing repairs.
-- Why this is useful:
--   Gives a real-time dashboard of all active maintenance (Reported or
--   In Progress). The duration column helps identify long-overdue items
--   that need escalation.
-- ============================================================================

SELECT
    s.space_code,
    s.space_name,
    s.space_type,
    m.maintenance_id,
    m.problem_type,
    m.problem_description,
    m.status               AS maintenance_status,
    m.start_time,
    DATEDIFF(DAY, COALESCE(m.start_time, SYSDATETIME()), SYSDATETIME()) AS days_open,
    rp.full_name           AS reported_by,
    ast.full_name          AS assigned_staff,
    m.result_note
FROM Spaces s
INNER JOIN MaintenanceRecords m ON s.space_code = m.space_code
LEFT  JOIN Users rp             ON m.reporter_id = rp.user_id
LEFT  JOIN Users ast            ON m.assigned_staff_id = ast.user_id
WHERE m.status IN ('Reported', 'In Progress')
ORDER BY days_open DESC, s.space_code;

GO

-- ============================================================================
-- Q4: BOOKING HISTORY FOR A SPECIFIC SPACE
-- ============================================================================
-- Business question:
--   What is the complete booking history for a particular space, including
--   who booked it, what for, and how it turned out?
-- Target user(s):
--   Facility Manager — for auditing, space usage analysis, and resolving
--   disputes about past bookings.
-- Why this is useful:
--   Provides a full chronological audit trail (past and future) for any
--   space. The status column captures the entire lifecycle outcome, and
--   usage_notes give qualitative detail about each session.
-- ============================================================================

DECLARE @target_space NVARCHAR(20) = 'CS-101';

SELECT
    b.booking_id,
    b.requested_start_time,
    b.requested_end_time,
    u.full_name        AS requester,
    u.role             AS requester_role,
    b.booking_type,
    b.status,
    b.actual_start_time,
    b.actual_end_time,
    b.expected_participants,
    b.purpose_of_use,
    b.usage_notes,
    au.full_name       AS approved_by,
    cu.full_name       AS checked_in_by
FROM Bookings b
INNER JOIN Users u   ON b.requester_id = u.user_id
LEFT  JOIN Users au  ON b.approver_id = au.user_id
LEFT  JOIN Users cu  ON b.check_in_person_id = cu.user_id
WHERE b.space_code = @target_space
ORDER BY b.requested_start_time DESC;

GO

-- ============================================================================
-- Q5: USER BOOKING HISTORY WITH TIMELINE
-- ============================================================================
-- Business question:
--   What is a specific user's booking history, across all spaces, showing
--   the full lifecycle (requested time, actual usage, outcome)?
-- Target user(s):
--   Facility Staff — to check a user's booking patterns before approving
--   new requests. Also useful for the user themselves to review past bookings.
-- Why this is useful:
--   A comprehensive view of one user's bookings. The DATEDIFF between
--   actual and requested times lets staff spot patterns like habitual
--   late check-ins or overstays.
-- ============================================================================

DECLARE @target_user INT = 2;  -- Grace Hopper

SELECT
    b.booking_id,
    s.space_code,
    s.space_name,
    b.requested_start_time,
    b.requested_end_time,
    b.actual_start_time,
    b.actual_end_time,
    DATEDIFF(MINUTE, b.requested_start_time, b.actual_start_time) AS check_in_lag_minutes,
    b.status,
    b.booking_type,
    b.purpose_of_use,
    b.usage_notes
FROM Bookings b
INNER JOIN Spaces s ON b.space_code = s.space_code
WHERE b.requester_id = @target_user
ORDER BY b.requested_start_time DESC;

GO

-- ============================================================================
-- Q6: NO-SHOW REPORT
-- ============================================================================
-- Business question:
--   Which bookings resulted in no-shows, and are there repeat offenders
--   (users or spaces) that warrant attention?
-- Target user(s):
--   Facility Manager — to enforce booking policies and identify misuse.
-- Why this is useful:
--   No-shows waste space capacity that others could have used. Grouping
--   by requester and space helps identify patterns: a user who repeatedly
--   no-shows may need a warning, and a space with frequent no-shows may
--   have an availability perception problem.
-- ============================================================================

SELECT
    b.booking_id,
    b.space_code,
    s.space_name,
    u.full_name        AS requester,
    u.department,
    b.requested_start_time,
    b.requested_end_time,
    b.booking_type,
    DATEDIFF(HOUR, b.requested_start_time, b.requested_end_time) AS requested_duration_hours,
    au.full_name       AS approved_by
FROM Bookings b
INNER JOIN Spaces s ON b.space_code = s.space_code
INNER JOIN Users u  ON b.requester_id = u.user_id
LEFT  JOIN Users au ON b.approver_id = au.user_id
WHERE b.status = 'No-Show'
ORDER BY b.requested_start_time DESC;

-- Companion: count no-shows per user to spot repeat offenders.
SELECT
    u.user_id,
    u.full_name,
    u.role,
    COUNT(*) AS no_show_count
FROM Bookings b
INNER JOIN Users u ON b.requester_id = u.user_id
WHERE b.status = 'No-Show'
GROUP BY u.user_id, u.full_name, u.role
ORDER BY no_show_count DESC;

GO

-- ============================================================================
-- Q7: SPACE UTILIZATION SUMMARY
-- ============================================================================
-- Business question:
--   How much is each space being used? What is the no-show and cancellation
--   rate? What is the average booking size compared to capacity?
-- Target user(s):
--   Facility Manager — for strategic decisions about space allocation,
--   identifying underutilized spaces, and planning capacity.
-- Why this is useful:
--   Aggregates all bookings into a per-space summary: total bookings,
--   completed vs. no-show vs. cancelled counts, average participants,
--   and average requested duration. A low completion rate or high
--   no-show rate may indicate a space that needs policy changes.
-- ============================================================================

SELECT
    s.space_code,
    s.space_name,
    s.space_type,
    s.capacity,
    COUNT(b.booking_id)                                                   AS total_bookings,
    SUM(CASE WHEN b.status = 'Completed'   THEN 1 ELSE 0 END)            AS completed,
    SUM(CASE WHEN b.status = 'No-Show'     THEN 1 ELSE 0 END)            AS no_show,
    SUM(CASE WHEN b.status = 'Cancelled'   THEN 1 ELSE 0 END)            AS cancelled,
    SUM(CASE WHEN b.status = 'Rejected'    THEN 1 ELSE 0 END)            AS rejected,
    ROUND(AVG(CAST(b.expected_participants AS FLOAT)), 1)                AS avg_participants,
    ROUND(AVG(CAST(b.expected_participants AS FLOAT)) / s.capacity, 2)  AS utilization_ratio,
    ROUND(AVG(DATEDIFF(HOUR, b.requested_start_time, b.requested_end_time)), 1) AS avg_duration_hours
FROM Spaces s
LEFT JOIN Bookings b ON s.space_code = b.space_code
GROUP BY s.space_code, s.space_name, s.space_type, s.capacity
ORDER BY total_bookings DESC, s.space_code;

GO

-- ============================================================================
-- Q8: FACILITIES IN POOR CONDITION
-- ============================================================================
-- Business question:
--   Which spaces have facilities that are broken or in fair condition,
--   and what specific items need attention?
-- Target user(s):
--   Facility Staff — to prioritize repairs and replacements.
-- Why this is useful:
--   Supplies a targeted list of equipment needing service, grouped by
--   space. Staff can use this to plan maintenance rounds and order
--   replacement parts without manually inspecting every room.
-- ============================================================================

SELECT
    s.space_code,
    s.space_name,
    s.space_type,
    s.current_status,
    f.facility_id,
    f.facility_name,
    f.condition
FROM Spaces s
INNER JOIN Facilities f ON s.space_code = f.space_code
WHERE f.condition IN ('Broken', 'Fair')
ORDER BY
    CASE f.condition
        WHEN 'Broken' THEN 1
        WHEN 'Fair'   THEN 2
    END,
    s.space_code,
    f.facility_name;

GO

-- ============================================================================
-- QUERY COVERAGE SUMMARY
-- ============================================================================
-- Q1  Space availability check               (All users — booking workflow)
-- Q2  Upcoming bookings (7-day dashboard)    (Facility Staff — space prep)
-- Q3  Active maintenance overview            (Facility Manager — tracking)
-- Q4  Booking history for a specific space   (Facility Manager — audit)
-- Q5  User booking history with timeline     (Facility Staff — user check)
-- Q6  No-show report + repeat offenders      (Facility Manager — policy)
-- Q7  Space utilization summary              (Facility Manager — strategy)
-- Q8  Facilities in poor condition           (Facility Staff — repairs)
-- ============================================================================

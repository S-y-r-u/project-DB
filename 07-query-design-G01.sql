-- ============================================================================
-- Query Design Document — Group G01
-- DBMS: Microsoft SQL Server
-- Description: 28 reporting and operational queries for the Space Booking
--              and Maintenance Management System.
-- ============================================================================

USE SpaceBookingDB;
GO

-- ============================================================================
-- SECTION 1 — SPACE QUERIES
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Q1: SPACE AVAILABILITY CHECK
-- ----------------------------------------------------------------------------
-- Business question:
--   Which bookable spaces are free during a given time window?
-- Target user(s):
--   All users (students, lecturers, TAs, staff) who want to submit a booking.
-- Explanation:
--   The most fundamental operational query. Excludes non-bookable spaces
--   (Under Maintenance, Temporarily Closed, Retired) and spaces with
--   an approved/checked-in booking overlapping the desired window.
-- ----------------------------------------------------------------------------
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

-- ----------------------------------------------------------------------------
-- Q2: SPACES GROUPED BY CURRENT STATUS
-- ----------------------------------------------------------------------------
-- Business question:
--   How many spaces are in each operational status across the school?
-- Target user(s):
--   Facility Manager — for high-level overview of space availability.
-- Explanation:
--   Quick dashboard showing the count of spaces per status (Available,
--   Under Maintenance, Temporarily Closed, Retired). Useful for monthly
--   reports and capacity planning.
-- ----------------------------------------------------------------------------
SELECT
    current_status,
    COUNT(*)            AS space_count,
    STRING_AGG(space_code, ', ') WITHIN GROUP (ORDER BY space_code) AS spaces
FROM Spaces
GROUP BY current_status
ORDER BY space_count DESC;
GO

-- ----------------------------------------------------------------------------
-- Q3: SPACES BY TYPE WITH CAPACITY RANGES
-- ----------------------------------------------------------------------------
-- Business question:
--   What spaces exist of each type, and how do their capacities compare?
-- Target user(s):
--   Facility Manager, Department Administrator — for planning events.
-- Explanation:
--   Shows min, max, and average capacity per space type so users can
--   quickly identify which type of space meets their size requirements.
-- ----------------------------------------------------------------------------
SELECT
    space_type,
    COUNT(*)            AS count,
    MIN(capacity)       AS min_capacity,
    AVG(capacity)       AS avg_capacity,
    MAX(capacity)       AS max_capacity,
    STRING_AGG(space_code, ', ') WITHIN GROUP (ORDER BY capacity) AS spaces
FROM Spaces
GROUP BY space_type
ORDER BY avg_capacity DESC;
GO

-- ----------------------------------------------------------------------------
-- Q4: SPACES WITH THEIR FACILITY INVENTORY
-- ----------------------------------------------------------------------------
-- Business question:
--   What facilities does each space have, and how many total items?
-- Target user(s):
--   All users — to determine if a space has the equipment they need.
-- Explanation:
--   Left join from Spaces to Facilities, counting facilities per space.
--   LIB-301 (zero facilities) appears with NULLs so users know it has
--   no equipment listed.
-- ----------------------------------------------------------------------------
SELECT
    s.space_code,
    s.space_name,
    s.space_type,
    s.current_status,
    COUNT(f.facility_id)                               AS facility_count,
    STRING_AGG(f.facility_name + N' (' + ISNULL(f.condition, N'unknown') + N')', N'; ')
        WITHIN GROUP (ORDER BY f.facility_name)        AS facility_list
FROM Spaces s
LEFT JOIN Facilities f ON s.space_code = f.space_code
GROUP BY s.space_code, s.space_name, s.space_type, s.current_status
ORDER BY s.space_type, s.space_code;
GO

-- ----------------------------------------------------------------------------
-- Q5: SPACES THAT HAVE NEVER BEEN BOOKED
-- ----------------------------------------------------------------------------
-- Business question:
--   Which spaces have zero booking requests in the system?
-- Target user(s):
--   Facility Manager — to identify underutilized or newly added spaces.
-- Explanation:
--   Uses an anti-join to find spaces with no associated bookings.
--   These spaces may need promotion, policy review, or decommissioning.
-- ----------------------------------------------------------------------------
SELECT
    s.space_code,
    s.space_name,
    s.space_type,
    s.capacity,
    s.current_status,
    s.usage_policy
FROM Spaces s
WHERE NOT EXISTS (
    SELECT 1 FROM Bookings b WHERE b.space_code = s.space_code
)
ORDER BY s.space_code;
GO


-- ============================================================================
-- SECTION 2 — FACILITY QUERIES
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Q6: FACILITIES IN POOR CONDITION
-- ----------------------------------------------------------------------------
-- Business question:
--   Which spaces have facilities that are broken or in fair condition,
--   and what specific items need attention?
-- Target user(s):
--   Facility Staff — to prioritize repairs and replacements.
-- Explanation:
--   Lists all facilities marked Broken or Fair, sorted by severity
--   (Broken first), then by space. Staff can use this to plan
--   maintenance rounds without inspecting every room manually.
-- ----------------------------------------------------------------------------
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

-- ----------------------------------------------------------------------------
-- Q7: MOST COMMON FACILITY TYPES ACROSS ALL SPACES
-- ----------------------------------------------------------------------------
-- Business question:
--   What are the most frequently installed facility types, and how many
--   of each exist across the school?
-- Target user(s):
--   Facility Manager — for budgeting and procurement planning.
-- Explanation:
--   Groups facilities by name, counts occurrences, and shows which
--   spaces have them. Helps identify commonly needed equipment and
--   potential standardization opportunities.
-- ----------------------------------------------------------------------------
SELECT
    facility_name,
    COUNT(*)            AS total_installed,
    STRING_AGG(space_code, ', ') WITHIN GROUP (ORDER BY space_code) AS installed_in
FROM Facilities
GROUP BY facility_name
ORDER BY total_installed DESC;
GO

-- ----------------------------------------------------------------------------
-- Q8: SPACES WITH NO FACILITIES
-- ----------------------------------------------------------------------------
-- Business question:
--   Which spaces have zero facilities recorded in the system?
-- Target user(s):
--   Facility Staff — to determine if facilities need to be added.
-- Explanation:
--   Spaces with no facility records may be missing data entry rather
--   than genuinely having no equipment. This query flags those spaces
--   so staff can investigate and update the inventory.
-- ----------------------------------------------------------------------------
SELECT
    s.space_code,
    s.space_name,
    s.space_type,
    s.current_status
FROM Spaces s
WHERE NOT EXISTS (
    SELECT 1 FROM Facilities f WHERE f.space_code = s.space_code
)
ORDER BY s.space_code;
GO


-- ============================================================================
-- SECTION 3 — BOOKING OPERATIONAL QUERIES
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Q9: UPCOMING APPROVED BOOKINGS (NEXT 7 DAYS)
-- ----------------------------------------------------------------------------
-- Business question:
--   What approved or in-progress bookings are scheduled in the next week?
-- Target user(s):
--   Facility Staff — need to prepare spaces for upcoming sessions.
-- Explanation:
--   7-day lookahead so staff can allocate check-in personnel, schedule
--   cleaning, and prepare equipment. Shows the space, requester, time
--   window, and who approved each booking.
-- ----------------------------------------------------------------------------
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

-- ----------------------------------------------------------------------------
-- Q10: CURRENTLY CHECKED-IN BOOKINGS (REAL TIME)
-- ----------------------------------------------------------------------------
-- Business question:
--   Which bookings are in progress right now?
-- Target user(s):
--   Facility Staff, Facility Manager — to monitor real-time occupancy.
-- Explanation:
--   Shows all bookings currently in 'Checked In' status, along with
--   actual start time, who checked in, and initial room condition.
--   Useful for emergency response and head-count tracking.
-- ----------------------------------------------------------------------------
SELECT
    b.booking_id,
    b.space_code,
    s.space_name,
    s.space_type,
    u.full_name           AS requester,
    b.requested_start_time,
    b.requested_end_time,
    b.booking_type,
    b.actual_start_time,
    cu.full_name          AS checked_in_by,
    b.initial_condition,
    DATEDIFF(MINUTE, b.actual_start_time, SYSDATETIME()) AS minutes_elapsed
FROM Bookings b
INNER JOIN Spaces s       ON b.space_code = s.space_code
INNER JOIN Users u        ON b.requester_id = u.user_id
LEFT  JOIN Users cu       ON b.check_in_person_id = cu.user_id
WHERE b.status = 'Checked In'
ORDER BY b.actual_start_time;
GO

-- ----------------------------------------------------------------------------
-- Q11: PENDING BOOKINGS AWAITING APPROVAL
-- ----------------------------------------------------------------------------
-- Business question:
--   Which booking requests are still pending staff review?
-- Target user(s):
--   Facility Staff, Facility Manager — the approval queue.
-- Explanation:
--   Staff need a clean queue of submissions waiting for a decision.
--   Shows who requested what space, when, and for what purpose, ordered
--   by submission time so the oldest requests get attention first.
-- ----------------------------------------------------------------------------
SELECT
    b.booking_id,
    b.space_code,
    s.space_name,
    u.full_name          AS requester,
    u.role               AS requester_role,
    u.department,
    b.requested_start_time,
    b.requested_end_time,
    DATEDIFF(DAY, b.booking_id, SYSDATETIME()) AS days_waiting,
    b.booking_type,
    b.purpose_of_use,
    b.expected_participants
FROM Bookings b
INNER JOIN Spaces s ON b.space_code = s.space_code
INNER JOIN Users u  ON b.requester_id = u.user_id
WHERE b.status = 'Pending'
ORDER BY b.requested_start_time, b.booking_id;
GO

-- ----------------------------------------------------------------------------
-- Q12: BOOKING HISTORY FOR A SPECIFIC SPACE
-- ----------------------------------------------------------------------------
-- Business question:
--   What is the complete booking history for a particular space, including
--   who booked it, what for, and how it turned out?
-- Target user(s):
--   Facility Manager — for auditing and space usage analysis.
-- Explanation:
--   Full chronological audit trail (past and future) for any space.
--   The status column captures the lifecycle outcome, usage_notes give
--   qualitative detail, and the join shows who approved and checked in.
-- ----------------------------------------------------------------------------
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
    DATEDIFF(MINUTE, b.requested_start_time, b.actual_start_time) AS check_in_lag_minutes,
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

-- ----------------------------------------------------------------------------
-- Q13: USER BOOKING HISTORY
-- ----------------------------------------------------------------------------
-- Business question:
--   What is a specific user's booking history across all spaces?
-- Target user(s):
--   Facility Staff — to check a user's patterns before approving new
--   requests. Also useful for the user themselves to review past bookings.
-- Explanation:
--   Shows every booking for a user with the space, time window, status,
--   and actual usage times. The lag calculation helps identify habitual
--   late arrivals or overstays.
-- ----------------------------------------------------------------------------
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

-- ----------------------------------------------------------------------------
-- Q14: BOOKINGS FOR A SPECIFIC DATE
-- ----------------------------------------------------------------------------
-- Business question:
--   What is happening on a given day across all spaces?
-- Target user(s):
--   Facility Staff, All users — to see the daily schedule.
-- Explanation:
--   Shows all bookings for a single date regardless of status, giving
--   a complete picture of space usage for that day. Useful for the
--   front office when walk-in users ask about room availability.
-- ----------------------------------------------------------------------------
DECLARE @target_date DATE = '2026-07-07';

SELECT
    b.booking_id,
    b.space_code,
    s.space_name,
    b.requested_start_time,
    b.requested_end_time,
    u.full_name        AS requester,
    b.booking_type,
    b.status,
    b.expected_participants,
    b.purpose_of_use
FROM Bookings b
INNER JOIN Spaces s ON b.space_code = s.space_code
INNER JOIN Users u  ON b.requester_id = u.user_id
WHERE CAST(b.requested_start_time AS DATE) = @target_date
ORDER BY b.requested_start_time, b.space_code;
GO

-- ----------------------------------------------------------------------------
-- Q15: BOOKING TYPE DISTRIBUTION
-- ----------------------------------------------------------------------------
-- Business question:
--   How are bookings distributed across types (Lecture, Examination, etc.)?
-- Target user(s):
--   Facility Manager — to understand how spaces are being used.
-- Explanation:
--   Shows total count and percentage share of each booking type.
--   Helps identify dominant use patterns — e.g., if Student Activity
--   bookings dominate, the school may need more flexible spaces.
-- ----------------------------------------------------------------------------
SELECT
    booking_type,
    COUNT(*)                                    AS count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct,
    STRING_AGG(status, ', ')           AS observed_statuses
FROM Bookings
GROUP BY booking_type
ORDER BY count DESC;
GO


-- ============================================================================
-- SECTION 4 — BOOKING LIFECYCLE QUERIES
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Q16: COMPLETED BOOKINGS WITH CHECK-IN/CHECK-OUT TRAIL
-- ----------------------------------------------------------------------------
-- Business question:
--   Which bookings were fully completed, and what was the actual usage
--   compared to the requested time?
-- Target user(s):
--   Facility Staff, Facility Manager — reviewing session compliance.
-- Explanation:
--   Shows every completed booking with actual start/end times, who
--   performed check-in/check-out, and the condition notes. The
--   overrun calculation helps identify sessions that exceeded their
--   allotted time, which may affect subsequent bookings.
-- ----------------------------------------------------------------------------
SELECT
    b.booking_id,
    b.space_code,
    s.space_name,
    u.full_name                AS requester,
    b.requested_start_time,
    b.requested_end_time,
    b.actual_start_time,
    b.actual_end_time,
    DATEDIFF(MINUTE, b.requested_end_time, b.actual_end_time) AS overrun_minutes,
    cu_in.full_name            AS checked_in_by,
    cu_out.full_name           AS checked_out_by,
    b.initial_condition,
    b.final_condition,
    b.usage_notes
FROM Bookings b
INNER JOIN Spaces s         ON b.space_code = s.space_code
INNER JOIN Users u          ON b.requester_id = u.user_id
LEFT  JOIN Users cu_in      ON b.check_in_person_id = cu_in.user_id
LEFT  JOIN Users cu_out     ON b.check_in_person_id = cu_out.user_id
WHERE b.status = 'Completed'
ORDER BY b.requested_start_time DESC;
GO

-- ----------------------------------------------------------------------------
-- Q17: REJECTED BOOKINGS WITH REASONS
-- ----------------------------------------------------------------------------
-- Business question:
--   Which booking requests were rejected, by whom, and for what reasons?
-- Target user(s):
--   Facility Manager — to review rejection patterns and staff decisions.
-- Explanation:
--   Lists every rejected booking with the rejection reason, who rejected
--   it, and when. The Facility Manager can use this to ensure consistent
--   application of booking policies across all staff.
-- ----------------------------------------------------------------------------
SELECT
    b.booking_id,
    b.space_code,
    s.space_name,
    u.full_name            AS requester,
    u.role                 AS requester_role,
    b.requested_start_time,
    b.requested_end_time,
    b.booking_type,
    b.purpose_of_use,
    au.full_name           AS rejected_by,
    b.decision_time        AS rejected_at,
    b.decision_note,
    b.rejection_reason
FROM Bookings b
INNER JOIN Spaces s ON b.space_code = s.space_code
INNER JOIN Users u  ON b.requester_id = u.user_id
INNER JOIN Users au ON b.approver_id = au.user_id
WHERE b.status = 'Rejected'
ORDER BY b.decision_time DESC;
GO

-- ----------------------------------------------------------------------------
-- Q18: CANCELLED BOOKINGS
-- ----------------------------------------------------------------------------
-- Business question:
--   Which bookings were cancelled after being approved, and what was the
--   cancellation pattern?
-- Target user(s):
--   Facility Manager — to track wastage and adjust overbooking policies.
-- Explanation:
--   Shows all cancelled bookings, including the approval details before
--   cancellation. A high cancellation rate for certain spaces or users
--   may indicate a need to adjust allocation policies.
-- ----------------------------------------------------------------------------
SELECT
    b.booking_id,
    b.space_code,
    s.space_name,
    u.full_name            AS requester,
    u.role                 AS requester_role,
    b.requested_start_time,
    b.requested_end_time,
    b.booking_type,
    b.purpose_of_use,
    au.full_name           AS originally_approved_by,
    b.decision_time        AS was_approved_at,
    DATEDIFF(DAY, b.decision_time, b.requested_start_time) AS days_before_cancellation
FROM Bookings b
INNER JOIN Spaces s ON b.space_code = s.space_code
INNER JOIN Users u  ON b.requester_id = u.user_id
LEFT  JOIN Users au ON b.approver_id = au.user_id
WHERE b.status = 'Cancelled'
ORDER BY b.decision_time DESC;
GO

-- ----------------------------------------------------------------------------
-- Q19: NO-SHOW REPORT WITH REPEAT OFFENDERS
-- ----------------------------------------------------------------------------
-- Business question:
--   Which bookings resulted in no-shows, and are there users who
--   repeatedly fail to show up?
-- Target user(s):
--   Facility Manager — to enforce booking policies.
-- Explanation:
--   Two-part query: first lists individual no-show bookings with detail,
--   then aggregates by user to identify repeat offenders who may need
--   a warning or temporary suspension of booking privileges.
-- ----------------------------------------------------------------------------
SELECT
    b.booking_id,
    b.space_code,
    s.space_name,
    u.full_name        AS requester,
    u.department,
    b.requested_start_time,
    b.requested_end_time,
    b.booking_type,
    DATEDIFF(HOUR, b.requested_start_time, b.requested_end_time) AS duration_hours,
    au.full_name       AS approved_by
FROM Bookings b
INNER JOIN Spaces s ON b.space_code = s.space_code
INNER JOIN Users u  ON b.requester_id = u.user_id
LEFT  JOIN Users au ON b.approver_id = au.user_id
WHERE b.status = 'No-Show'
ORDER BY b.requested_start_time DESC;

-- Repeat-offender summary
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
-- SECTION 5 — MAINTENANCE QUERIES
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Q20: ACTIVE MAINTENANCE OVERVIEW
-- ----------------------------------------------------------------------------
-- Business question:
--   Which spaces are currently under maintenance, and how long has each
--   issue been open?
-- Target user(s):
--   Facility Manager, Facility Staff — to track ongoing repairs.
-- Explanation:
--   Shows all active (Reported or In Progress) maintenance records with
--   their duration. Days-open helps identify overdue items requiring
--   escalation. Also shows who reported it and who is assigned.
-- ----------------------------------------------------------------------------
SELECT
    s.space_code,
    s.space_name,
    s.space_type,
    m.maintenance_id,
    m.problem_type,
    m.problem_description,
    m.status               AS maintenance_status,
    m.start_time,
    DATEDIFF(DAY, ISNULL(m.start_time, SYSDATETIME()), SYSDATETIME()) AS days_open,
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

-- ----------------------------------------------------------------------------
-- Q21: MAINTENANCE HISTORY FOR A SPECIFIC SPACE
-- ----------------------------------------------------------------------------
-- Business question:
--   What is the complete maintenance history for a space — every repair,
--   cleaning, and inspection?
-- Target user(s):
--   Facility Manager — for space audit and recurring problem detection.
-- Explanation:
--   Shows every maintenance record for a given space in reverse
--   chronological order. Recurring problems (e.g., repeated AC failures)
--   become visible, informing decisions about equipment replacement.
-- ----------------------------------------------------------------------------
DECLARE @maint_space NVARCHAR(20) = 'CS-210';

SELECT
    m.maintenance_id,
    m.problem_type,
    m.problem_description,
    m.status          AS maintenance_status,
    m.start_time,
    m.completion_time,
    DATEDIFF(DAY, m.start_time, m.completion_time) AS duration_days,
    rp.full_name      AS reported_by,
    ast.full_name     AS assigned_staff,
    m.result_note
FROM MaintenanceRecords m
LEFT JOIN Users rp  ON m.reporter_id = rp.user_id
LEFT JOIN Users ast ON m.assigned_staff_id = ast.user_id
WHERE m.space_code = @maint_space
ORDER BY m.start_time DESC;
GO

-- ----------------------------------------------------------------------------
-- Q22: COMPLETED MAINTENANCE WITH RESOLUTION DETAILS
-- ----------------------------------------------------------------------------
-- Business question:
--   What maintenance work has been completed, how long did it take, and
--   what was the outcome?
-- Target user(s):
--   Facility Manager — to evaluate staff performance and repair efficiency.
-- Explanation:
--   Lists all completed maintenance with duration (days from start to
--   completion) and the result note. The duration helps benchmark
--   repair times for different problem types.
-- ----------------------------------------------------------------------------
SELECT
    m.maintenance_id,
    m.space_code,
    s.space_name,
    m.problem_type,
    m.problem_description,
    m.start_time,
    m.completion_time,
    DATEDIFF(DAY, m.start_time, m.completion_time) AS repair_duration_days,
    ast.full_name      AS assigned_staff,
    m.result_note
FROM MaintenanceRecords m
INNER JOIN Spaces s ON m.space_code = s.space_code
LEFT  JOIN Users ast ON m.assigned_staff_id = ast.user_id
WHERE m.status = 'Completed'
ORDER BY m.completion_time DESC;
GO

-- ----------------------------------------------------------------------------
-- Q23: UNASSIGNED MAINTENANCE REQUESTS
-- ----------------------------------------------------------------------------
-- Business question:
--   Which maintenance requests have not yet been assigned to any staff
--   member?
-- Target user(s):
--   Facility Manager — to dispatch work orders.
-- Explanation:
--   Shows all maintenance records with assigned_staff_id IS NULL.
--   These are open tasks that no one is actively working on, and the
--   manager needs to assign them to prevent delays.
-- ----------------------------------------------------------------------------
SELECT
    m.maintenance_id,
    m.space_code,
    s.space_name,
    m.problem_type,
    m.problem_description,
    m.status          AS maintenance_status,
    rp.full_name      AS reported_by,
    m.start_time,
    DATEDIFF(DAY, ISNULL(m.start_time, SYSDATETIME()), SYSDATETIME()) AS days_since_report
FROM MaintenanceRecords m
INNER JOIN Spaces s ON m.space_code = s.space_code
LEFT  JOIN Users rp ON m.reporter_id = rp.user_id
WHERE m.assigned_staff_id IS NULL
ORDER BY days_since_report DESC;
GO

-- ----------------------------------------------------------------------------
-- Q24: MOST COMMON MAINTENANCE PROBLEM TYPES
-- ----------------------------------------------------------------------------
-- Business question:
--   What are the most frequent types of maintenance issues across all
--   spaces?
-- Target user(s):
--   Facility Manager — for preventive maintenance planning and budgeting.
-- Explanation:
--   Groups by problem type, counts occurrences, and calculates the
--   average resolution time for completed records. Frequent issues
--   may warrant preventive replacement (e.g., aging projectors).
-- ----------------------------------------------------------------------------
SELECT
    m.problem_type,
    COUNT(*)                                        AS total_reports,
    SUM(CASE WHEN m.status = 'Completed' THEN 1 ELSE 0 END) AS completed,
    ROUND(AVG(CASE WHEN m.status = 'Completed'
        THEN DATEDIFF(DAY, m.start_time, m.completion_time)
        ELSE NULL END), 1)                          AS avg_completion_days,
    STRING_AGG(s.space_code, ', ')         AS affected_spaces
FROM MaintenanceRecords m
INNER JOIN Spaces s ON m.space_code = s.space_code
GROUP BY m.problem_type
ORDER BY total_reports DESC;
GO


-- ============================================================================
-- SECTION 6 — ANALYTICS & REPORTING QUERIES
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Q25: SPACE UTILIZATION SUMMARY
-- ----------------------------------------------------------------------------
-- Business question:
--   How much is each space being used? What are the no-show and
--   cancellation rates?
-- Target user(s):
--   Facility Manager — for strategic capacity planning.
-- Explanation:
--   Aggregates all bookings per space: completed, no-show, cancelled,
--   rejected counts, average participants, and utilization ratio
--   (participants vs. capacity). A low completion rate flags spaces
--   that may need policy changes.
-- ----------------------------------------------------------------------------
SELECT
    s.space_code,
    s.space_name,
    s.space_type,
    s.capacity,
    s.current_status,
    COUNT(b.booking_id)                                                   AS total_bookings,
    SUM(CASE WHEN b.status = 'Completed'   THEN 1 ELSE 0 END)            AS completed,
    SUM(CASE WHEN b.status = 'No-Show'     THEN 1 ELSE 0 END)            AS no_show,
    SUM(CASE WHEN b.status = 'Cancelled'   THEN 1 ELSE 0 END)            AS cancelled,
    SUM(CASE WHEN b.status = 'Rejected'    THEN 1 ELSE 0 END)            AS rejected,
    ROUND(AVG(CAST(b.expected_participants AS FLOAT)), 1)                AS avg_participants,
    ROUND(AVG(CAST(b.expected_participants AS FLOAT)) / NULLIF(s.capacity, 0), 2) AS utilization_ratio,
    ROUND(AVG(DATEDIFF(HOUR, b.requested_start_time, b.requested_end_time)), 1)  AS avg_duration_hours
FROM Spaces s
LEFT JOIN Bookings b ON s.space_code = b.space_code
GROUP BY s.space_code, s.space_name, s.space_type, s.capacity, s.current_status
ORDER BY total_bookings DESC, s.space_code;
GO

-- ----------------------------------------------------------------------------
-- Q26: MOST FREQUENT BOOKERS BY ROLE
-- ----------------------------------------------------------------------------
-- Business question:
--   Which users (and roles) submit the most booking requests?
-- Target user(s):
--   Facility Manager — to identify heavy users and adjust policies.
-- Explanation:
--   Ranks users by total booking count and shows their role. If a small
--   number of users dominate bookings, the manager may consider limits
--   per user or per role to ensure fair access.
-- ----------------------------------------------------------------------------
SELECT
    u.user_id,
    u.full_name,
    u.role,
    u.department,
    COUNT(b.booking_id)                              AS total_bookings,
    SUM(CASE WHEN b.status = 'Completed' THEN 1 ELSE 0 END) AS completed,
    SUM(CASE WHEN b.status = 'Rejected'  THEN 1 ELSE 0 END) AS rejected,
    STRING_AGG(b.booking_type, ', ')        AS booking_types
FROM Users u
INNER JOIN Bookings b ON u.user_id = b.requester_id
GROUP BY u.user_id, u.full_name, u.role, u.department
ORDER BY total_bookings DESC;
GO

-- ----------------------------------------------------------------------------
-- Q27: STAFF APPROVAL / REJECTION STATISTICS
-- ----------------------------------------------------------------------------
-- Business question:
--   How many bookings has each staff member approved or rejected?
-- Target user(s):
--   Facility Manager — to evaluate staff workload and decision patterns.
-- Explanation:
--   Shows each staff member who has acted on bookings (approve or reject),
--   with counts of each decision type. Helps ensure the approval workload
--   is distributed fairly and identify if any staff member is unusually
--   strict or lenient.
-- ----------------------------------------------------------------------------
SELECT
    au.user_id,
    au.full_name,
    au.role,
    COUNT(*)                                        AS total_decisions,
    SUM(CASE WHEN b.status = 'Approved' THEN 1 ELSE 0 END)  AS approved,
    SUM(CASE WHEN b.status = 'Rejected' THEN 1 ELSE 0 END)  AS rejected,
    ROUND(100.0 * SUM(CASE WHEN b.status = 'Approved' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0), 1)                   AS approval_pct,
    STRING_AGG(b.space_code, ', ')          AS spaces_covered
FROM Bookings b
INNER JOIN Users au ON b.approver_id = au.user_id
WHERE b.status IN ('Approved', 'Rejected')
GROUP BY au.user_id, au.full_name, au.role
ORDER BY total_decisions DESC;
GO

-- ----------------------------------------------------------------------------
-- Q28: OVERLAPPING BOOKING AUDIT (CONFLICT DETECTION)
-- ----------------------------------------------------------------------------
-- Business question:
--   Are there any existing overlapping approved/checked-in bookings that
--   should not coexist for the same space?
-- Target user(s):
--   Facility Manager — for periodic data integrity audits.
-- Explanation:
--   Self-join on Bookings comparing every pair of approved/checked-in
--   bookings for the same space. A clean result (empty set) means the
--   overlap trigger is working correctly. Any rows returned indicate
--   a data integrity issue that needs investigation.
-- ----------------------------------------------------------------------------
SELECT DISTINCT
    b1.booking_id               AS booking_1_id,
    b1.space_code,
    b1.requested_start_time     AS b1_start,
    b1.requested_end_time       AS b1_end,
    b1.status                   AS b1_status,
    u1.full_name                AS b1_requester,
    b2.booking_id               AS booking_2_id,
    b2.requested_start_time     AS b2_start,
    b2.requested_end_time       AS b2_end,
    b2.status                   AS b2_status,
    u2.full_name                AS b2_requester
FROM Bookings b1
INNER JOIN Bookings b2
    ON  b1.space_code = b2.space_code
    AND b1.booking_id < b2.booking_id
    AND b1.requested_start_time < b2.requested_end_time
    AND b2.requested_start_time < b1.requested_end_time
INNER JOIN Users u1 ON b1.requester_id = u1.user_id
INNER JOIN Users u2 ON b2.requester_id = u2.user_id
WHERE b1.status IN ('Approved', 'Checked In')
  AND b2.status IN ('Approved', 'Checked In')
ORDER BY b1.space_code, b1.requested_start_time;
GO


-- ============================================================================
-- QUERY COVERAGE SUMMARY
-- ============================================================================
--  Section 1 — Space Queries
--    Q1  Space availability check                           (All users)
--    Q2  Spaces grouped by current status                   (Facility Manager)
--    Q3  Spaces by type with capacity ranges                (Facility Manager)
--    Q4  Spaces with their facility inventory               (All users)
--    Q5  Spaces that have never been booked                 (Facility Manager)
--
--  Section 2 — Facility Queries
--    Q6  Facilities in poor condition                       (Facility Staff)
--    Q7  Most common facility types across spaces           (Facility Manager)
--    Q8  Spaces with no facilities                          (Facility Staff)
--
--  Section 3 — Booking Operational Queries
--    Q9  Upcoming approved bookings (next 7 days)           (Facility Staff)
--    Q10 Currently checked-in bookings (real time)          (Facility Staff)
--    Q11 Pending bookings awaiting approval                 (Facility Staff)
--    Q12 Booking history for a specific space               (Facility Manager)
--    Q13 User booking history                               (Facility Staff)
--    Q14 Bookings for a specific date                       (All users)
--    Q15 Booking type distribution                          (Facility Manager)
--
--  Section 4 — Booking Lifecycle Queries
--    Q16 Completed bookings with check-in/out trail         (Facility Staff)
--    Q17 Rejected bookings with reasons                     (Facility Manager)
--    Q18 Cancelled bookings                                 (Facility Manager)
--    Q19 No-show report with repeat offenders               (Facility Manager)
--
--  Section 5 — Maintenance Queries
--    Q20 Active maintenance overview                        (Facility Manager)
--    Q21 Maintenance history for a specific space           (Facility Manager)
--    Q22 Completed maintenance with resolution details      (Facility Manager)
--    Q23 Unassigned maintenance requests                    (Facility Manager)
--    Q24 Most common maintenance problem types              (Facility Manager)
--
--  Section 6 — Analytics & Reporting Queries
--    Q25 Space utilization summary                          (Facility Manager)
--    Q26 Most frequent bookers by role                      (Facility Manager)
--    Q27 Staff approval / rejection statistics              (Facility Manager)
--    Q28 Overlapping booking audit (conflict detection)     (Facility Manager)
-- ============================================================================

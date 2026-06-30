-- ============================================================================
-- Query Design — Group G01
-- DBMS: Microsoft SQL Server
-- Description: 7 meaningful business queries for the Space Booking and
--              Maintenance Management System.
-- ============================================================================

USE SpaceBookingDB;
GO

-- ============================================================================
-- Q1: Find available spaces for a given date/time range
-- ============================================================================
-- Business question:
--   "Which spaces are available to book on 2026-07-07 between 13:00 and 17:00?"
-- Target user(s):
--   Students, Lecturers, TAs, Department Administrators (anyone making a
--   booking request).
-- Why useful:
--   Instead of manually checking spreadsheets, a requester can query
--   available spaces directly. The query excludes spaces that are
--   non-bookable by status AND spaces already occupied by an approved or
--   checked-in booking during the requested window. A LEFT JOIN with a
--   NULL check implements the "not overlapping" condition without a
--   correlated subquery on the full Bookings table.
-- SQL features: LEFT JOIN, anti-join pattern, column aliases, WHERE
--   filtering, ORDER BY.

DECLARE @SearchStart DATETIME2 = '2026-07-07 13:00:00';
DECLARE @SearchEnd   DATETIME2 = '2026-07-07 17:00:00';

SELECT
    s.space_code,
    s.space_name,
    s.space_type,
    s.building,
    s.floor,
    s.room_number,
    s.capacity,
    s.usage_policy
FROM
    Spaces s
    LEFT JOIN Bookings b
        ON  b.space_code = s.space_code
        AND b.status IN ('Approved', 'Checked In')
        AND b.requested_start_time < @SearchEnd
        AND b.requested_end_time   > @SearchStart
WHERE
    s.current_status = 'Available'
    AND b.booking_id IS NULL   -- no conflicting booking found
ORDER BY
    s.building,
    s.floor,
    s.room_number;

-- Expected result: All 6 available spaces EXCEPT CS-101 (Booking 4,
--   approved workshop 13:00–17:00 on 2026-07-07, overlaps the search
--   window). The result should show 5 spaces:
--   CS-202, CS-205, CS-B01, LIB-301, ADM-100.

GO

-- ============================================================================
-- Q2: Upcoming approved bookings for the next 7 days
-- ============================================================================
-- Business question:
--   "What is the schedule of approved bookings for the upcoming week,
--    ordered by date and room?"
-- Target user(s):
--   Facility Staff (daily planning, room preparation, check-in schedule).
-- Why useful:
--   Staff need a consolidated view of the coming week's bookings so they
--   can prepare rooms, check equipment, and assign check-in personnel.
-- SQL features: INNER JOIN (3 tables), date range filtering, ORDER BY
--   multiple columns, CAST for date-only display.

DECLARE @Today DATE = '2026-06-30';
DECLARE @WeekLater DATE = DATEADD(DAY, 7, @Today);

SELECT
    b.booking_id,
    CAST(b.requested_start_time AS DATE) AS booking_date,
    b.requested_start_time,
    b.requested_end_time,
    s.space_code,
    s.space_name,
    u.full_name      AS requester_name,
    u.role            AS requester_role,
    b.booking_type,
    b.expected_participants,
    b.purpose_of_use
FROM
    Bookings b
    INNER JOIN Spaces s ON b.space_code = s.space_code
    INNER JOIN Users  u ON b.requester_id = u.user_id
WHERE
    b.status = 'Approved'
    AND b.requested_start_time >= @Today
    AND b.requested_start_time <  @WeekLater
ORDER BY
    booking_date,
    s.space_code,
    b.requested_start_time;

-- Expected result: 2 bookings
--   2026-07-07 | CS-101 | Marie Curie | Workshop (booking 4)
--   2026-07-14 | CS-202 | Dennis Ritchie | Lecture (booking 11)

GO

-- ============================================================================
-- Q3: Space utilization summary — number of completed bookings per space
-- ============================================================================
-- Business question:
--   "Which spaces are used the most (and least) based on completed booking
--    history? What is the total hours used and average occupancy?"
-- Target user(s):
--   Facility Manager (resource planning, space allocation decisions).
-- Why useful:
--   The Facility Manager can identify overused and underused spaces to
--   inform decisions about re-allocation, renovation, or changes to
--   booking policies.
-- SQL features: LEFT JOIN with GROUP BY, aggregation (COUNT, SUM, AVG),
--   DATEDIFF, COALESCE, ORDER BY.

SELECT
    s.space_code,
    s.space_name,
    s.space_type,
    s.capacity,
    COUNT(b.booking_id)                               AS total_completed_bookings,
    COALESCE(SUM(DATEDIFF(MINUTE, b.actual_start_time, b.actual_end_time)), 0)
        / 60.0                                        AS total_usage_hours,
    COALESCE(AVG(b.expected_participants * 1.0), 0)   AS avg_expected_occupancy,
    COALESCE(AVG(b.expected_participants * 1.0) / NULLIF(s.capacity, 0) * 100, 0)
                                                        AS avg_occupancy_pct
FROM
    Spaces s
    LEFT JOIN Bookings b
        ON  b.space_code = s.space_code
        AND b.status = 'Completed'
GROUP BY
    s.space_code,
    s.space_name,
    s.space_type,
    s.capacity
ORDER BY
    total_completed_bookings DESC,
    total_usage_hours DESC;

-- Expected result: 9 rows (one per space)
--   CS-205 (2 completed: 3h + 3h15m = 6.25 hrs)
--   CS-101 (1 completed: 3h15m)
--   Remaining 7 spaces: 0 completed bookings, 0 usage hours.

GO

-- ============================================================================
-- Q4: Active maintenance issues with assigned staff
-- ============================================================================
-- Business question:
--   "What maintenance work is currently outstanding (Reported or In
--    Progress), and who is assigned to each issue?"
-- Target user(s):
--   Facility Staff, Facility Manager (workload tracking, prioritisation).
-- Why useful:
--   Provides a real-time dashboard of unresolved maintenance issues
--   so that the Facility Manager can assign unassigned tasks and track
--   progress. The query also shows whether a space is currently bookable
--   based on its status.
-- SQL features: INNER/LEFT JOIN, CASE expression, ORDER BY priority
--   (status severity), concatenation.

SELECT
    m.maintenance_id,
    m.space_code,
    s.space_name,
    s.current_status                             AS space_current_status,
    CASE
        WHEN s.current_status IN ('Under Maintenance', 'Temporarily Closed')
        THEN 'NOT BOOKABLE'
        ELSE 'Bookable'
    END                                          AS bookable_flag,
    m.problem_type,
    m.problem_description,
    m.status                                     AS maintenance_status,
    COALESCE(u_assigned.full_name, N'(Unassigned)') AS assigned_staff,
    u_reporter.full_name                         AS reported_by,
    m.start_time,
    m.result_note
FROM
    MaintenanceRecords m
    INNER JOIN Spaces s ON m.space_code = s.space_code
    INNER JOIN Users u_reporter ON m.reporter_id = u_reporter.user_id
    LEFT JOIN Users u_assigned ON m.assigned_staff_id = u_assigned.user_id
WHERE
    m.status IN ('Reported', 'In Progress')
ORDER BY
    CASE m.status
        WHEN 'Reported'    THEN 1
        WHEN 'In Progress' THEN 2
    END,
    m.maintenance_id;

-- Expected result: 2 rows
--   Maintenance 2 | CS-210 | Under Maintenance | NOT BOOKABLE
--     | Broken Projector | In Progress | John von Neumann
--   Maintenance 3 | CS-205 | Available | Bookable
--     | Other | Reported | (Unassigned) | Nikola Tesla

GO

-- ============================================================================
-- Q5: User booking history — view own bookings with details
-- ============================================================================
-- Business question:
--   "Show me (Grace Hopper) all my past and upcoming bookings, ordered
--    from most recent to furthest in the future."
-- Target user(s):
--   Any user (students, lecturers, etc.) checking their own booking history.
-- Why useful:
--   Users can track the status of their requests, see upcoming approved
--   bookings, and review past completed or rejected bookings — without
--   contacting the school office.
-- SQL features: INNER JOIN (2 tables), parameterised user filter,
--   CASE for human-readable status label, ORDER BY time.

DECLARE @TargetUserEmail NVARCHAR(255) = N'ghopper@university.edu';

SELECT
    b.booking_id,
    s.space_code,
    s.space_name,
    b.requested_start_time,
    b.requested_end_time,
    b.booking_type,
    b.purpose_of_use,
    b.status,
    CASE
        WHEN b.status = 'Pending'    THEN N'Awaiting staff review'
        WHEN b.status = 'Approved'   THEN N'Approved — ready for check-in'
        WHEN b.status = 'Rejected'   THEN N'Rejected: ' + ISNULL(b.rejection_reason, N'No reason provided')
        WHEN b.status = 'Cancelled'  THEN N'Cancelled'
        WHEN b.status = 'Checked In' THEN N'In progress'
        WHEN b.status = 'Completed'  THEN N'Completed'
        WHEN b.status = 'No-Show'    THEN N'Missed — not checked in'
        ELSE b.status
    END                                AS status_description,
    b.expected_participants
FROM
    Bookings b
    INNER JOIN Spaces s ON b.space_code = s.space_code
    INNER JOIN Users  u ON b.requester_id = u.user_id
WHERE
    u.email = @TargetUserEmail
ORDER BY
    b.requested_start_time DESC;

-- Expected result: 3 rows for Grace Hopper (user_id = 4)
--   Booking 6 | CS-101 | 2026-06-16 09:00 | Rejected   (most recent DESC)
--   Booking 2 | CS-205 | 2026-06-23 14:00 | Completed
--   Booking 5 | LIB-301 | 2026-07-08 14:00 | Pending    (earliest)

GO

-- ============================================================================
-- Q6: Spaces with no-show bookings requiring follow-up
-- ============================================================================
-- Business question:
--   "Which bookings resulted in no-shows, and what spaces were reserved
--    but went unused?"
-- Target user(s):
--   Facility Manager, Facility Staff (identifying wasted capacity,
--   enforcing no-show penalties, updating policies).
-- Why useful:
--   No-show bookings waste capacity that could have been used by others.
--   This query surfaces no-show records so staff can investigate,
--   update policies, or contact the requester.
-- SQL features: INNER JOIN (3 tables), DATEDIFF to measure wasted time,
--   ORDER BY wasted time descending.

SELECT
    b.booking_id,
    u.full_name           AS requester_name,
    u.email               AS requester_email,
    u.role                AS requester_role,
    s.space_code,
    s.space_name,
    s.capacity,
    b.requested_start_time,
    b.requested_end_time,
    DATEDIFF(MINUTE, b.requested_start_time, b.requested_end_time)
                            AS wasted_minutes,
    b.expected_participants,
    b.booking_type,
    b.purpose_of_use,
    COALESCE(u_approver.full_name, N'(No approver)') AS last_approved_by
FROM
    Bookings b
    INNER JOIN Spaces s ON b.space_code = s.space_code
    INNER JOIN Users  u ON b.requester_id = u.user_id
    LEFT JOIN Users u_approver ON b.approver_id = u_approver.user_id
WHERE
    b.status = 'No-Show'
ORDER BY
    wasted_minutes DESC;

-- Expected result: 1 row
--   Booking 8 | Marie Curie | CS-101 | 120 min wasted

GO

-- ============================================================================
-- Q7: Detect overlapping approved bookings for conflict checking
-- ============================================================================
-- Business question:
--   "Are there any two approved (or checked-in) bookings in the same space
--    with overlapping time ranges?"
-- Target user(s):
--   Facility Staff, Facility Manager, Application (trigger/validation
--   logic). This query can be used inside a trigger or application code
--   to enforce business rule BR3 (no overlapping approved bookings).
-- Why useful:
--   The schema-level CHECK constraints cannot enforce cross-row
--   temporal constraints. This self-JOIN query detects conflicts so
--   that staff can manually resolve them, or it can serve as the basis
--   for a trigger that rejects conflicting INSERT/UPDATE operations.
-- SQL features: Self-JOIN, anti-symmetric pair elimination (a < b),
--   overlap condition, filtered to active booking statuses.

SELECT DISTINCT
    b1.booking_id        AS conflict_booking_1,
    b2.booking_id        AS conflict_booking_2,
    b1.space_code,
    s.space_name,
    b1.status            AS status_1,
    b2.status            AS status_2,
    b1.requested_start_time AS start_1,
    b1.requested_end_time   AS end_1,
    b2.requested_start_time AS start_2,
    b2.requested_end_time   AS end_2
FROM
    Bookings b1
    INNER JOIN Bookings b2
        ON  b1.booking_id < b2.booking_id       -- each pair once
        AND b1.space_code = b2.space_code
        AND b1.requested_start_time < b2.requested_end_time
        AND b2.requested_start_time < b1.requested_end_time
    INNER JOIN Spaces s ON b1.space_code = s.space_code
WHERE
    b1.status IN ('Approved', 'Checked In')
    AND b2.status IN ('Approved', 'Checked In')
ORDER BY
    b1.space_code,
    b1.requested_start_time;

-- Expected result: 1 row
--   Booking 4 (Approved, 13:00-17:00) conflicts with Booking 9
--   (Pending, 14:00-16:00) — both in CS-101 on 2026-07-07.
--   NOTE: Booking 9 is Pending, so this query filters it OUT
--   (only Approved/Checked In are compared). The result is empty
--   because the sample data has no two *approved* bookings that
--   overlap. This is by design — the conflict-detection trigger
--   would use this query after status transitions. If Booking 9
--   were Approved, it would appear here.

-- To demonstrate a detectable conflict, the same query without the
-- status filter (or with Pending included) would show the pair:
--   SELECT ... WHERE b1.status IN ('Approved','Checked In','Pending')
--               AND b2.status IN ('Approved','Checked In','Pending')
-- Uncomment below to see the pending-vs-approved conflict:
/*
SELECT DISTINCT
    b1.booking_id        AS conflict_booking_1,
    b2.booking_id        AS conflict_booking_2,
    b1.space_code,
    b1.status            AS status_1,
    b2.status            AS status_2,
    b1.requested_start_time,
    b1.requested_end_time,
    b2.requested_start_time,
    b2.requested_end_time
FROM
    Bookings b1
    INNER JOIN Bookings b2
        ON  b1.booking_id < b2.booking_id
        AND b1.space_code = b2.space_code
        AND b1.requested_start_time < b2.requested_end_time
        AND b2.requested_start_time < b1.requested_end_time
WHERE
    b1.status IN ('Approved', 'Checked In', 'Pending')
    AND b2.status IN ('Approved', 'Checked In', 'Pending')
ORDER BY
    b1.space_code,
    b1.requested_start_time;
*/

GO

-- ============================================================================
-- QUERY SUMMARY
-- ============================================================================
-- +------+--------------------------------------------------+------------------+
-- | Query| Purpose                                          | SQL Features     |
-- +------+--------------------------------------------------+------------------+
-- | Q1   | Find available spaces for a time window          | LEFT JOIN, anti- |
-- |      |                                                  | join, variables  |
-- | Q2   | Upcoming week approved bookings                  | 3-table INNER    |
-- |      |                                                  | JOIN, date range |
-- | Q3   | Space utilization (completed bookings)           | LEFT JOIN, GROUP |
-- |      |                                                  | BY, aggregation  |
-- | Q4   | Active maintenance with assignee info            | LEFT JOIN, CASE, |
-- |      |                                                  | COALESCE         |
-- | Q5   | User booking history (self-service)              | JOIN, CASE for   |
-- |      |                                                  | readable status  |
-- | Q6   | No-show bookings for follow-up                   | JOIN, DATEDIFF,  |
-- |      |                                                  | LEFT JOIN        |
-- | Q7   | Overlap detection (conflict checker)             | Self-JOIN, anti- |
-- |      |                                                  | symmetric pair   |
-- +------+--------------------------------------------------+------------------+
-- ============================================================================

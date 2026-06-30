-- ============================================================================
-- Sample Data Script — Group G01
-- DBMS: Microsoft SQL Server
-- Description: Realistic test data covering normal operations and exceptional
--              cases for the Space Booking and Maintenance Management System.
-- ============================================================================

-- Prerequisite: Run 05-db-definition-G01.sql first to create the schema.

USE SpaceBookingDB;
GO

-- ============================================================================
-- 1. USERS
-- ============================================================================
SET IDENTITY_INSERT Users ON;
GO

INSERT INTO Users (user_id, full_name, email, phone_number, role, department, account_status)
VALUES
    -- Lecturers
    (1,  N'Dr. Alan Turing',     N'aturing@university.edu',  N'555-0101', N'Lecturer',                N'Computer Science',     N'Active'),
    (2,  N'Dr. Dennis Ritchie',  N'dritchie@university.edu', N'555-0102', N'Lecturer',                N'Computer Science',     N'Active'),
    (3,  N'Prof. Ada Lovelace',  N'alovelace@university.edu',N'555-0103', N'Lecturer',                N'Computer Science',     N'Active'),

    -- Students
    (4,  N'Grace Hopper',        N'ghopper@university.edu',  N'555-0201', N'Student',                 N'Computer Science',     N'Active'),
    (5,  N'Marie Curie',         N'mcurie@university.edu',   N'555-0202', N'Student',                 N'Computer Science',     N'Active'),
    (6,  N'Linus Torvalds',      N'ltorvalds@university.edu',N'555-0203', N'Student',                 N'Computer Science',     N'Active'),

    -- Teaching Assistant
    (7,  N'Nikola Tesla',        N'ntesla@university.edu',   N'555-0301', N'Teaching Assistant',      N'Computer Science',     N'Active'),

    -- Facility Staff
    (8,  N'Ada Lovelace',        N'alovelace.staff@university.edu', N'555-0401', N'Facility Staff',   N'School Office',        N'Active'),
    (9,  N'John von Neumann',    N'jneumann@university.edu', N'555-0402', N'Facility Staff',         N'School Office',        N'Active'),

    -- Department Administrator
    (10, N'Alan Kay',            N'akay@university.edu',     N'555-0501', N'Department Administrator',N'Computer Science',     N'Active'),

    -- Facility Manager
    (11, N'Charles Babbage',     N'cbabbage@university.edu', N'555-0601', N'Facility Manager',        N'School Office',        N'Active'),

    -- Suspended account for edge case testing
    (12, N'Suspended User',      N'suspended@university.edu',NULL,        N'Student',                 N'Computer Science',     N'Suspended');
GO

SET IDENTITY_INSERT Users OFF;
GO

-- ============================================================================
-- 2. SPACES
-- ============================================================================
INSERT INTO Spaces (space_code, space_name, space_type, building, floor, room_number, capacity, current_status, usage_policy)
VALUES
    -- Available spaces
    (N'CS-101', N'Turing Auditorium',      N'Auditorium',          N'CS Building',    1,  N'101', 200, N'Available',         N'Priority given to lectures and examinations. Max 200 persons.'),
    (N'CS-202', N'Hopper Classroom',       N'Classroom',            N'CS Building',    2,  N'202',  60, N'Available',         N'Standard classroom. Whiteboard and projector available.'),
    (N'CS-205', N'Lovelace Computer Lab',  N'Computer Laboratory',  N'CS Building',    2,  N'205',  30, N'Available',         N'30 workstations with pre-installed software. No food or drink.'),
    (N'CS-B01', N'Babbage Project Lab',    N'Project Laboratory',   N'CS Building',   -1,  N'B01',  20, N'Available',         N'Project workspace with soldering stations and 3D printers.'),
    (N'LIB-301',N'Study Nook',             N'Student Workspace',    N'Library',         3,  N'301',  10, N'Available',         N'Quiet study room. Group discussion permitted at low volume.'),
    (N'ADM-100',N'Executive Meeting Room', N'Meeting Room',         N'Admin Building',  1,  N'100',  15, N'Available',         N'Administrative meetings only. Video conferencing equipped.'),

    -- Exceptional-status spaces (cannot be booked)
    (N'CS-210', N'Shannon Classroom',      N'Classroom',            N'CS Building',    2,  N'210',  40, N'Under Maintenance',  N'Room closed — AC repair in progress.'),
    (N'CS-001', N'Legacy Classroom',       N'Classroom',            N'CS Building',    0,  N'001',  30, N'Retired',           N'This room is no longer in service.'),
    (N'CS-203', N'Tesla Computer Lab',     N'Computer Laboratory',  N'CS Building',    2,  N'203',  25, N'Temporarily Closed', N'Closed for ventilation system upgrade.');
GO

-- ============================================================================
-- 3. FACILITIES
-- ============================================================================
SET IDENTITY_INSERT Facilities ON;
GO

INSERT INTO Facilities (facility_id, space_code, facility_name, quantity, condition)
VALUES
    -- CS-101 Turing Auditorium
    (1,  N'CS-101', N'Projector',            2, N'Good'),
    (2,  N'CS-101', N'Microphone',           2, N'Good'),
    (3,  N'CS-101', N'Whiteboard',           2, N'Good'),
    (4,  N'CS-101', N'Computer',             1, N'Good'),
    (5,  N'CS-101', N'Livestreaming Equipment', 1, N'Fair'),
    (6,  N'CS-101', N'Air Conditioner',      2, N'Good'),

    -- CS-202 Hopper Classroom
    (7,  N'CS-202', N'Projector',            1, N'Good'),
    (8,  N'CS-202', N'Whiteboard',           1, N'Good'),
    (9,  N'CS-202', N'Computer',             1, N'Fair'),

    -- CS-205 Lovelace Computer Lab
    (10, N'CS-205', N'Computer',             30, N'Good'),
    (11, N'CS-205', N'Projector',            1, N'Good'),
    (12, N'CS-205', N'Whiteboard',           1, N'Good'),
    (13, N'CS-205', N'Air Conditioner',      1, N'Good'),

    -- CS-B01 Babbage Project Lab
    (14, N'CS-B01', N'3D Printer',           3, N'Good'),
    (15, N'CS-B01', N'Soldering Station',     5, N'Good'),
    (16, N'CS-B01', N'Computer',             4, N'Good'),

    -- LIB-301 Study Nook (no facilities — minimal setup)
    -- Intentionally empty to test spaces with zero facilities.

    -- ADM-100 Executive Meeting Room
    (17, N'ADM-100', N'Projector',           1, N'Good'),
    (18, N'ADM-100', N'Microphone',          1, N'Good'),
    (19, N'ADM-100', N'Video Conferencing System', 1, N'Good'),

    -- CS-210 Shannon Classroom (under maintenance — facilities may have issues)
    (20, N'CS-210', N'Projector',            1, N'Broken'),
    (21, N'CS-210', N'Whiteboard',           1, N'Good'),
    (22, N'CS-210', N'Air Conditioner',      1, N'Broken'),

    -- CS-203 Tesla Computer Lab (temporarily closed)
    (23, N'CS-203', N'Computer',             25, N'Fair'),
    (24, N'CS-203', N'Projector',            1, N'Good');

GO

SET IDENTITY_INSERT Facilities OFF;
GO

-- ============================================================================
-- 4. BOOKINGS
-- ============================================================================
SET IDENTITY_INSERT Bookings ON;
GO

-- Reference date: all dates are relative to 2026-06-30 (today per env).
-- Past: last week (2026-06-23), two weeks ago (2026-06-16)
-- Future: next week (2026-07-07), two weeks from now (2026-07-14)

INSERT INTO Bookings (booking_id, requester_id, space_code,
    requested_start_time, requested_end_time,
    purpose_of_use, expected_participants, booking_type, status,
    approver_id, decision_time, decision_note, rejection_reason,
    actual_start_time, check_in_person_id, initial_condition,
    actual_end_time, final_condition, usage_notes)
VALUES
    -- =======================================================================
    -- SCENARIO 1: Completed booking — Full lifecycle (Lecture in Auditorium)
    -- =======================================================================
    (1,
     1,        -- Dr. Alan Turing (Lecturer)
     N'CS-101',
     '2026-06-23 09:00:00', '2026-06-23 11:00:00',
     N'CS301 — Introduction to Database Systems lecture',
     180, N'Lecture', N'Completed',
     11,       -- Charles Babbage approved
     '2026-06-16 10:00:00',
     N'Approved — standard lecture slot.',
     NULL,     -- Not rejected
     '2026-06-23 08:55:00', 8,  -- Ada Lovelace (staff) checked in
     N'All equipment functional. Room clean.',
     '2026-06-23 11:10:00', 8,
     N'All equipment returned. Room tidy.',
     N'Lecture finished on time. Students left promptly.'),

    -- =======================================================================
    -- SCENARIO 2: Completed booking — Student activity
    -- =======================================================================
    (2,
     4,        -- Grace Hopper (Student)
     N'CS-205',
     '2026-06-23 14:00:00', '2026-06-23 17:00:00',
     N'Student coding workshop — hackathon preparation',
     25, N'Student Activity', N'Completed',
     8,        -- Ada Lovelace (staff) approved
     '2026-06-17 09:30:00',
     N'Approved. Ensure no food or drink in the lab.',
     NULL,
     '2026-06-23 14:05:00', 9,  -- John von Neumann checked in
     N'All 30 workstations operational.',
     '2026-06-23 17:15:00', 9,
     N'Workstations shut down properly. Minor cable mess — tidied.',
     N'Productive session. Students used 20 workstations.'),

    -- =======================================================================
    -- SCENARIO 3: Currently checked in — Seminar in progress (today)
    -- =======================================================================
    (3,
     7,        -- Nikola Tesla (TA)
     N'CS-205',
     '2026-06-30 10:00:00', '2026-06-30 12:00:00',
     N'TA-led seminar on advanced SQL query optimization',
     15, N'Seminar', N'Checked In',
     11,       -- Charles Babbage approved
     '2026-06-25 14:00:00',
     N'Approved — TA-led seminar, low headcount.',
     NULL,
     '2026-06-30 10:02:00', 8,  -- Ada Lovelace checked in
     N'Lab is clean. 15 computers powered on and ready.',
     NULL, NULL, NULL,  -- Not completed yet
     NULL),

    -- =======================================================================
    -- SCENARIO 4: Approved future booking — Workshop next week
    -- =======================================================================
    (4,
     5,        -- Marie Curie (Student)
     N'CS-101',
     '2026-07-07 13:00:00', '2026-07-07 17:00:00',
     N'Introduction to Quantum Computing — student workshop',
     80, N'Workshop', N'Approved',
     8,        -- Ada Lovelace approved
     '2026-06-28 11:00:00',
     N'Approved. Expected 80 participants fits within capacity (200).',
     NULL,
     NULL, NULL, NULL, NULL, NULL, NULL),

    -- =======================================================================
    -- SCENARIO 5: Pending future booking — awaiting staff approval
    -- =======================================================================
    (5,
     4,        -- Grace Hopper (Student)
     N'LIB-301',
     '2026-07-08 14:00:00', '2026-07-08 16:00:00',
     N'Group study session for database project',
     6, N'Student Activity', N'Pending',
     NULL, NULL, NULL, NULL,
     NULL, NULL, NULL, NULL, NULL, NULL),

    -- =======================================================================
    -- SCENARIO 6: Rejected booking — with reason
    -- =======================================================================
    (6,
     4,        -- Grace Hopper (Student)
     N'CS-101',
     '2026-06-16 09:00:00', '2026-06-16 12:00:00',
     N'Student club meeting — Gaming Society event',
     150, N'Student Activity', N'Rejected',
     11,       -- Charles Babbage rejected
     '2026-06-14 08:00:00',
     N'Rejected — request does not align with academic use policy.',
     N'Space usage policy restricts student society events in auditoriums to after-hours. Requested time conflicts with scheduled examination period. Please rebook for after 18:00 or select a different space.',
     NULL, NULL, NULL, NULL, NULL, NULL),

    -- =======================================================================
    -- SCENARIO 7: Cancelled booking — was approved then cancelled
    -- =======================================================================
    (7,
     10,       -- Alan Kay (Dept Admin)
     N'ADM-100',
     '2026-06-24 10:00:00', '2026-06-24 12:00:00',
     N'Department curriculum committee meeting',
     12, N'Meeting', N'Cancelled',
     8,        -- Ada Lovelace approved
     '2026-06-20 09:00:00',
     N'Approved — administrative meeting.',
     NULL,
     NULL, NULL, NULL, NULL, NULL, NULL),

    -- =======================================================================
    -- SCENARIO 8: No-show booking — was approved but never checked in
    -- =======================================================================
    (8,
     5,        -- Marie Curie (Student)
     N'CS-101',
     '2026-06-16 14:00:00', '2026-06-16 16:00:00',
     N'Practice examination — mock test for CS301',
     50, N'Examination', N'No-Show',
     9,        -- John von Neumann approved
     '2026-06-13 10:00:00',
     N'Approved — examination booking.',
     NULL,
     NULL, NULL, NULL, NULL, NULL, NULL),

    -- =======================================================================
    -- SCENARIO 9: Pending that overlaps an approved booking (conflict test)
    -- This booking for CS-101 on 2026-07-07 overlaps with booking 4
    -- (13:00-17:00). Tests conflict-detection logic (E1 in app/trigger).
    -- =======================================================================
    (9,
     6,        -- Linus Torvalds (Student)
     N'CS-101',
     '2026-07-07 14:00:00', '2026-07-07 16:00:00',
     N'Linux Users Group meeting',
     30, N'Student Activity', N'Pending',
     NULL, NULL, NULL, NULL,
     NULL, NULL, NULL, NULL, NULL, NULL),

    -- =======================================================================
    -- SCENARIO 10: Pending for a space under maintenance (blocked by E2)
    -- CS-210 is "Under Maintenance" — should be rejected by business logic.
    -- =======================================================================
    (10,
     5,        -- Marie Curie (Student)
     N'CS-210',
     '2026-07-10 09:00:00', '2026-07-10 11:00:00',
     N'Small group tutoring session',
     20, N'Lecture', N'Pending',
     NULL, NULL, NULL, NULL,
     NULL, NULL, NULL, NULL, NULL, NULL),

    -- =======================================================================
    -- SCENARIO 11: Lecturer future lecture (approved)
    -- =======================================================================
    (11,
     2,        -- Dr. Dennis Ritchie (Lecturer)
     N'CS-202',
     '2026-07-14 08:00:00', '2026-07-14 10:00:00',
     N'CS450 — Operating Systems lecture',
     55, N'Lecture', N'Approved',
     11,       -- Charles Babbage approved
     '2026-06-29 09:00:00',
     N'Approved — recurring lecture slot.',
     NULL,
     NULL, NULL, NULL, NULL, NULL, NULL);

GO

SET IDENTITY_INSERT Bookings OFF;
GO

-- ============================================================================
-- 5. MAINTENANCE RECORDS
-- ============================================================================
SET IDENTITY_INSERT MaintenanceRecords ON;
GO

INSERT INTO MaintenanceRecords (maintenance_id, space_code, reporter_id,
    assigned_staff_id, problem_description, problem_type,
    start_time, completion_time, status, result_note)
VALUES
    -- =======================================================================
    -- SCENARIO M1: Completed maintenance — AC repair
    -- =======================================================================
    (1,
     N'CS-210',     -- Shannon Classroom
     4,             -- Grace Hopper reported (student)
     8,             -- Ada Lovelace assigned (staff)
     N'Air conditioning is not cooling the room. Temperature reached 31°C during yesterday''s lecture.',
     N'Air-Conditioning Failure',
     '2026-06-20 09:00:00',
     '2026-06-22 16:00:00',
     N'Completed',
     N'AC compressor replaced. System now cooling to 22°C. Room returned to service.'),

    -- =======================================================================
    -- SCENARIO M2: Active maintenance (In Progress) — currently blocking
    -- This keeps CS-210 in a non-bookable state.
    -- =======================================================================
    (2,
     N'CS-210',     -- Shannon Classroom (second issue)
     1,             -- Dr. Alan Turing reported
     9,             -- John von Neumann assigned
     N'Projector lamp flickers intermittently. Image quality degraded.',
     N'Broken Projector',
     '2026-06-28 14:00:00',
     NULL,          -- Not yet completed
     N'In Progress',
     N'Replacement lamp ordered. Expected delivery in 3 days.'),

    -- =======================================================================
    -- SCENARIO M3: Reported — not yet assigned
    -- =======================================================================
    (3,
     N'CS-205',     -- Lovelace Computer Lab
     7,             -- Nikola Tesla (TA) reported
     NULL,          -- Not yet assigned
     N'Workstation #12 bluescreens on boot. Keyboard on #7 has several non-functional keys.',
     N'Other',
     NULL, NULL,    -- Not started yet
     N'Reported',
     NULL),

    -- =======================================================================
    -- SCENARIO M4: Completed maintenance — network fix
    -- =======================================================================
    (4,
     N'CS-205',     -- Lovelace Computer Lab
     4,             -- Grace Hopper reported
     9,             -- John von Neumann assigned
     N'Network connectivity intermittent in the lab. Students cannot access remote servers.',
     N'Network Problem',
     '2026-06-18 11:00:00',
     '2026-06-18 15:30:00',
     N'Completed',
     N'Replaced faulty switch in rack #2. All 30 workstations reconnected and tested.'),

    -- =======================================================================
    -- SCENARIO M5: Cancelled maintenance
    -- =======================================================================
    (5,
     N'CS-202',     -- Hopper Classroom
     10,            -- Alan Kay (Dept Admin) reported
     8,             -- Ada Lovelace assigned
     N'One of the whiteboard markers was dry. Requesting replacement.',
     N'Other',
     '2026-06-19 08:00:00',
     '2026-06-19 08:30:00',
     N'Cancelled',
     N'Issue resolved without maintenance — cleaning staff replaced markers.'),

    -- =======================================================================
    -- SCENARIO M6: Maintenance for a retired space (historical record)
    -- =======================================================================
    (6,
     N'CS-001',     -- Legacy Classroom (Retired)
     8,             -- Ada Lovelace reported (staff)
     8,             -- Self-assigned
     N'Final inspection before room decommissioning — all furniture to be removed.',
     N'Other',
     '2026-05-30 09:00:00',
     '2026-05-30 17:00:00',
     N'Completed',
     N'All furniture removed. Room inspected and marked as retired in the system.'),

    -- =======================================================================
    -- SCENARIO M7: Cleaning issue — completed (past)
    -- =======================================================================
    (7,
     N'LIB-301',    -- Study Nook
     4,             -- Grace Hopper reported
     9,             -- John von Neumann assigned
     N'Spilled drink on study desks. Sticky residue on desks #3 and #4.',
     N'Cleaning Issue',
     '2026-06-21 16:00:00',
     '2026-06-21 17:30:00',
     N'Completed',
     N'Desks cleaned and sanitized. Area ready for use.');

GO

SET IDENTITY_INSERT MaintenanceRecords OFF;
GO

-- ============================================================================
-- 6. DATA SUMMARY — Coverage Checklist
-- ============================================================================
-- +----------------------+----------------------------------------------+
-- | Category             | Scenarios Covered                           |
-- +----------------------+----------------------------------------------+
-- | User roles           | Lecturer, Student, TA, Facility Staff,       |
-- |                      | Dept Admin, Facility Manager, Suspended      |
-- +----------------------+----------------------------------------------+
-- | Space types          | Auditorium, Classroom, Computer Lab,         |
-- |                      | Project Lab, Student Workspace, Meeting Room |
-- +----------------------+----------------------------------------------+
-- | Space statuses       | Available, Under Maintenance, Temporarily    |
-- |                      | Closed, Retired                              |
-- +----------------------+----------------------------------------------+
-- | Facility coverage    | Spaces with many facilities; LIB-301 has     |
-- |                      | none (edge: zero-facility space)             |
-- +----------------------+----------------------------------------------+
-- | Booking statuses     | Pending, Approved, Rejected, Cancelled,      |
-- |                      | Checked In, Completed, No-Show               |
-- +----------------------+----------------------------------------------+
-- | Booking types        | Lecture, Examination, Seminar, Workshop,     |
-- |                      | Meeting, Student Activity                    |
-- +----------------------+----------------------------------------------+
-- | Booking lifecycle    | Full flow (Pending→Approved→CheckedIn→       |
-- | lifecycle            | Completed); rejected; cancelled; no-show     |
-- +----------------------+----------------------------------------------+
-- | Conflict tests       | Booking 9 overlaps Booking 4 (same space,    |
-- |                      | same day, overlapping time)                  |
-- +----------------------+----------------------------------------------+
-- | Maintenance block    | Booking 10 requests CS-210 which is          |
-- | test                 | "Under Maintenance" with active work         |
-- +----------------------+----------------------------------------------+
-- | Maintenance statuses | Reported, In Progress, Completed, Cancelled  |
-- +----------------------+----------------------------------------------+
-- | Maintenance types    | AC Failure, Broken Projector, Network        |
-- |                      | Problem, Cleaning Issue, Other               |
-- +----------------------+----------------------------------------------+
-- | Suspended user       | User 12 (Suspended User) can still exist     |
-- |                      | but should not be able to book (app logic)   |
-- +----------------------+----------------------------------------------+
-- ============================================================================

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
    (1,  N'Dr. Alan Turing',     N'aturing@university.edu',  N'555-0101', N'Lecturer',                N'Computer Science', N'Active'),
    (2,  N'Grace Hopper',        N'ghopper@university.edu',  N'555-0201', N'Student',                 N'Computer Science', N'Active'),
    (3,  N'Ada Lovelace',        N'alovelace@university.edu',N'555-0401', N'Facility Staff',          N'School Office',    N'Active'),
    (4,  N'Charles Babbage',     N'cbabbage@university.edu', N'555-0601', N'Facility Manager',        N'School Office',    N'Active'),
    (5,  N'Marie Curie',         N'mcurie@university.edu',   N'555-0202', N'Student',                 N'Computer Science', N'Active'),
    (6,  N'Nikola Tesla',        N'ntesla@university.edu',   N'555-0301', N'Teaching Assistant',      N'Computer Science', N'Active'),
    (7,  N'Alan Kay',            N'akay@university.edu',     N'555-0501', N'Department Administrator', N'Computer Science', N'Active'),
    (8,  N'Dr. Dennis Ritchie',  N'dritchie@university.edu', N'555-0102', N'Lecturer',                N'Computer Science', N'Active'),
    (9,  N'John von Neumann',    N'jneumann@university.edu', N'555-0402', N'Facility Staff',          N'School Office',    N'Active'),
    (10, N'Suspended User',      N'suspended@university.edu',NULL,        N'Student',                 N'Computer Science', N'Suspended'),
    (11, N'Prof. Ada Lovelace',  N'alovelace.prof@university.edu',NULL,   N'Lecturer',                N'Computer Science', N'Active');
GO

SET IDENTITY_INSERT Users OFF;
GO

-- ============================================================================
-- 2. SPACES
-- ============================================================================
INSERT INTO Spaces (space_code, space_name, space_type, building, floor, room_number, capacity, current_status, usage_policy)
VALUES
    -- Available spaces (ready for booking)
    (N'CS-101', N'Turing Auditorium',     N'Auditorium',          N'CS Building',  1,  N'101', 200, N'Available',         N'Priority to lectures and exams. Capacity 200.'),
    (N'CS-202', N'Hopper Classroom',      N'Classroom',            N'CS Building',  2,  N'202',  60, N'Available',         N'Standard classroom. Whiteboard and projector.'),
    (N'CS-205', N'Lovelace Computer Lab', N'Computer Laboratory',  N'CS Building',  2,  N'205',  30, N'Available',         N'30 workstations. No food or drink.'),
    (N'CS-B01', N'Babbage Project Lab',   N'Project Laboratory',   N'CS Building', -1,  N'B01',  20, N'Available',         N'Soldering stations and 3D printers.'),
    (N'LIB-301',N'Study Nook',            N'Student Workspace',    N'Library',       3,  N'301',  10, N'Available',         N'Quiet study room. Low-volume discussion OK.'),
    (N'ADM-100',N'Meeting Room Alpha',    N'Meeting Room',         N'Admin Building',1,  N'100',  15, N'Available',         N'Admin meetings only. Video conferencing.'),

    -- Spaces that will become Under Maintenance via trigger (starts Available)
    (N'CS-210', N'Shannon Classroom',     N'Classroom',            N'CS Building',  2,  N'210',  40, N'Available',         N''),

    -- Non-bookable statuses (set directly, not changed by trigger)
    (N'CS-001', N'Legacy Classroom',      N'Classroom',            N'CS Building',  0,  N'001',  30, N'Retired',           N'Decommissioned.'),
    (N'CS-203', N'Tesla Computer Lab',    N'Computer Laboratory',  N'CS Building',  2,  N'203',  25, N'Temporarily Closed', N'Ventilation upgrade in progress.');
GO

-- ============================================================================
-- 3. FACILITIES
-- ============================================================================
SET IDENTITY_INSERT Facilities ON;
GO

INSERT INTO Facilities (facility_id, space_code, facility_name, condition)
VALUES
    -- CS-101 Turing Auditorium
    (1,  N'CS-101', N'Projector',            N'Good'),
    (2,  N'CS-101', N'Microphone',           N'Good'),
    (3,  N'CS-101', N'Whiteboard',           N'Good'),
    (4,  N'CS-101', N'Computer',             N'Good'),
    (5,  N'CS-101', N'Livestreaming Equipment', N'Fair'),
    (6,  N'CS-101', N'Air Conditioner',      N'Good'),

    -- CS-202 Hopper Classroom
    (7,  N'CS-202', N'Projector',            N'Good'),
    (8,  N'CS-202', N'Whiteboard',           N'Good'),
    (9,  N'CS-202', N'Computer',             N'Fair'),

    -- CS-205 Lovelace Computer Lab
    (10, N'CS-205', N'Computer',             N'Good'),
    (11, N'CS-205', N'Projector',            N'Good'),
    (12, N'CS-205', N'Whiteboard',           N'Good'),
    (13, N'CS-205', N'Air Conditioner',      N'Good'),

    -- CS-B01 Babbage Project Lab
    (14, N'CS-B01', N'3D Printer',           N'Good'),
    (15, N'CS-B01', N'Soldering Station',     N'Good'),
    (16, N'CS-B01', N'Computer',             N'Good'),

    -- LIB-301 Study Nook — intentionally no facilities (edge case)

    -- ADM-100 Meeting Room Alpha
    (17, N'ADM-100', N'Projector',           N'Good'),
    (18, N'ADM-100', N'Microphone',          N'Good'),
    (19, N'ADM-100', N'Video Conferencing System', N'Good'),

    -- CS-210 Shannon Classroom
    (20, N'CS-210', N'Projector',            N'Broken'),
    (21, N'CS-210', N'Whiteboard',           N'Good'),
    (22, N'CS-210', N'Air Conditioner',      N'Broken'),

    -- CS-203 Tesla Computer Lab (temporarily closed)
    (23, N'CS-203', N'Computer',             N'Fair'),
    (24, N'CS-203', N'Projector',            N'Good');
GO

SET IDENTITY_INSERT Facilities OFF;
GO

-- ============================================================================
-- 4. MAINTENANCE RECORDS
-- ============================================================================
-- Note: The trigger trg_Maintenance_SyncSpaceStatus fires on INSERT/UPDATE.
-- Inserting a maintenance with status 'Reported' or 'In Progress' will
-- automatically set the Space's current_status to 'Under Maintenance'.
-- Inserting a maintenance with status 'Completed' or 'Cancelled' will
-- revert the Space to 'Available' if no other active maintenance exists.
-- ============================================================================
SET IDENTITY_INSERT MaintenanceRecords ON;
GO

INSERT INTO MaintenanceRecords (maintenance_id, space_code, reporter_id,
    assigned_staff_id, problem_description, problem_type,
    start_time, completion_time, status, result_note)
VALUES
    -- M1: Active maintenance — will trigger CS-210 → 'Under Maintenance'
    (1,
     N'CS-210',
     1,     -- Dr. Alan Turing reported
     9,     -- John von Neumann assigned
     N'Projector lamp flickers and image quality is degraded. AC also blows warm air.',
     N'Broken Projector',
     '2026-06-28 14:00:00',
     NULL,
     N'In Progress',
     N'Replacement lamp ordered. AC technician scheduled.'),

    -- M2: Completed maintenance for CS-210 (past, does not affect current status
    --     because M1 is still active)
    (2,
     N'CS-210',
     5,     -- Marie Curie reported
     3,     -- Ada Lovelace assigned
     N'Air conditioning not cooling. Room reached 30°C during exam.',
     N'Air-Conditioning Failure',
     '2026-06-20 09:00:00',
     '2026-06-22 16:00:00',
     N'Completed',
     N'AC compressor replaced. System cooling normally.'),

    -- M3: Active maintenance — will trigger CS-B01 → 'Under Maintenance'
    (3,
     N'CS-B01',
     6,     -- Nikola Tesla reported
     NULL,  -- Not yet assigned
     N'3D printer #2 extruder clogged. Soldering station #4 iron tip broken.',
     N'Other',
     NULL,
     NULL,
     N'Reported',
     NULL),

    -- M4: Completed maintenance for CS-205 (past, no effect on current status)
    (4,
     N'CS-205',
     2,     -- Grace Hopper reported
     9,     -- John von Neumann assigned
     N'Intermittent network connectivity. Students cannot reach remote servers.',
     N'Network Problem',
     '2026-06-18 11:00:00',
     '2026-06-18 15:30:00',
     N'Completed',
     N'Replaced faulty switch. All 30 workstations reconnected.'),

    -- M5: Completed maintenance for LIB-301 (past, no effect)
    (5,
     N'LIB-301',
     2,     -- Grace Hopper reported
     9,     -- John von Neumann assigned
     N'Spilled drink on desks #3 and #4. Sticky residue.',
     N'Cleaning Issue',
     '2026-06-21 16:00:00',
     '2026-06-21 17:30:00',
     N'Completed',
     N'Desks cleaned and sanitized.'),

    -- M6: Completed maintenance for retired space CS-001 (historical)
    (6,
     N'CS-001',
     3,     -- Ada Lovelace reported
     3,     -- Self-assigned
     N'Final decommissioning — remove all furniture and equipment.',
     N'Other',
     '2026-05-30 09:00:00',
     '2026-05-30 17:00:00',
     N'Completed',
     N'All furniture removed. Space marked as Retired.'),

    -- M7: Cancelled maintenance for CS-202
    (7,
     N'CS-202',
     7,     -- Alan Kay reported
     3,     -- Ada Lovelace assigned
     N'Whiteboard marker dry — requesting replacement.',
     N'Other',
     '2026-06-19 08:00:00',
     '2026-06-19 08:30:00',
     N'Cancelled',
     N'Cleaning staff replaced markers. No maintenance needed.');
GO

SET IDENTITY_INSERT MaintenanceRecords OFF;
GO

-- ============================================================================
-- 5. BOOKINGS
-- ============================================================================
-- Note: The trigger trg_Booking_PreventOverlap fires on INSERT/UPDATE.
-- It prevents setting a booking to 'Approved' or 'Checked In' if another
-- approved/checked-in booking exists for the same space with overlapping
-- time.  All Pending/Rejected/Cancelled bookings are allowed regardless
-- of overlap.
-- ============================================================================
SET IDENTITY_INSERT Bookings ON;
GO

INSERT INTO Bookings (booking_id, requester_id, space_code,
    requested_start_time, requested_end_time,
    purpose_of_use, expected_participants, booking_type, status,
    approver_id, decision_time, decision_note, rejection_reason,
    actual_start_time, check_in_person_id, initial_condition,
    actual_end_time, final_condition, usage_notes)
VALUES
    -- ===================================================================
    -- B1: Completed — full lifecycle (Pending → Approved → Checked In → Completed)
    -- Lecturer lecture in auditorium.
    -- ===================================================================
    (1,
     1,        -- Dr. Alan Turing
     N'CS-101',
     '2026-06-23 09:00:00', '2026-06-23 11:00:00',
     N'CS301 — Introduction to Database Systems lecture',
     180, N'Lecture', N'Completed',
     4,        -- Charles Babbage approved
     '2026-06-16 10:00:00',
     N'Approved — standard lecture slot.',
     NULL,
     '2026-06-23 08:55:00', 3,  -- Ada Lovelace checked in
     N'All equipment functional. Room clean and ready.',
     '2026-06-23 11:10:00', 
     N'Projector off. Whiteboard cleaned. Room tidy.',
     N'180 students attended. Finished on time.'),

    -- ===================================================================
    -- B2: Completed — student activity in computer lab
    -- ===================================================================
    (2,
     2,        -- Grace Hopper
     N'CS-205',
     '2026-06-23 14:00:00', '2026-06-23 17:00:00',
     N'Student coding workshop — hackathon preparation',
     25, N'Student Activity', N'Completed',
     3,        -- Ada Lovelace approved
     '2026-06-17 09:30:00',
     N'Approved. No food or drink in the lab.',
     NULL,
     '2026-06-23 14:05:00', 9,  -- John von Neumann checked in
     N'All 30 workstations operational. Lab clean.',
     '2026-06-23 17:15:00', 
     N'Workstations shut down. Cables tidied.',
     N'Productive session. 20 workstations used.'),

    -- ===================================================================
    -- B3: Checked In — seminar in progress (today)
    -- ===================================================================
    (3,
     6,        -- Nikola Tesla (TA)
     N'CS-205',
     '2026-07-01 10:00:00', '2026-07-01 12:00:00',
     N'TA-led seminar on advanced SQL query optimization',
     15, N'Seminar', N'Checked In',
     4,        -- Charles Babbage approved
     '2026-06-25 14:00:00',
     N'Approved — TA seminar, low headcount.',
     NULL,
     '2026-07-01 10:02:00', 3,  -- Ada Lovelace checked in
     N'Lab clean. 15 computers ready.',
     NULL, NULL,  -- Not yet completed
     NULL),

    -- ===================================================================
    -- B4: Approved — future workshop
    -- ===================================================================
    (4,
     5,        -- Marie Curie
     N'CS-101',
     '2026-07-07 13:00:00', '2026-07-07 17:00:00',
     N'Introduction to Quantum Computing — student workshop',
     80, N'Workshop', N'Approved',
     3,        -- Ada Lovelace approved
     '2026-06-28 11:00:00',
     N'Approved. 80 participants within capacity of 200.',
     NULL,
     NULL, NULL, NULL, NULL, NULL, NULL),

    -- ===================================================================
    -- B5: Pending — awaiting staff review
    -- ===================================================================
    (5,
     2,        -- Grace Hopper
     N'LIB-301',
     '2026-07-08 14:00:00', '2026-07-08 16:00:00',
     N'Group study session for database project',
     6, N'Student Activity', N'Pending',
     NULL, NULL, NULL, NULL,
     NULL, NULL, NULL, NULL, NULL, NULL),

    -- ===================================================================
    -- B6: Rejected — with full reason
    -- ===================================================================
    (6,
     2,        -- Grace Hopper
     N'CS-101',
     '2026-06-16 09:00:00', '2026-06-16 12:00:00',
     N'Gaming Society club meeting',
     150, N'Student Activity', N'Rejected',
     4,        -- Charles Babbage rejected
     '2026-06-14 08:00:00',
     N'Rejected — does not align with academic use policy.',
     N'Student society events in auditoriums are restricted to after-hours (after 18:00). Requested time conflicts with scheduled examination period. Please rebook after 18:00 or select a different space.',
     NULL, NULL, NULL, NULL, NULL, NULL),

    -- ===================================================================
    -- B7: Cancelled — was approved then cancelled
    -- ===================================================================
    (7,
     7,        -- Alan Kay (Dept Admin)
     N'ADM-100',
     '2026-06-24 10:00:00', '2026-06-24 12:00:00',
     N'Department curriculum committee meeting',
     12, N'Meeting', N'Cancelled',
     3,        -- Ada Lovelace approved
     '2026-06-20 09:00:00',
     N'Approved — administrative meeting.',
     NULL,
     NULL, NULL, NULL, NULL, NULL, NULL),

    -- ===================================================================
    -- B8: No-Show — was approved but never checked in
    -- ===================================================================
    (8,
     5,        -- Marie Curie
     N'CS-101',
     '2026-06-16 14:00:00', '2026-06-16 16:00:00',
     N'Practice examination — mock test for CS301',
     50, N'Examination', N'No-Show',
     9,        -- John von Neumann approved
     '2026-06-13 10:00:00',
     N'Approved — examination booking.',
     NULL,
     NULL, NULL, NULL, NULL, NULL, NULL),

    -- ===================================================================
    -- B9: Pending overlap test — same space, same day, overlapping time
    --     as B4 (Approved 13:00–17:00). This should be rejected by
    --     trg_Booking_PreventOverlap if anyone tries to approve it.
    -- ===================================================================
    (9,
     8,        -- Dr. Dennis Ritchie
     N'CS-101',
     '2026-07-07 14:00:00', '2026-07-07 16:00:00',
     N'C guest lecture — memory management in C',
     40, N'Lecture', N'Pending',
     NULL, NULL, NULL, NULL,
     NULL, NULL, NULL, NULL, NULL, NULL),

    -- ===================================================================
    -- B10: Pending maintenance block test — CS-210 is Under Maintenance
    --      (via trigger from M1). Booking should be rejected at approval
    --      time by business logic or app-level check.
    -- ===================================================================
    (10,
     8,        -- Dr. Dennis Ritchie
     N'CS-210',
     '2026-07-10 09:00:00', '2026-07-10 11:00:00',
     N'Tutoring session for operating systems',
     20, N'Lecture', N'Pending',
     NULL, NULL, NULL, NULL,
     NULL, NULL, NULL, NULL, NULL, NULL),

    -- ===================================================================
    -- B11: Approved — future lecture
    -- ===================================================================
    (11,
     8,        -- Dr. Dennis Ritchie
     N'CS-202',
     '2026-07-14 08:00:00', '2026-07-14 10:00:00',
     N'CS450 — Operating Systems lecture',
     55, N'Lecture', N'Approved',
     4,        -- Charles Babbage approved
     '2026-06-29 09:00:00',
     N'Approved — confirmed recurring lecture.',
     NULL,
     NULL, NULL, NULL, NULL, NULL, NULL);

GO

SET IDENTITY_INSERT Bookings OFF;
GO

-- ============================================================================
-- 6. DATA COVERAGE SUMMARY
-- ============================================================================
--
-- Users:       11 (Lecturer ×3, Student ×3, TA ×1, Facility Staff ×2,
--                   Dept Admin ×1, Facility Manager ×1, Suspended Student ×1)
-- Spaces:       9 (Auditorium, Classroom ×2, Computer Lab ×2, Project Lab,
--                   Student Workspace, Meeting Room; statuses: Available ×6,
--                   Under Maintenance ×1 [via trigger], Retired ×1,
--                   Temporarily Closed ×1)
-- Facilities:  24 (across 8 spaces; LIB-301 has zero — edge case)
-- Bookings:    11 (Completed ×2, Checked In ×1, Approved ×2, Pending ×3,
--                   Rejected ×1, Cancelled ×1, No-Show ×1)
-- Maintenance:  7 (Reported ×1 [active], In Progress ×1 [active],
--                   Completed ×4, Cancelled ×1)
--
-- Trigger test scenarios:
--   - trg_Maintenance_SyncSpaceStatus: M1 (In Progress) → CS-210 becomes
--     Under Maintenance. M3 (Reported) → CS-B01 becomes Under Maintenance.
--   - trg_Booking_PreventOverlap: B9 (Pending) overlaps B4 (Approved) on
--     CS-101 at the same day. Approving B9 would trigger a conflict.
--
-- Business rule test scenarios:
--   - BR3 (conflict):  B9 overlaps B4 on CS-101
--   - BR2/BR7 (block): B10 targets CS-210 which is Under Maintenance
--   - BR5 (approval):  B6 (Rejected) has non-null rejection_reason
--   - BR6 (check-in):  B1 (Completed) has full check-in/check-out trail
--   - BR10 (susp.):    User 10 (Suspended) has no bookings
-- ============================================================================

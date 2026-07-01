-- ============================================================================
-- Database Definition Script — Group G01
-- DBMS: Microsoft SQL Server
-- Description: Space Booking and Maintenance Management System
-- ============================================================================

-- ============================================================================
-- 1. DATABASE CREATION
-- ============================================================================
-- Uncomment and modify the file path to create the database.
--
CREATE DATABASE SpaceBookingDB;
GO
USE SpaceBookingDB;
GO

-- ============================================================================
-- 2. TABLES
-- ============================================================================

-- --------------------------------------------------------------------------
-- 2.1 Users
-- --------------------------------------------------------------------------
CREATE TABLE Users (
    user_id         INT             NOT NULL IDENTITY(1,1),
    full_name       NVARCHAR(100)   NOT NULL,
    email           NVARCHAR(255)   NOT NULL,
    phone_number    NVARCHAR(20)    NULL,
    role            NVARCHAR(30)    NOT NULL,
    department      NVARCHAR(100)   NOT NULL,
    account_status  NVARCHAR(15)    NOT NULL,

    CONSTRAINT PK_Users PRIMARY KEY (user_id),
    CONSTRAINT UQ_Users_Email UNIQUE (email),
    CONSTRAINT CK_Users_Role CHECK (role IN (
        'Student',
        'Lecturer',
        'Teaching Assistant',
        'Facility Staff',
        'Department Administrator',
        'Facility Manager'
    )),
    CONSTRAINT CK_Users_AccountStatus CHECK (account_status IN (
        'Active',
        'Suspended',
        'Inactive'
    ))
);

-- --------------------------------------------------------------------------
-- 2.2 Spaces
-- --------------------------------------------------------------------------
CREATE TABLE Spaces (
    space_code      NVARCHAR(20)    NOT NULL,
    space_name      NVARCHAR(100)   NOT NULL,
    space_type      NVARCHAR(30)    NOT NULL,
    building        NVARCHAR(100)   NOT NULL,
    floor           INT             NOT NULL,
    room_number     NVARCHAR(20)    NOT NULL,
    capacity        INT             NOT NULL,
    current_status  NVARCHAR(20)    NOT NULL,
    usage_policy    NVARCHAR(MAX)   NULL,

    CONSTRAINT PK_Spaces PRIMARY KEY (space_code),
    CONSTRAINT UQ_Spaces_Location UNIQUE (building, floor, room_number),
    CONSTRAINT CK_Spaces_SpaceType CHECK (space_type IN (
        'Auditorium',
        'Classroom',
        'Computer Laboratory',
        'Project Laboratory',
        'Meeting Room',
        'Student Workspace'
    )),
    CONSTRAINT CK_Spaces_CurrentStatus CHECK (current_status IN (
        'Available',
        'In Use',
        'Under Maintenance',
        'Temporarily Closed',
        'Retired'
    )),
    CONSTRAINT CK_Spaces_Capacity CHECK (capacity > 0)
);

-- --------------------------------------------------------------------------
-- 2.3 Facilities
-- --------------------------------------------------------------------------
CREATE TABLE Facilities (
    facility_id     INT             NOT NULL IDENTITY(1,1),
    space_code      NVARCHAR(20)    NOT NULL,
    facility_name   NVARCHAR(100)   NOT NULL,
    condition       NVARCHAR(100)   NULL,

    CONSTRAINT PK_Facilities PRIMARY KEY (facility_id),

    CONSTRAINT FK_Facilities_SpaceCode
        FOREIGN KEY (space_code) REFERENCES Spaces (space_code)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- --------------------------------------------------------------------------
-- 2.4 Bookings
-- --------------------------------------------------------------------------
CREATE TABLE Bookings (
    booking_id              INT             NOT NULL IDENTITY(1,1),
    requester_id            INT             NOT NULL,
    space_code              NVARCHAR(20)    NOT NULL,
    requested_start_time    DATETIME2       NOT NULL,
    requested_end_time      DATETIME2       NOT NULL,
    purpose_of_use          NVARCHAR(MAX)   NOT NULL,
    expected_participants   INT             NOT NULL,
    booking_type            NVARCHAR(25)    NOT NULL,
    status                  NVARCHAR(15)    NOT NULL,
    approver_id             INT             NULL,
    decision_time           DATETIME2       NULL,
    decision_note           NVARCHAR(MAX)   NULL,
    rejection_reason        NVARCHAR(MAX)   NULL,
    actual_start_time       DATETIME2       NULL,
    check_in_person_id      INT             NULL,
    initial_condition       NVARCHAR(MAX)   NULL,
    actual_end_time         DATETIME2       NULL,
    final_condition         NVARCHAR(MAX)   NULL,
    usage_notes             NVARCHAR(MAX)   NULL,

    CONSTRAINT PK_Bookings PRIMARY KEY (booking_id),

    CONSTRAINT FK_Bookings_Requester
        FOREIGN KEY (requester_id) REFERENCES Users (user_id)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,

    CONSTRAINT FK_Bookings_SpaceCode
        FOREIGN KEY (space_code) REFERENCES Spaces (space_code)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,

    CONSTRAINT FK_Bookings_Approver
        FOREIGN KEY (approver_id) REFERENCES Users (user_id)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,

    CONSTRAINT FK_Bookings_CheckInPerson
        FOREIGN KEY (check_in_person_id) REFERENCES Users (user_id)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,

    CONSTRAINT CK_Bookings_BookingType CHECK (booking_type IN (
        'Lecture',
        'Examination',
        'Seminar',
        'Workshop',
        'Meeting',
        'Student Activity',
        'Administrative Event'
    )),

    CONSTRAINT CK_Bookings_Status CHECK (status IN (
        'Pending',
        'Approved',
        'Rejected',
        'Cancelled',
        'Checked In',
        'Completed',
        'No-Show'
    )),

    CONSTRAINT CK_Bookings_TimeRange CHECK (requested_end_time > requested_start_time),
    CONSTRAINT CK_Bookings_Participants CHECK (expected_participants > 0),

    -- An Approved or Rejected booking must have a decision and an approver.
    CONSTRAINT CK_Bookings_Decision CHECK (
        status NOT IN ('Approved', 'Rejected')
        OR (approver_id IS NOT NULL AND decision_time IS NOT NULL)
    ),

    -- A Rejected booking must include a rejection reason.
    CONSTRAINT CK_Bookings_Rejection CHECK (
        status <> 'Rejected'
        OR rejection_reason IS NOT NULL
    ),

    -- actual_end_time requires actual_start_time.
    CONSTRAINT CK_Bookings_CheckOut CHECK (
        actual_end_time IS NULL
        OR actual_start_time IS NOT NULL
    )
);

-- --------------------------------------------------------------------------
-- 2.5 MaintenanceRecords
-- --------------------------------------------------------------------------
CREATE TABLE MaintenanceRecords (
    maintenance_id      INT             NOT NULL IDENTITY(1,1),
    space_code          NVARCHAR(20)    NOT NULL,
    reporter_id         INT             NOT NULL,
    assigned_staff_id   INT             NULL,
    problem_description NVARCHAR(MAX)   NOT NULL,
    problem_type        NVARCHAR(30)    NOT NULL,
    start_time          DATETIME2       NULL,
    completion_time     DATETIME2       NULL,
    status              NVARCHAR(15)    NOT NULL,
    result_note         NVARCHAR(MAX)   NULL,

    CONSTRAINT PK_MaintenanceRecords PRIMARY KEY (maintenance_id),

    CONSTRAINT FK_MaintenanceRecords_SpaceCode
        FOREIGN KEY (space_code) REFERENCES Spaces (space_code)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,

    CONSTRAINT FK_MaintenanceRecords_Reporter
        FOREIGN KEY (reporter_id) REFERENCES Users (user_id)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,

    CONSTRAINT FK_MaintenanceRecords_AssignedStaff
        FOREIGN KEY (assigned_staff_id) REFERENCES Users (user_id)
        ON DELETE SET NULL
        ON UPDATE NO ACTION,

    CONSTRAINT CK_MaintenanceRecords_ProblemType CHECK (problem_type IN (
        'Broken Projector',
        'Air-Conditioning Failure',
        'Damaged Furniture',
        'Cleaning Issue',
        'Network Problem',
        'Other'
    )),

    CONSTRAINT CK_MaintenanceRecords_Status CHECK (status IN (
        'Reported',
        'In Progress',
        'Completed',
        'Cancelled'
    )),

    -- If a completion time is recorded, a start time must also exist.
    CONSTRAINT CK_MaintenanceRecords_CompletionTime CHECK (
        completion_time IS NULL
        OR start_time IS NOT NULL
    )
);

-- ============================================================================
-- 3. INDEXES
-- ============================================================================

-- Speed up overlap checks for conflict-prevention trigger.
CREATE INDEX IX_Bookings_SpaceCode_TimeRange
    ON Bookings (space_code, requested_start_time, requested_end_time)
    WHERE status IN ('Approved', 'Checked In');

-- Look up bookings by requester.
CREATE INDEX IX_Bookings_Requester
    ON Bookings (requester_id);

-- Find active maintenance records for a space (used by BR2/BR7 trigger).
CREATE INDEX IX_MaintenanceRecords_Active
    ON MaintenanceRecords (space_code, status)
    WHERE status IN ('Reported', 'In Progress');

-- Look up facilities by space.
CREATE INDEX IX_Facilities_SpaceCode
    ON Facilities (space_code);
GO

-- ============================================================================
-- 4. TRIGGERS
-- ============================================================================

-- --------------------------------------------------------------------------
-- 4.1 Trigger: trg_Maintenance_SyncSpaceStatus (BR2 + BR7)
--
-- When a MaintenanceRecord is inserted or updated:
--   - If the new status is 'Reported' or 'In Progress', set the
--     Space.current_status to 'Under Maintenance'.
--   - If the new status is 'Completed' or 'Cancelled', check whether
--     any other active maintenance exists for that space.  If none,
--     revert Space.current_status to 'Available'.
-- --------------------------------------------------------------------------
CREATE TRIGGER trg_Maintenance_SyncSpaceStatus
    ON MaintenanceRecords
    AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Handle activation: maintenance marked Reported or In Progress.
    UPDATE s
    SET current_status = 'Under Maintenance'
    FROM Spaces s
    INNER JOIN inserted i ON s.space_code = i.space_code
    WHERE i.status IN ('Reported', 'In Progress')
      AND s.current_status NOT IN ('Temporarily Closed', 'Retired');

    -- Handle deactivation: maintenance marked Completed or Cancelled.
    -- Only revert to Available if no other active maintenance exists for
    -- that space AND the space is not Temporarily Closed or Retired.
    UPDATE s
    SET current_status = 'Available'
    FROM Spaces s
    INNER JOIN inserted i ON s.space_code = i.space_code
    WHERE i.status IN ('Completed', 'Cancelled')
      AND s.current_status = 'Under Maintenance'
      AND NOT EXISTS (
          SELECT 1
          FROM MaintenanceRecords m
          WHERE m.space_code = s.space_code
            AND m.status IN ('Reported', 'In Progress')
      );
END;
GO

-- --------------------------------------------------------------------------
-- 4.2 Trigger: trg_Booking_PreventOverlap (BR3)
--
-- Before INSERT or UPDATE on Bookings, prevent creating or updating a
-- booking to 'Approved' or 'Checked In' if another approved/checked-in
-- booking already exists for the same space with overlapping time.
-- --------------------------------------------------------------------------
CREATE TRIGGER trg_Booking_PreventOverlap
    ON Bookings
    AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM Bookings b1
        INNER JOIN inserted i
            ON  b1.space_code = i.space_code
            AND b1.booking_id <> i.booking_id
            AND b1.requested_start_time < i.requested_end_time
            AND i.requested_start_time < b1.requested_end_time
        WHERE i.status IN ('Approved', 'Checked In')
          AND b1.status IN ('Approved', 'Checked In')
    )
    BEGIN
        RAISERROR ('Booking conflict: the requested time period overlaps with an existing approved booking for this space.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;
END;
GO

-- ============================================================================
-- 5. COMPLETE CONSTRAINT INVENTORY
-- ============================================================================
--
-- Primary keys:      5 (Users.user_id, Spaces.space_code, Facilities.facility_id,
--                       Bookings.booking_id, MaintenanceRecords.maintenance_id)
-- Foreign keys:      8 (Facilities.space_code, Bookings.requester_id,
--                       Bookings.space_code, Bookings.approver_id,
--                       Bookings.check_in_person_id, MaintenanceRecords.space_code,
--                       MaintenanceRecords.reporter_id,
--                       MaintenanceRecords.assigned_staff_id)
-- UNIQUE:            2 (Users.email, Spaces.(building, floor, room_number))
-- CHECK (enum):      8 (role, account_status, space_type, current_status,
--                       booking_type, status, problem_type, maintenance status)
-- CHECK (range):     3 (capacity > 0, expected_participants > 0,
--                       requested_end_time > requested_start_time)
-- CHECK (conditional): 3 (decision/approver for Approved/Rejected,
--                         rejection_reason for Rejected,
--                         actual_start_time required for actual_end_time)
-- CHECK (completion): 1 (start_time required if completion_time provided)
-- Triggers:          2 (maintenance status sync, overlap prevention)
-- Indexes:           4 (time-range overlap, requester lookup, active
--                       maintenance, facilities by space)
-- ============================================================================

-- ============================================================================
-- Database Definition Script — Group G01
-- DBMS: Microsoft SQL Server
-- Description: Space Booking and Maintenance Management System
-- ============================================================================

-- ============================================================================
-- 1. DATABASE CREATION
-- ============================================================================
-- Uncomment and modify the file path below to create the database on your
-- target SQL Server instance.
--
-- CREATE DATABASE SpaceBookingDB;
-- GO
-- USE SpaceBookingDB;
-- GO

-- ============================================================================
-- 2. TABLES WITH CONSTRAINTS
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
    quantity        INT             NOT NULL DEFAULT 1,
    condition       NVARCHAR(100)   NULL,

    CONSTRAINT PK_Facilities PRIMARY KEY (facility_id),

    CONSTRAINT FK_Facilities_SpaceCode
        FOREIGN KEY (space_code) REFERENCES Spaces (space_code)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT CK_Facilities_Quantity CHECK (quantity >= 1)
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
        ON DELETE SET NULL
        ON UPDATE NO ACTION,

    CONSTRAINT FK_Bookings_CheckInPerson
        FOREIGN KEY (check_in_person_id) REFERENCES Users (user_id)
        ON DELETE SET NULL
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

    -- Validation recommendation I2 + I4:
    -- An Approved or Rejected booking must have an approver and a decision timestamp.
    CONSTRAINT CK_Bookings_Decision CHECK (
        status NOT IN ('Approved', 'Rejected')
        OR (approver_id IS NOT NULL AND decision_time IS NOT NULL)
    ),

    -- Validation recommendation I3:
    -- A Rejected booking must include a rejection reason.
    CONSTRAINT CK_Bookings_Rejection CHECK (
        status <> 'Rejected'
        OR rejection_reason IS NOT NULL
    ),

    -- Validation recommendation I5:
    -- If actual_end_time is recorded, actual_start_time must also be recorded.
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

    CONSTRAINT CK_MaintenanceRecords_CompletionTime CHECK (
        completion_time IS NULL
        OR start_time IS NOT NULL
    )
);

-- ============================================================================
-- 3. INDEXES FOR PERFORMANCE
-- ============================================================================

-- Index to speed up overlap checks: find approved bookings for a space
-- within a time range.
CREATE INDEX IX_Bookings_SpaceCode_TimeRange
    ON Bookings (space_code, requested_start_time, requested_end_time)
    WHERE status IN ('Approved', 'Checked In');

-- Index to find bookings by requester.
CREATE INDEX IX_Bookings_Requester
    ON Bookings (requester_id);

-- Index to find active maintenance records for a space (used when blocking
-- new bookings).
CREATE INDEX IX_MaintenanceRecords_Active
    ON MaintenanceRecords (space_code, status)
    WHERE status IN ('Reported', 'In Progress');

-- Index to look up facilities by space.
CREATE INDEX IX_Facilities_SpaceCode
    ON Facilities (space_code);

-- Index to look up spaces by building/location.
CREATE INDEX IX_Spaces_Location
    ON Spaces (building, floor);

-- ============================================================================
-- 4. VALIDATION TRACEABILITY
-- ============================================================================
--
-- Issue I1 (Medium): Added UNIQUE(building, floor, room_number) on Spaces.
-- Issue I2 (Low):   CK_Bookings_Decision enforces approver + decision_time
--                   when status is Approved or Rejected.
-- Issue I3 (Low):   CK_Bookings_Rejection enforces rejection_reason when
--                   status is Rejected.
-- Issue I4 (Low):   Handled by CK_Bookings_Decision (approver_id required
--                   when status is Approved or Rejected).
-- Issue I5 (Low):   CK_Bookings_CheckOut enforces actual_start_time required
--                   when actual_end_time is present.
-- Issue I6 (Info):  floor constraint relaxed (no lower bound) to allow
--                   basement levels (e.g., B1).
--
-- Business rules requiring external enforcement (triggers / app logic):
--   E1: No overlapping approved bookings (BR3)
--   E2: Maintenance blocks booking (BR7)
--   E3: No overlapping active maintenance (BR9)
--   E4: Status lifecycle sequencing (BR4)
-- ============================================================================

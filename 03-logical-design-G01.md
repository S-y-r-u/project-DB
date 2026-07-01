# Logical Database Design — Relational Schema — Group G01

## 1. Relational Schema Overview

Five relations derived from the conceptual ERD:

| Relation | Abbreviation | ERD Source |
|---|---|---|
| Users | USR | USER entity |
| Spaces | SPC | SPACE entity |
| Facilities | FAC | FACILITY entity |
| Bookings | BKG | BOOKING entity |
| MaintenanceRecords | MNT | MAINTENANCE entity |

---

## 2. Relation Definitions

### 2.1 Users

| Column | Domain | Constraints | Description |
|---|---|---|---|
| user_id | INT | **PK**, NOT NULL | System-generated unique identifier |
| full_name | NVARCHAR(100) | NOT NULL | Full name of the user |
| email | NVARCHAR(255) | NOT NULL, **UNIQUE** | University email address |
| phone_number | NVARCHAR(20) | NULL | Contact phone number |
| role | NVARCHAR(30) | NOT NULL, CHECK(role IN ('Student', 'Lecturer', 'Teaching Assistant', 'Facility Staff', 'Department Administrator', 'Facility Manager')) | User role |
| department | NVARCHAR(100) | NOT NULL | Academic or administrative department |
| account_status | NVARCHAR(15) | NOT NULL, CHECK(account_status IN ('Active', 'Suspended', 'Inactive')) | Account operational status |

**Candidate keys**: `user_id` (PK), `email` (UNIQUE)

---

### 2.2 Spaces

| Column | Domain | Constraints | Description |
|---|---|---|---|
| space_code | NVARCHAR(20) | **PK**, NOT NULL | Unique space identifier (e.g., CS-101) |
| space_name | NVARCHAR(100) | NOT NULL | Human-readable name |
| space_type | NVARCHAR(30) | NOT NULL, CHECK(space_type IN ('Auditorium', 'Classroom', 'Computer Laboratory', 'Project Laboratory', 'Meeting Room', 'Student Workspace')) | Category of the space |
| building | NVARCHAR(100) | NOT NULL | Building location |
| floor | INT | NOT NULL | Floor number |
| room_number | NVARCHAR(20) | NOT NULL | Room number on the floor |
| capacity | INT | NOT NULL, CHECK(capacity > 0) | Maximum occupancy |
| current_status | NVARCHAR(20) | NOT NULL, CHECK(current_status IN ('Available', 'In Use', 'Under Maintenance', 'Temporarily Closed', 'Retired')) | Operational status |
| usage_policy | NVARCHAR(MAX) | NULL | Rules governing space use |

**Candidate keys**: `space_code` (PK), `(building, floor, room_number)` (UNIQUE business key)

---

### 2.3 Facilities

| Column | Domain | Constraints | Description |
|---|---|---|---|
| facility_id | INT | **PK**, NOT NULL | System-generated unique identifier |
| space_code | NVARCHAR(20) | NOT NULL, **FK → Spaces(space_code)** | The space this facility belongs to |
| facility_name | NVARCHAR(100) | NOT NULL | Name (e.g., Projector, Whiteboard) |
| condition | NVARCHAR(100) | NULL | Current working condition |

**Candidate keys**: `facility_id` (PK)

**Referential integrity**: CASCADE delete on `space_code` — facilities are part of a space.

---

### 2.4 Bookings

| Column | Domain | Constraints | Description |
|---|---|---|---|
| booking_id | INT | **PK**, NOT NULL | System-generated unique identifier |
| requester_id | INT | NOT NULL, **FK → Users(user_id)** | User who submitted the request |
| space_code | NVARCHAR(20) | NOT NULL, **FK → Spaces(space_code)** | The requested space |
| requested_start_time | DATETIME2 | NOT NULL | Desired start date and time |
| requested_end_time | DATETIME2 | NOT NULL, CHECK(requested_end_time > requested_start_time) | Desired end date and time |
| purpose_of_use | NVARCHAR(MAX) | NOT NULL | Description of intended use |
| expected_participants | INT | NOT NULL, CHECK(expected_participants > 0) | Number of people expected |
| booking_type | NVARCHAR(25) | NOT NULL, CHECK(booking_type IN ('Lecture', 'Examination', 'Seminar', 'Workshop', 'Meeting', 'Student Activity', 'Administrative Event')) | Category of booking |
| status | NVARCHAR(15) | NOT NULL, CHECK(status IN ('Pending', 'Approved', 'Rejected', 'Cancelled', 'Checked In', 'Completed', 'No-Show')) | Current lifecycle state |
| approver_id | INT | NULL, **FK → Users(user_id)** | Staff who approved/rejected |
| decision_time | DATETIME2 | NULL | When the decision was made |
| decision_note | NVARCHAR(MAX) | NULL | Notes accompanying the decision |
| rejection_reason | NVARCHAR(MAX) | NULL | Reason if rejected |
| actual_start_time | DATETIME2 | NULL | Actual check-in time |
| check_in_person_id | INT | NULL, **FK → Users(user_id)** | Staff who performed check-in |
| initial_condition | NVARCHAR(MAX) | NULL | Space condition at check-in |
| actual_end_time | DATETIME2 | NULL | Actual completion time |
| final_condition | NVARCHAR(MAX) | NULL | Space condition at check-out |
| usage_notes | NVARCHAR(MAX) | NULL | Notes about the session |

**Candidate keys**: `booking_id` (PK)

**Referential integrity**:
- `requester_id` → Users: ON DELETE NO ACTION (preserve booking history)
- `space_code` → Spaces: ON DELETE NO ACTION
- `approver_id` → Users: ON DELETE SET NULL
- `check_in_person_id` → Users: ON DELETE SET NULL

---

### 2.5 MaintenanceRecords

| Column | Domain | Constraints | Description |
|---|---|---|---|
| maintenance_id | INT | **PK**, NOT NULL | System-generated unique identifier |
| space_code | NVARCHAR(20) | NOT NULL, **FK → Spaces(space_code)** | The space being maintained |
| reporter_id | INT | NOT NULL, **FK → Users(user_id)** | User who reported the problem |
| assigned_staff_id | INT | NULL, **FK → Users(user_id)** | Staff assigned to fix the issue |
| problem_description | NVARCHAR(MAX) | NOT NULL | Description of the problem |
| problem_type | NVARCHAR(30) | NOT NULL, CHECK(problem_type IN ('Broken Projector', 'Air-Conditioning Failure', 'Damaged Furniture', 'Cleaning Issue', 'Network Problem', 'Other')) | Category of the problem |
| start_time | DATETIME2 | NULL | When maintenance work began |
| completion_time | DATETIME2 | NULL | When maintenance was completed |
| status | NVARCHAR(15) | NOT NULL, CHECK(status IN ('Reported', 'In Progress', 'Completed', 'Cancelled')) | Current maintenance state |
| result_note | NVARCHAR(MAX) | NULL | Notes about the outcome |

**Candidate keys**: `maintenance_id` (PK)

**Referential integrity**:
- `space_code` → Spaces: ON DELETE NO ACTION (preserve maintenance history)
- `reporter_id` → Users: ON DELETE NO ACTION
- `assigned_staff_id` → Users: ON DELETE SET NULL

---

## 3. Foreign Key Summary

| FK Column | Parent Table | Parent Column | Nullable | Delete Rule | Update Rule |
|---|---|---|---|---|---|
| Facilities.space_code | Spaces | space_code | NO | CASCADE | CASCADE |
| Bookings.requester_id | Users | user_id | NO | NO ACTION | NO ACTION |
| Bookings.space_code | Spaces | space_code | NO | NO ACTION | CASCADE |
| Bookings.approver_id | Users | user_id | YES | SET NULL | NO ACTION |
| Bookings.check_in_person_id | Users | user_id | YES | SET NULL | NO ACTION |
| MaintenanceRecords.space_code | Spaces | space_code | NO | NO ACTION | CASCADE |
| MaintenanceRecords.reporter_id | Users | user_id | NO | NO ACTION | NO ACTION |
| MaintenanceRecords.assigned_staff_id | Users | user_id | YES | SET NULL | NO ACTION |

---

## 4. Candidate Keys Summary

| Relation | Primary Key | Alternate Key |
|---|---|---|
| Users | user_id | email |
| Spaces | space_code | (building, floor, room_number) |
| Facilities | facility_id | — |
| Bookings | booking_id | — |
| MaintenanceRecords | maintenance_id | — |

---

## 5. Constraint Checklist

| Constraint Type | Count | Examples |
|---|---|---|
| Primary keys | 5 | user_id, space_code, facility_id, booking_id, maintenance_id |
| Foreign keys | 8 | As listed in Section 3 |
| UNIQUE | 2 | Users.email, Spaces.(building, floor, room_number) |
| CHECK (enum) | 8 | role, account_status, space_type, current_status, booking_type, status, problem_type, maintenance status |
| CHECK (range) | 3 | capacity > 0, expected_participants > 0, requested_end_time > requested_start_time |

---

## 6. Business Rule Enforcement

| BR | Rule | Enforcement |
|---|---|---|
| 1 | Unique user identity | PK (user_id) + UNIQUE (email) |
| 2 | Space status prevents booking | CHECK on current_status; trigger syncs with MaintenanceRecord |
| 3 | No overlapping approved bookings | Trigger or app — temporal overlap check |
| 4 | Booking status lifecycle | App logic |
| 5 | Approval recording | Columns present; conditional CHECK constraints |
| 6 | Check-in/check-out recording | Columns present |
| 7 | Maintenance blocks + auto-revert | Trigger on MaintenanceRecord changes |
| 8 | Historical retention | ON DELETE NO ACTION on history-critical FKs |
| 9 | Role-based actions | App logic (validate approver/check-in person role) |
| 10 | Suspended/inactive cannot book | App logic (check account_status before booking) |

---

## 7. Normalization Verification

| Normal Form | Status | Justification |
|---|---|---|
| 1NF | ✓ | All columns are atomic; no repeating groups. |
| 2NF | ✓ | All PKs are single-column; no partial dependencies. |
| 3NF | ✓ | Every non-key attribute depends solely on the PK. |
| BCNF | ✓ | Every determinant is a candidate key. |

**Verdict**: Schema is in BCNF.

---

## 8. Traceability from ERD to Relational Schema

| ERD Entity | Relation | FK Added | Relationship |
|---|---|---|---|
| USER | Users | — | — |
| SPACE | Spaces | — | — |
| FACILITY | Facilities | space_code → Spaces | contains |
| BOOKING | Bookings | requester_id → Users | submits |
| BOOKING | Bookings | space_code → Spaces | books |
| BOOKING | Bookings | approver_id → Users | approves |
| BOOKING | Bookings | check_in_person_id → Users | checks in |
| MAINTENANCE | MaintenanceRecords | space_code → Spaces | undergoes |
| MAINTENANCE | MaintenanceRecords | reporter_id → Users | reports |
| MAINTENANCE | MaintenanceRecords | assigned_staff_id → Users | assigned |

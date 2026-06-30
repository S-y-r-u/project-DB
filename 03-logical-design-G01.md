# Logical Database Design — Relational Schema — Group G01

## 1. Relational Schema Overview

Five relations derived from the conceptual ERD:

| Relation | Abbreviation | Type |
|---|---|---|
| Users | USR | Strong entity |
| Spaces | SPC | Strong entity |
| Facilities | FAC | Strong entity |
| Bookings | BKG | Strong entity |
| MaintenanceRecords | MNT | Strong entity |

---

## 2. Relation Definitions

### 2.1 Users

| Column | Domain / Type | Constraints | Description |
|---|---|---|---|
| user_id | INT | **PK**, NOT NULL | System-generated unique identifier |
| full_name | NVARCHAR(100) | NOT NULL | Full name of the user |
| email | NVARCHAR(255) | NOT NULL, **UNIQUE** | University email address |
| phone_number | NVARCHAR(20) | NULLABLE | Contact phone number |
| role | NVARCHAR(30) | NOT NULL, CHECK(role IN ('Student', 'Lecturer', 'Teaching Assistant', 'Facility Staff', 'Department Administrator', 'Facility Manager')) | User role in the system |
| department | NVARCHAR(100) | NOT NULL | Academic or administrative department |
| account_status | NVARCHAR(15) | NOT NULL, CHECK(account_status IN ('Active', 'Suspended', 'Inactive')) | Account operational status |

**Candidate keys**: `user_id` (PK), `email` (unique)

---

### 2.2 Spaces

| Column | Domain / Type | Constraints | Description |
|---|---|---|---|
| space_code | NVARCHAR(20) | **PK**, NOT NULL | Unique space identifier (e.g., CS-101) |
| space_name | NVARCHAR(100) | NOT NULL | Human-readable name |
| space_type | NVARCHAR(30) | NOT NULL, CHECK(space_type IN ('Auditorium', 'Classroom', 'Computer Laboratory', 'Project Laboratory', 'Meeting Room', 'Student Workspace')) | Category of the space |
| building | NVARCHAR(100) | NOT NULL | Building location |
| floor | INT | NOT NULL, CHECK(floor >= 0) | Floor number |
| room_number | NVARCHAR(20) | NOT NULL | Room number on the floor |
| capacity | INT | NOT NULL, CHECK(capacity > 0) | Maximum occupancy |
| current_status | NVARCHAR(20) | NOT NULL, CHECK(current_status IN ('Available', 'In Use', 'Under Maintenance', 'Temporarily Closed', 'Retired')) | Operational status |
| usage_policy | NVARCHAR(MAX) | NULLABLE | Rules governing space use |

**Candidate keys**: `space_code` (PK)

---

### 2.3 Facilities

| Column | Domain / Type | Constraints | Description |
|---|---|---|---|
| facility_id | INT | **PK**, NOT NULL | System-generated unique identifier |
| space_code | NVARCHAR(20) | NOT NULL, **FK → Spaces(space_code)** | The space this facility belongs to |
| facility_name | NVARCHAR(100) | NOT NULL | Name (e.g., Projector, Whiteboard) |
| quantity | INT | NOT NULL, DEFAULT 1, CHECK(quantity >= 1) | Number of units |
| condition | NVARCHAR(100) | NULLABLE | Current working condition |

**Candidate keys**: `facility_id` (PK)

**Referential integrity**: `space_code` FK references `Spaces(space_code)` — ON DELETE CASCADE (facilities are part of a space; if a space is removed, its facilities are removed).

---

### 2.4 Bookings

| Column | Domain / Type | Constraints | Description |
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
| approver_id | INT | NULLABLE, **FK → Users(user_id)** | Staff who approved/rejected |
| decision_time | DATETIME2 | NULLABLE | When decision was made |
| decision_note | NVARCHAR(MAX) | NULLABLE | Notes accompanying decision |
| rejection_reason | NVARCHAR(MAX) | NULLABLE | Reason if rejected |
| actual_start_time | DATETIME2 | NULLABLE | Actual check-in time |
| check_in_person_id | INT | NULLABLE, **FK → Users(user_id)** | Staff who performed check-in |
| initial_condition | NVARCHAR(MAX) | NULLABLE | Space condition at check-in |
| actual_end_time | DATETIME2 | NULLABLE | Actual completion time |
| final_condition | NVARCHAR(MAX) | NULLABLE | Space condition at check-out |
| usage_notes | NVARCHAR(MAX) | NULLABLE | Notes about the session |

**Candidate keys**: `booking_id` (PK)

**Referential integrity**:
- `requester_id` FK → `Users(user_id)` — ON DELETE NO ACTION (keep booking history)
- `space_code` FK → `Spaces(space_code)` — ON DELETE NO ACTION
- `approver_id` FK → `Users(user_id)` — ON DELETE SET NULL (keep booking even if staff account is removed)
- `check_in_person_id` FK → `Users(user_id)` — ON DELETE SET NULL

---

### 2.5 MaintenanceRecords

| Column | Domain / Type | Constraints | Description |
|---|---|---|---|
| maintenance_id | INT | **PK**, NOT NULL | System-generated unique identifier |
| space_code | NVARCHAR(20) | NOT NULL, **FK → Spaces(space_code)** | The space being maintained |
| reporter_id | INT | NOT NULL, **FK → Users(user_id)** | User who reported the problem |
| assigned_staff_id | INT | NULLABLE, **FK → Users(user_id)** | Staff assigned to fix it |
| problem_description | NVARCHAR(MAX) | NOT NULL | Description of the problem |
| problem_type | NVARCHAR(30) | NOT NULL, CHECK(problem_type IN ('Broken Projector', 'Air-Conditioning Failure', 'Damaged Furniture', 'Cleaning Issue', 'Network Problem', 'Other')) | Category of problem |
| start_time | DATETIME2 | NULLABLE | When work began |
| completion_time | DATETIME2 | NULLABLE | When work was completed |
| status | NVARCHAR(15) | NOT NULL, CHECK(status IN ('Reported', 'In Progress', 'Completed', 'Cancelled')) | Current maintenance state |
| result_note | NVARCHAR(MAX) | NULLABLE | Outcome notes |

**Candidate keys**: `maintenance_id` (PK)

**Referential integrity**:
- `space_code` FK → `Spaces(space_code)` — ON DELETE NO ACTION
- `reporter_id` FK → `Users(user_id)` — ON DELETE NO ACTION
- `assigned_staff_id` FK → `Users(user_id)` — ON DELETE SET NULL

---

## 3. Foreign Key Summary

| FK Column | Parent Table | Parent Column | Nullable | Delete Rule |
|---|---|---|---|---|
| Facilities.space_code | Spaces | space_code | NO | CASCADE |
| Bookings.requester_id | Users | user_id | NO | NO ACTION |
| Bookings.space_code | Spaces | space_code | NO | NO ACTION |
| Bookings.approver_id | Users | user_id | YES | SET NULL |
| Bookings.check_in_person_id | Users | user_id | YES | SET NULL |
| MaintenanceRecords.space_code | Spaces | space_code | NO | NO ACTION |
| MaintenanceRecords.reporter_id | Users | user_id | NO | NO ACTION |
| MaintenanceRecords.assigned_staff_id | Users | user_id | YES | SET NULL |

---

## 4. Candidate Keys and Alternate Keys

| Relation | Primary Key | Alternate / Candidate Keys |
|---|---|---|
| Users | user_id | email |
| Spaces | space_code | (building, floor, room_number) — business key candidate |
| Facilities | facility_id | — |
| Bookings | booking_id | — |
| MaintenanceRecords | maintenance_id | — |

---

## 5. Additional Business Constraints (not expressible as simple CHECK)

| Constraint | Description | Enforcement Mechanism |
|---|---|---|
| No overlapping approved bookings | Two approved bookings for the same space must not have overlapping time intervals | Application logic or a trigger that checks intervals before INSERT/UPDATE on Bookings |
| Maintenance blocks booking | A space with a non-completed MaintenanceRecord (status IN ('Reported', 'In Progress')) cannot receive new approved bookings | Application logic or a trigger |
| Approver must have staff role | The user referenced by approver_id should have role IN ('Facility Staff', 'Facility Manager') | Application logic or a CHECK constraint with a UDF |
| Check-in person must have staff role | The user referenced by check_in_person_id should have role IN ('Facility Staff', 'Facility Manager') | Application logic or a CHECK constraint with a UDF |
| Decision time required if status is Approved or Rejected | If status IN ('Approved', 'Rejected') then decision_time IS NOT NULL | Application logic or a CHECK constraint |
| Rejection reason required if status is Rejected | If status = 'Rejected' then rejection_reason IS NOT NULL | Application logic or a CHECK constraint |
| No overlapping active maintenance | A space should not have two active (Reported or In Progress) maintenance records simultaneously | Application logic or a trigger |

---

## 6. Normalization Verification

| Normal Form | Status | Justification |
|---|---|---|
| **1NF** | ✓ | All attributes are atomic; no repeating groups or composite attributes exist. |
| **2NF** | ✓ | Every non-key attribute is fully functionally dependent on the entire PK. No partial dependencies exist (all PKs are single-column). |
| **3NF** | ✓ | No transitive dependencies. All non-key attributes depend directly on the PK, not on other non-key attributes. |
| **BCNF** | ✓ | Every determinant is a candidate key. No FD where a non-candidate-key determines another attribute exists. |

Schema is in BCNF.

---

## 7. Traceability from ERD to Relational Schema

| ERD Entity | Mapped To | FK Introduced From | FK Relationship |
|---|---|---|---|
| USER | Users | — | — |
| SPACE | Spaces | — | — |
| FACILITY | Facilities | Facilities.space_code → Spaces | contains |
| BOOKING | Bookings | Bookings.requester_id → Users | submits |
| BOOKING | Bookings | Bookings.space_code → Spaces | books |
| BOOKING | Bookings | Bookings.approver_id → Users | approves |
| BOOKING | Bookings | Bookings.check_in_person_id → Users | checks in |
| MAINTENANCE | MaintenanceRecords | MaintenanceRecords.space_code → Spaces | undergoes |
| MAINTENANCE | MaintenanceRecords | MaintenanceRecords.reporter_id → Users | reports |
| MAINTENANCE | MaintenanceRecords | MaintenanceRecords.assigned_staff_id → Users | assigned |

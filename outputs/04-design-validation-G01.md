# Design Validation Report — Group G01

## 1. ERD-to-Relational Mapping Validation

### 1.1 Entity Coverage

| ERD Entity | Relation | Status | Notes |
|---|---|---|---|
| USER | Users | ✓ | All 7 attributes mapped correctly |
| SPACE | Spaces | ✓ | All 9 attributes mapped correctly |
| FACILITY | Facilities | ✓ | All 3 attributes mapped correctly; 1 FK added for relationship |
| BOOKING | Bookings | ✓ | All 16 attributes mapped; 4 FKs added for relationships |
| MAINTENANCE | MaintenanceRecords | ✓ | All 7 attributes mapped; 3 FKs added for relationships |

### 1.2 Relationship Coverage

| ERD Relationship | Cardinality | FK Implementation | Nullable | Delete Rule | Status |
|---|---|---|---|---|---|
| submits | 1:N | Bookings.requester_id → Users.user_id | NO | NO ACTION | ✓ |
| approves | 1:N (opt) | Bookings.approver_id → Users.user_id | YES | NO ACTION | ✓ |
| checks in | 1:N (opt) | Bookings.check_in_person_id → Users.user_id | YES | NO ACTION | ✓ |
| reports | 1:N | MaintenanceRecords.reporter_id → Users.user_id | NO | NO ACTION | ✓ |
| assigned | 1:N (opt) | MaintenanceRecords.assigned_staff_id → Users.user_id | YES | SET NULL | ✓ |
| books | 1:N | Bookings.space_code → Spaces.space_code | NO | NO ACTION | ✓ |
| contains | 1:N | Facilities.space_code → Spaces.space_code | NO | CASCADE | ✓ |
| undergoes | 1:N | MaintenanceRecords.space_code → Spaces.space_code | NO | NO ACTION | ✓ |

**Result**: All 8 relationships correctly mapped. Participation constraints (optional vs. mandatory) match via NULL/NOT NULL. ✓

---

## 2. Business Rules Compliance

| BR | Rule | DDL Enforcement | App/Trigger | Status |
|---|---|---|---|---|
| 1 | Unique user identity | PK (`user_id`), UNIQUE (`email`) | — | ✓ Schema-level |
| 2 | Space status prevents booking + auto-sync | CHECK on `current_status` for valid values | Trigger syncs Space.status with MaintenanceRecord | ⚠ Partial (DDL covers domain, trigger specified but not designed) |
| 3 | No overlapping approved bookings | — | Trigger or app | ⚠ External (documented) |
| 4 | Booking status lifecycle | CHECK on `status` for valid values | App logic for transitions | ⚠ Partial |
| 5 | Approval recording | `approver_id`, `decision_time`, `decision_note`, `rejection_reason` columns present | Conditional CHECK | ✓ Schema-level (columns) |
| 6 | Check-in/check-out recording | `actual_start_time`, `check_in_person_id`, `initial_condition`, `actual_end_time`, `final_condition`, `usage_notes` columns present | — | ✓ Schema-level |
| 7 | Maintenance blocks + auto-revert | — | Trigger on MaintenanceRecord changes | ⚠ External (documented) |
| 8 | Historical retention | ON DELETE NO ACTION on all history-critical FKs | — | ✓ Schema-level |
| 9 | Role-based actions | — | App logic for role validation | ⚠ External |
| 10 | Suspended/inactive cannot book | — | App logic on account_status check | ⚠ External |

**Verdict**: 6 of 10 rules have schema-level enforcement; 4 require external mechanisms (all documented in Section 6 of the logical design). ✓

---

## 3. Key and Constraint Analysis

### 3.1 Primary Keys

| Relation | PK | Type | Assessment |
|---|---|---|---|
| Users | user_id | Surrogate INT | ✓ Stable, compact |
| Spaces | space_code | Natural NVARCHAR(20) | ✓ Meaningful identifier (e.g., CS-101) |
| Facilities | facility_id | Surrogate INT | ✓ No natural key |
| Bookings | booking_id | Surrogate INT | ✓ No natural key |
| MaintenanceRecords | maintenance_id | Surrogate INT | ✓ No natural key |

### 3.2 Candidate / Alternate Keys

| Relation | Candidate Key | Enforced? | Status |
|---|---|---|---|
| Users | email | UNIQUE | ✓ |
| Spaces | (building, floor, room_number) | UNIQUE | ✓ |

### 3.3 Foreign Key Delete Rules

| FK | Delete Rule | Justification | Assessment |
|---|---|---|---|
| Facilities.space_code → Spaces | CASCADE | Facilities are dependent on a space | ✓ |
| Bookings.requester_id → Users | NO ACTION | Preserve booking history | ✓ |
| Bookings.space_code → Spaces | NO ACTION | Preserve booking history | ✓ |
| Bookings.approver_id → Users | NO ACTION | Preserve booking history | ✓ |
| Bookings.check_in_person_id → Users | NO ACTION | Preserve booking history | ✓ |
| MaintenanceRecords.space_code → Spaces | NO ACTION | Preserve maintenance history | ✓ |
| MaintenanceRecords.reporter_id → Users | NO ACTION | Preserve maintenance history | ✓ |
| MaintenanceRecords.assigned_staff_id → Users | SET NULL | Keep record if staff removed | ✓ |

### 3.4 Domain Constraint Completeness

| CHECK Target | Values Covered | Matches Requirements? |
|---|---|---|
| role | Student, Lecturer, Teaching Assistant, Facility Staff, Department Administrator, Facility Manager | ✓ (abbreviations TA/Dept Admin expanded to full names, consistent with ERD) |
| account_status | Active, Suspended, Inactive | ✓ |
| space_type | Auditorium, Classroom, Computer Laboratory, Project Laboratory, Meeting Room, Student Workspace | ⚠ Requirement uses "Computer Lab" / "Project Lab"; ERD/logical use full names (consistent between ERD and logical) |
| current_status | Available, In Use, Under Maintenance, Temporarily Closed, Retired | ✓ |
| booking_type | Lecture, Examination, Seminar, Workshop, Meeting, Student Activity, Administrative Event | ✓ |
| status | Pending, Approved, Rejected, Cancelled, Checked In, Completed, No-Show | ✓ |
| problem_type | Broken Projector, Air-Conditioning Failure, Damaged Furniture, Cleaning Issue, Network Problem, Other | ✓ |
| maintenance status | Reported, In Progress, Completed, Cancelled | ✓ |
| capacity | > 0 | ✓ |
| expected_participants | > 0 | ✓ |
| requested_end_time | > requested_start_time | ✓ |

---

## 4. Schema Consistency Audit

### 4.1 Issues Found

| ID | Severity | Location | Issue | Recommendation |
|---|---|---|---|---|
| V1 | Low | Requirement vs. ERD | Requirement §3.2 uses "Computer Lab" / "Project Lab"; ERD and logical design use "Computer Laboratory" / "Project Laboratory". | Cosmetic difference. The ERD convention is followed consistently throughout. No action needed. |
| V2 | Low | Requirement vs. ERD | Requirement §3.1 uses "TA" / "Dept Admin"; ERD and logical design use full names "Teaching Assistant" / "Department Administrator". | Consistent between ERD and logical design. No action needed. |
| V3 | Info | Logical Design §5 | Constraint checklist says "CHECK (range) \| 3". Rows shown: capacity > 0, expected_participants > 0, requested_end_time > requested_start_time. Count matches. | No action needed. |

### 4.2 Normalization Verification

| Check | Status | Finding |
|---|---|---|
| 1NF | ✓ | All columns atomic; no repeating groups. |
| 2NF | ✓ | All PKs single-column; no partial dependencies. |
| 3NF | ✓ | No transitive dependencies. |
| BCNF | ✓ | Every determinant is a candidate key. |

---

## 5. Overall Assessment

| Criteria | Result |
|---|---|
| ERD faithfully represented | ✓ All 5 entities and 8 relationships correctly mapped with matching cardinalities |
| Business rules addressed | ✓ All 10 rules addressed (6 schema-level, 4 documented for external enforcement) |
| Keys appropriate | ✓ Surrogate PKs where no natural key; natural PK for Spaces; email and location as alternate keys |
| Relationships correct | ✓ FKs on the N-side with correct nullability and delete rules matching participation constraints |
| Constraints complete | ✓ All CHECK constraints, UNIQUE, and NOT NULL properly match their respective columns |
| Normalization | ✓ BCNF |

### 5.1 Verdict

The logical design is **sound** and ready for DDL implementation. No blocking issues found.

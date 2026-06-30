# Design Validation Report — Group G01

## 1. ERD-to-Relational Mapping Validation

### 1.1 Entity Coverage

| ERD Entity | Relation | Status | Notes |
|---|---|---|---|
| USER | Users | ✓ | All attributes mapped |
| SPACE | Spaces | ✓ | All attributes mapped |
| FACILITY | Facilities | ✓ | All attributes mapped; FK `space_code` added |
| BOOKING | Bookings | ✓ | All attributes mapped; FKs `requester_id`, `space_code`, `approver_id`, `check_in_person_id` added |
| MAINTENANCE | MaintenanceRecords | ✓ | All attributes mapped; FKs `space_code`, `reporter_id`, `assigned_staff_id` added |

### 1.2 Relationship Coverage

| ERD Relationship | Cardinality | Implementation | Nullable | Delete Rule | Status |
|---|---|---|---|---|---|
| USER → BOOKING (submits) | 1:N | Bookings.requester_id FK → Users.user_id | NO | NO ACTION | ✓ |
| USER → BOOKING (approves) | 1:N (opt) | Bookings.approver_id FK → Users.user_id | YES | SET NULL | ✓ |
| USER → BOOKING (checks in) | 1:N (opt) | Bookings.check_in_person_id FK → Users.user_id | YES | SET NULL | ✓ |
| USER → MAINTENANCE (reports) | 1:N | MaintenanceRecords.reporter_id FK → Users.user_id | NO | NO ACTION | ✓ |
| USER → MAINTENANCE (assigned) | 1:N (opt) | MaintenanceRecords.assigned_staff_id FK → Users.user_id | YES | SET NULL | ✓ |
| SPACE → BOOKING (books) | 1:N | Bookings.space_code FK → Spaces.space_code | NO | NO ACTION | ✓ |
| SPACE → FACILITY (contains) | 1:N | Facilities.space_code FK → Spaces.space_code | NO | CASCADE | ✓ |
| SPACE → MAINTENANCE (undergoes) | 1:N | MaintenanceRecords.space_code FK → Spaces.space_code | NO | NO ACTION | ✓ |

**Result**: All 8 relationships from the ERD are correctly implemented as foreign keys. Participation constraints (optional vs. mandatory) match via NULL/NOT NULL. ✓

---

## 2. Business Rules Compliance

| Rule | Description | Covered in Schema? | Enforcement |
|---|---|---|---|
| BR1 | Unique user identity | ✓ | PK on `user_id`; UNIQUE on `email` |
| BR2 | Space status prevents booking | Partial | CHECK on `current_status` stores valid values; **blocking logic** requires trigger or app |
| BR3 | No overlapping approved bookings | Missing | Must be enforced by trigger or application code |
| BR4 | Booking status lifecycle | Partial | CHECK on `status` restricts values; **state transitions** require app logic |
| BR5 | Approval recording | ✓ | `approver_id`, `decision_time`, `decision_note`, `rejection_reason` present |
| BR6 | Check-in/check-out recording | ✓ | `actual_start_time`, `check_in_person_id`, `initial_condition`, `actual_end_time`, `final_condition`, `usage_notes` present |
| BR7 | Maintenance blocks booking | Missing | Must be enforced by trigger or application code |
| BR8 | Historical retention | ✓ | ON DELETE NO ACTION on history-critical FKs prevents data loss |
| BR9 | No overlapping active maintenance | Missing | Must be enforced by trigger or application code |
| BR10 | Role-based actions | Partial | Noted in Section 5; UDF-based CHECK or app logic needed to restrict approver/check-in roles |

**Summary**: 4 rules fully covered by schema, 3 partially covered, 3 require additional enforcement mechanisms. This is expected for a logical design — temporal and state-machine constraints are typically implemented via triggers or application logic rather than pure DDL.

---

## 3. Key and Constraint Analysis

### 3.1 Primary Keys

| Relation | PK | Type | Assessment |
|---|---|---|---|
| Users | user_id | Surrogate INT | ✓ Appropriate; stable, compact |
| Spaces | space_code | Natural NVARCHAR(20) | ✓ Appropriate; meaningful code (e.g., CS-101) |
| Facilities | facility_id | Surrogate INT | ✓ Appropriate; no natural key exists |
| Bookings | booking_id | Surrogate INT | ✓ Appropriate; no natural key exists |
| MaintenanceRecords | maintenance_id | Surrogate INT | ✓ Appropriate; no natural key exists |

### 3.2 Candidate / Alternate Keys

| Relation | Candidate Key | Status | Assessment |
|---|---|---|---|
| Users | email | UNIQUE | ✓ Correct; university emails are unique |
| Spaces | (building, floor, room_number) | Not enforced | ⚠ Candidate key identified but no UNIQUE constraint declared in the schema definition. Should be added. |

### 3.3 CHECK Constraints — Completeness

| Check Target | Values | Assessment |
|---|---|---|
| Users.role | Student, Lecturer, Teaching Assistant, Facility Staff, Department Administrator, Facility Manager | ✓ Matches all 6 roles from requirements |
| Users.account_status | Active, Suspended, Inactive | ✓ Reasonable set |
| Spaces.space_type | Auditorium, Classroom, Computer Laboratory, Project Laboratory, Meeting Room, Student Workspace | ✓ Matches all 6 types |
| Spaces.current_status | Available, In Use, Under Maintenance, Temporarily Closed, Retired | ✓ Matches all 5 statuses |
| Spaces.floor | >= 0 | ✓ Basement floors would be missed — consider allowing negative values if basements exist |
| Spaces.capacity | > 0 | ✓ Correct for bookable spaces |
| Bookings.booking_type | Lecture, Examination, Seminar, Workshop, Meeting, Student Activity, Administrative Event | ✓ Matches all 7 types |
| Bookings.status | Pending, Approved, Rejected, Cancelled, Checked In, Completed, No-Show | ✓ Matches all 7 statuses from lifecycle |
| Bookings.expected_participants | > 0 | ✓ Correct |
| Bookings.requested_end_time | > requested_start_time | ✓ Correct |
| Facilities.quantity | >= 1 | ✓ Reasonable |
| MaintenanceRecords.problem_type | Broken Projector, Air-Conditioning Failure, Damaged Furniture, Cleaning Issue, Network Problem, Other | ✓ Covers all listed types + Other |
| MaintenanceRecords.status | Reported, In Progress, Completed, Cancelled | ✓ Complete lifecycle |

### 3.4 Foreign Key Delete Rule Appropriateness

| FK | Rule | Justification | Assessment |
|---|---|---|---|
| Facilities.space_code → Spaces | CASCADE | Facilities are dependent on a space; if space is retired/removed, facilities are meaningless | ✓ |
| Bookings.requester_id → Users | NO ACTION | Booking history must be preserved even if user account is removed | ✓ |
| Bookings.space_code → Spaces | NO ACTION | Booking history must be preserved even if space is retired | ✓ |
| Bookings.approver_id → Users | SET NULL | Keep booking record; just lose the approver reference if staff is removed | ✓ |
| Bookings.check_in_person_id → Users | SET NULL | Same reasoning as approver | ✓ |
| MaintenanceRecords.space_code → Spaces | NO ACTION | Maintenance history must be preserved | ✓ |
| MaintenanceRecords.reporter_id → Users | NO ACTION | Maintenance history must be preserved | ✓ |
| MaintenanceRecords.assigned_staff_id → Users | SET NULL | Keep record; lose assignee reference if staff is removed | ✓ |

### 3.5 Missing Constraints Identified

| # | Missing Constraint | Impact |
|---|---|---|
| M1 | UNIQUE(building, floor, room_number) on Spaces | Could allow duplicate entries for the same physical room |
| M2 | CHECK(status IN ('Approved', 'Rejected') → decision_time IS NOT NULL) | Could have approved/rejected bookings without a decision timestamp |
| M3 | CHECK(status = 'Rejected' → rejection_reason IS NOT NULL) | Could have rejected bookings without a reason |
| M4 | CHECK(approver_id IS NOT NULL → status IN ('Approved', 'Rejected')) | Could have an approver assigned without a decision |

---

## 4. Normalization Review

| Check | Status | Finding |
|---|---|---|
| 1NF | ✓ | All attributes are atomic. No repeating groups. |
| 2NF | ✓ | All PKs are single-column; no partial dependencies possible. |
| 3NF | ✓ | No transitive dependencies found. Each non-key attribute depends only on the PK. |
| BCNF | ✓ | Every determinant is a candidate key. |

**Edge case verification**:

- **Bookings**: Could there be an FD `requester_id → department`? No — `department` is not an attribute of Bookings. The book only stores the FK. ✓
- **MaintenanceRecords**: Could there be an FD `reporter_id → department`? Same reasoning — not stored. ✓
- **Facilities**: Could `facility_name → condition` exist? No — same facility name in different spaces could have different conditions. ✓

**Verdict**: All relations are in BCNF. No normalization issues. ✓

---

## 5. Issues Identified

### 5.1 Issues to Fix (before implementation)

| ID | Severity | Relation | Issue | Recommendation |
|---|---|---|---|---|
| I1 | Medium | Spaces | UNIQUE(building, floor, room_number) is listed as a candidate key but not enforced as a constraint in the schema definition | Add UNIQUE(building, floor, room_number) in the DDL |

### 5.2 Issues to Note (not critical for logical design)

| ID | Severity | Relation | Issue | Comment |
|---|---|---|---|---|
| I2 | Low | Bookings | `decision_time` is logically dependent on `status` being Approved or Rejected, but no CHECK enforces this | Can be enforced via constraint or app logic |
| I3 | Low | Bookings | `rejection_reason` should be NOT NULL when status = Rejected | Can be enforced via constraint or app logic |
| I4 | Low | Bookings | `approver_id` should be NOT NULL when status is Approved or Rejected | Can be enforced via constraint or app logic |
| I5 | Low | Bookings | No CHECK prevents a booking from having `actual_end_time` without `actual_start_time` | Logical check-in/check-out pairing |
| I6 | Info | Spaces | `floor CHECK(floor >= 0)` may not support basement levels (e.g., B1) | Change to allow negative values if needed |

### 5.3 Business Rules Needing External Enforcement

| ID | Business Rule | Mechanism | Included in Section 5 |
|---|---|---|---|
| E1 | No overlapping approved bookings (BR3) | Trigger or app | ✓ |
| E2 | Maintenance blocks booking (BR7) | Trigger or app | ✓ |
| E3 | No overlapping active maintenance (BR9) | Trigger or app | ✓ |
| E4 | Status lifecycle sequencing (BR4) | App logic | Noted implicitly |

---

## 6. Recommendations

| Priority | Recommendation | Reason |
|---|---|---|
| **High** | Add `UNIQUE(building, floor, room_number)` to Spaces in the DDL | Prevents duplicate physical space entries |
| **Medium** | Enforce `decision_time IS NOT NULL` when `status` is Approved or Rejected via CHECK or trigger | Data integrity for business rule BR5 |
| **Medium** | Enforce `rejection_reason IS NOT NULL` when `status` is Rejected via CHECK or trigger | Data integrity for business rule BR5 |
| **Low** | Enforce `approver_id IS NOT NULL` when `status` is Approved or Rejected | Prevents orphaned decisions |
| **Low** | Consider allowing negative floor values | Accommodates basement spaces |

---

## 7. Overall Assessment

| Criteria | Result |
|---|---|
| ERD faithfully represented | ✓ All 5 entities and 8 relationships correctly mapped |
| Business rules addressed | ✓ All 10 rules covered (4 schema-level, 3 partial, 3 via external enforcement) |
| Keys appropriate | ✓ Surrogate PKs where no natural key exists; natural PK (space_code) for Spaces; email as candidate key |
| Relationships correct | ✓ All FKs on correct side (N-side), with appropriate nullability and delete rules |
| Constraints sufficient | ⚠ Minor gaps: missing UNIQUE(building, floor, room_number), conditional NOT NULLs |
| Normalization | ✓ All relations in BCNF |

**Verdict**: The logical design is **sound** and ready for implementation after addressing the one high-priority issue (I1 — add UNIQUE constraint on Spaces for the business key). The remaining issues (I2–I6) are refinements that can be handled either at the DDL stage or in application logic.

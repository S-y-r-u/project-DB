# Conceptual Design — ERD (Crow's Foot Notation) — Group G01

## 1. Entity-Relationship Diagram

```mermaid
erDiagram
    USER {
        int user_id PK
        string full_name
        string email
        string phone_number
        string role
        string department
        string account_status
    }

    SPACE {
        string space_code PK
        string space_name
        string space_type
        string building
        int floor
        string room_number
        int capacity
        string current_status
        string usage_policy
    }

    FACILITY {
        int facility_id PK
        string facility_name
        string condition
    }

    BOOKING {
        int booking_id PK
        datetime requested_start_time
        datetime requested_end_time
        string purpose_of_use
        int expected_participants
        string booking_type
        string status
        datetime decision_time
        string decision_note
        string rejection_reason
        datetime actual_start_time
        datetime actual_end_time
        string initial_condition
        string final_condition
        string usage_notes
    }

    MAINTENANCE {
        int maintenance_id PK
        string problem_description
        string problem_type
        datetime start_time
        datetime completion_time
        string status
        string result_note
    }

    USER ||--o{ BOOKING : "submits"
    USER |o--o{ BOOKING : "approves"
    USER |o--o{ BOOKING : "checks in"
    USER ||--o{ MAINTENANCE : "reports"
    USER |o--o{ MAINTENANCE : "assigned"
    SPACE ||--o{ BOOKING : "books"
    SPACE ||--o{ FACILITY : "contains"
    SPACE ||--o{ MAINTENANCE : "undergoes"
```

---

## 2. Entity Descriptions and Attributes

### 2.1 User

Represents any person who interacts with the system (students, lecturers, TAs, facility staff, department administrators, facility manager).

| Attribute | Description | Type | Constraints |
|---|---|---|---|
| user_id | Unique system-generated identifier | Integer | PK |
| full_name | Full name of the user | String | Not null |
| email | University email address | String | Unique, not null |
| phone_number | Contact phone number | String | Optional |
| role | User's role in the system | String (enum) | Not null |
| department | Academic or administrative department | String | Not null |
| account_status | Whether the account is active, suspended, or inactive | String (enum) | Not null |

### 2.2 Space

A physical room or area that can be booked.

| Attribute | Description | Type | Constraints |
|---|---|---|---|
| space_code | Unique code for the space (e.g., CS-101) | String | PK |
| space_name | Human-readable name of the space | String | Not null |
| space_type | Category of the space | String (enum) | Not null |
| building | Building where the space is located | String | Not null |
| floor | Floor number within the building | Integer | Not null |
| room_number | Room number on that floor | String | Not null |
| capacity | Maximum number of people | Integer | Not null, > 0 |
| current_status | Operational status | String (enum) | Not null |
| usage_policy | Rules governing space use | Text | Optional |

### 2.3 Facility

A piece of equipment or amenity installed in a space (e.g., projector, whiteboard, microphone, computer, livestreaming equipment, air conditioner).

| Attribute | Description | Type | Constraints |
|---|---|---|---|
| facility_id | Unique identifier | Integer | PK |
| facility_name | Name of the facility | String | Not null |
| condition | Current working condition | String | Optional |

### 2.4 Booking

A request to use a space during a specific time period, along with check-in/check-out tracking.

| Attribute | Description | Type | Constraints |
|---|---|---|---|
| booking_id | Unique identifier | Integer | PK |
| requested_start_time | Desired start date and time | DateTime | Not null |
| requested_end_time | Desired end date and time | DateTime | Not null |
| purpose_of_use | Description of the intended use | Text | Not null |
| expected_participants | Number of people expected | Integer | Not null, > 0 |
| booking_type | Category of the booking | String (enum) | Not null |
| status | Current state of the booking | String (enum) | Not null |
| decision_time | When the approval/rejection was made | DateTime | Optional |
| decision_note | Notes accompanying the decision | Text | Optional |
| rejection_reason | Reason if rejected | Text | Optional |
| actual_start_time | When the booking was checked in | DateTime | Optional |
| actual_end_time | When the booking was completed | DateTime | Optional |
| initial_condition | Space condition at check-in | Text | Optional |
| final_condition | Space condition at check-out | Text | Optional |
| usage_notes | Notes about the session | Text | Optional |

### 2.5 Maintenance

A record of maintenance work performed on a space.

| Attribute | Description | Type | Constraints |
|---|---|---|---|
| maintenance_id | Unique identifier | Integer | PK |
| problem_description | Description of the problem | Text | Not null |
| problem_type | Category of the problem | String (enum) | Not null |
| start_time | When maintenance began | DateTime | Optional |
| completion_time | When maintenance was completed | DateTime | Optional |
| status | Current state of the maintenance | String (enum) | Not null |
| result_note | Notes about the outcome | Text | Optional |

---

## 3. Relationships, Cardinalities, and Participation Constraints

| Relationship | Left Entity | Left Card. | Right Entity | Right Card. | Description |
|---|---|---|---|---|---|
| submits | USER | `\|\|` (exactly one) | BOOKING | `o{` (zero or more) | One user can submit many bookings; a booking must have exactly one requester. |
| approves | USER | `\|o` (zero or one) | BOOKING | `o{` (zero or more) | One staff member may approve/reject many bookings; a booking may have at most one approver. |
| checks in | USER | `\|o` (zero or one) | BOOKING | `o{` (zero or more) | One staff member may check in many bookings; a booking may be checked in by at most one staff member. |
| reports | USER | `\|\|` (exactly one) | MAINTENANCE | `o{` (zero or more) | One user can report many maintenance issues; a maintenance record must have exactly one reporter. |
| assigned | USER | `\|o` (zero or one) | MAINTENANCE | `o{` (zero or more) | One staff member may be assigned to many maintenance records; a maintenance record may have at most one assignee. |
| books | SPACE | `\|\|` (exactly one) | BOOKING | `o{` (zero or more) | One space may have many bookings; a booking must be for exactly one space. |
| contains | SPACE | `\|\|` (exactly one) | FACILITY | `o{` (zero or more) | One space may contain many facilities; a facility must belong to exactly one space. |
| undergoes | SPACE | `\|\|` (exactly one) | MAINTENANCE | `o{` (zero or more) | One space may have many maintenance records; a maintenance record must be for exactly one space. |

### Crow's Foot Notation Legend

| Symbol | Meaning |
|---|---|
| `\|\|` | Exactly one (mandatory participation) |
| `\|o` | Zero or one (optional participation) |
| `}o` | Zero or more (optional many) |
| `}\|` | One or more (mandatory many) |

---

## 4. Participation Constraint Summary

| Relationship | Entity | Participation | Meaning |
|---|---|---|---|
| submits | USER | Mandatory | Every booking has a non-null requester. |
| submits | BOOKING | Optional | A user may have zero bookings. |
| approves | USER | Optional | Not every user is an approver. |
| approves | BOOKING | Optional | Not every booking has been decided. |
| checks in | USER | Optional | Not every user performs check-ins. |
| checks in | BOOKING | Optional | Not every booking has been checked in. |
| reports | USER | Mandatory | Every maintenance record has a reporter. |
| reports | MAINTENANCE | Optional | A user may have reported zero issues. |
| assigned | USER | Optional | Not every user is assigned maintenance tasks. |
| assigned | MAINTENANCE | Optional | Not every record has a staff assignee. |
| books | SPACE | Mandatory | Every booking references one space. |
| books | BOOKING | Optional | A space may have zero bookings. |
| contains | SPACE | Mandatory | Every facility belongs to a space. |
| contains | FACILITY | Optional | A space may have zero facilities. |
| undergoes | SPACE | Mandatory | Every maintenance record references a space. |
| undergoes | MAINTENANCE | Optional | A space may have zero maintenance records. |

---

## 5. Traceability Map

| Entity | Traced From (in requirement analysis) |
|---|---|
| USER | Section 2 (Actors) + Section 3.1 (User attributes) + BR10 (account_status blocks requests) |
| SPACE | Section 3.2 (bookable shared spaces) + BR2 (current_status blocks booking) + BR7 (maintenance-auto status) |
| FACILITY | Section 3.3 (facilities: projector, whiteboard, etc.) |
| BOOKING | Section 3.4 (Booking Request) + BR3 (conflict prevention) + BR4 (lifecycle) + BR5 (approval recording) + BR6 (check-in/out) |
| MAINTENANCE | Section 3.5 (Maintenance Record) + BR2/BR7 (maintenance blocks booking) |

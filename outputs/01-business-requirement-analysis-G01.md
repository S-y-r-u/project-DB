# Business Requirement Analysis — Group G01

## 1. Business Purpose

The School of Computer Science manages several shared physical spaces (auditoriums, classrooms, computer laboratories, project laboratories, meeting rooms, and student workspaces) used for teaching, seminars, examinations, workshops, student projects, research activities, and academic events.

Currently, requests to use these spaces are handled manually via email, phone, or in-person communication with the school office or facility staff. Staff check spreadsheets or shared calendars to determine availability, eligibility, and maintenance status.

As the volume of classes, student projects, workshops, seminars, and events increases, the manual process has become difficult to manage. The School wants to build a database system to automate and manage:

- Space booking
- Booking approval workflows
- Usage session tracking (check-in / check-out)
- Maintenance management
- Incident reporting
- Facility utilization tracking

The main goal is to manage shared campus spaces fairly, avoid overlapping bookings, prevent the use of unavailable spaces, and preserve usage history.

---

## 2. Actors / User Roles

| Role | Description |
|---|---|
| **Student** | Submits booking requests for student activities, project work, etc. |
| **Lecturer** | Submits booking requests for lectures, examinations, seminars, etc. |
| **Teaching Assistant** | Submits booking requests for tutorials, lab sessions, etc. |
| **Facility Staff** | Reviews and approves/rejects booking requests; performs check-in and check-out; manages maintenance records. |
| **Department Administrator** | May submit or manage bookings on behalf of the department. |
| **Facility Manager** | Oversees the entire system; manages spaces, staff assignments, and policy decisions; initiates and manages maintenance records. |

---

## 3. Entities and Attributes

### 3.1 User

Represents any person who interacts with the system.

| Attribute | Description | Type / Notes |
|---|---|---|
| User ID | Unique identifier for the user | PK, system-generated |
| Full Name | Legal or preferred full name | String |
| Email | University email address | String, unique |
| Phone Number | Contact phone number | String, optional |
| Role | User role in the system | Enum: Student, Lecturer, TA, Facility Staff, Dept Admin, Facility Manager |
| Department | Academic or administrative department | String |
| Account Status | Whether the account is active, suspended, etc. | Enum (e.g., Active, Suspended, Inactive) |

### 3.2 Space

A physical room or area that can be booked.

| Attribute | Description | Type / Notes |
|---|---|---|
| Space Code | Unique identifier for the space | PK, e.g., "CS-101" |
| Space Name | Human-readable name | String |
| Space Type | Category of the space | Enum: Auditorium, Classroom, Computer Lab, Project Lab, Meeting Room, Student Workspace |
| Building | Building where the space is located | String |
| Floor | Floor number within the building | Integer |
| Room Number | Room number on that floor | String |
| Capacity | Maximum number of people the space can hold | Integer |
| Current Status | Operational status of the space | Enum: Available, In Use, Under Maintenance, Temporarily Closed, Retired |
| Usage Policy | Rules governing the use of this space | Text, optional |

### 3.3 Facility

A piece of equipment or amenity installed in a space.

| Attribute | Description | Type / Notes |
|---|---|---|
| Facility ID | Unique identifier | PK |
| Space Code | The space this facility belongs to | FK → Space |
| Facility Name | Name of the facility | String (e.g., Projector, Whiteboard, Microphone, Computer, Livestreaming Equipment, Air Conditioner) |
| Condition | Current working condition | String, optional |

### 3.4 Booking Request

A request to use a space during a specific time period.

| Attribute | Description | Type / Notes |
|---|---|---|
| Booking ID | Unique identifier | PK |
| Requester ID | The user who submitted the request | FK → User |
| Space Code | The requested space | FK → Space |
| Requested Start Time | Desired start date and time | DateTime |
| Requested End Time | Desired end date and time | DateTime |
| Purpose of Use | Description of what the space will be used for | Text |
| Expected Participants | Number of people expected | Integer |
| Booking Type | Category of the booking | Enum: Lecture, Examination, Seminar, Workshop, Meeting, Student Activity, Administrative Event |
| Status | Current state of the booking | Enum: Pending, Approved, Rejected, Cancelled, Checked In, Completed, No-Show |
| Approver ID | Staff member who approved/rejected | FK → User, nullable |
| Decision Time | When the approval/rejection decision was made | DateTime, nullable |
| Decision Note | Notes accompanying the decision | Text, nullable |
| Rejection Reason | Reason if booking was rejected | Text, nullable |
| Actual Start Time | When the booking was checked in | DateTime, nullable |
| Check-In Person ID | Who performed the check-in | FK → User, nullable |
| Initial Condition | Condition of the space at check-in | Text, nullable |
| Actual End Time | When the booking was completed | DateTime, nullable |
| Final Condition | Condition of the space at check-out | Text, nullable |
| Usage Notes | Any notes about the session | Text, nullable |

### 3.5 Maintenance Record

A record of maintenance work performed on a space.

| Attribute | Description | Type / Notes |
|---|---|---|
| Maintenance ID | Unique identifier | PK |
| Space Code | The space being maintained | FK → Space |
| Reporter ID | The user who reported the problem | FK → User |
| Assigned Staff ID | Staff member assigned to fix the issue | FK → User, nullable |
| Problem Description | Description of the problem | Text |
| Problem Type | Category of the problem | Enum: Broken Projector, AC Failure, Damaged Furniture, Cleaning Issue, Network Problem, Other |
| Start Time | When maintenance began | DateTime, nullable |
| Completion Time | When maintenance was completed | DateTime, nullable |
| Status | Current status of the maintenance | Enum: Reported, In Progress, Completed, Cancelled |
| Result Note | Notes about the maintenance outcome | Text, nullable |

---

## 4. Relationships and Cardinalities

| Relationship | Entity A | Entity B | Cardinality | Description |
|---|---|---|---|---|
| Submits | User | Booking Request | 1 : N | One user can submit many booking requests. A booking request belongs to exactly one user. |
| Books | Space | Booking Request | 1 : N | One space can receive many booking requests. A booking request is for exactly one space. |
| Approves | User (Staff) | Booking Request | 1 : N | One staff member can approve/reject many booking requests. A booking request may be approved/rejected by at most one staff member. |
| Contains | Space | Facility | 1 : N | One space can contain many facilities. A facility belongs to exactly one space. |
| Undergoes | Space | Maintenance Record | 1 : N | One space can have many maintenance records. A maintenance record is for exactly one space. |
| Reports | User | Maintenance Record | 1 : N | One user can report many maintenance issues. A maintenance record is reported by exactly one user. |
| Assigned To | User (Staff) | Maintenance Record | 1 : N | One staff member can be assigned to many maintenance records. A maintenance record may be assigned to at most one staff member. |
| Checks In | User (Staff) | Booking Request | 1 : N | One staff member can check in many bookings. A booking may be checked in by at most one staff member. |

---

## 5. Business Rules

1. **Unique User Identity**: Each user must have a university account. User ID is unique across the system.

2. **Space Status Prevents Booking**: A space whose `Current Status` is `Under Maintenance`, `Temporarily Closed`, or `Retired` cannot be booked. A space is automatically marked as Under Maintenance in the Space table whenever a Maintenance Record is created or updated with a status of Reported or In Progress.

3. **Conflict Prevention**: The same space cannot have two approved bookings with overlapping time periods. The system must reject or flag any new booking that overlaps an existing approved booking for the same space. 

4. **Booking Status Lifecycle**:
   - A newly submitted booking starts as `Pending`.
   - A pending booking may be `Approved` or `Rejected` by facility staff/manager.
   - An approved booking may be `Cancelled` (by requester or staff).
   - On arrival, an approved booking is `Checked In`.
   - After the session ends, a checked-in booking is `Completed`.
   - If the requester does not show up, the booking is marked `No-Show`.

5. **Approval Recording**: When a booking is approved or rejected, the system must record the approving staff member's ID, the decision time, and a decision note. If rejected, a rejection reason must be stored.

6. **Check-In/Check-Out Recording**: On check-in, the system records actual start time, who checked in, and the initial condition of the space. On completion, it records actual end time, final condition, and usage notes.

7. **Request Booking Block by Maintenance Status**: A space that has an active (non-completed) maintenance record with status `In Progress` or `Reported` is considered under maintenance and cannot accept booking requests. When a Maintenance Record status is updated to Completed or Cancelled, the system checks if any other active maintenance records exist for that space. If none exist, the Space.Current Status automatically reverts to Available.


8. **Historical Retention**: The system must keep historical records of all past bookings and maintenance activities (no hard deletion of completed records).

9. **Role-Based Actions**: Only Facility Staff and Facility Manager roles can approve/reject bookings, perform check-in/check-out, and manage maintenance records.

10. **Request Booking Block by User Status**: Users with a "Suspended" or "Inactive" account status cannot submit booking requests.

---

## 6. Open Questions

| # | Question | Suggested Source |
|---|---|---|
| Q1 | Should there be a recurring booking feature (e.g., weekly lecture slot for a semester)? | Clarify with Facility Manager |
| Q2 | What is the maximum advance notice period for booking a space? | Clarify with Facility Manager |
| Q3 | Should the system support waitlisting for popular spaces? | Clarify with Facility Manager |
| Q4 | Are there any capacity restrictions beyond the raw number (e.g., fire safety limits)? | Clarify with School Safety Officer |
| Q5 | Should the system integrate with the university's existing authentication (SSO/LDAP)? | Clarify with IT |
| Q6 | What constitutes a "no-show"? A specific grace period after the requested start time? | Clarify with Facility Manager |
| Q7 | Can a booking request span multiple days, or is it limited to a single day? | Clarify with Facility Manager |
| Q8 | Should there be a priority system (e.g., lecturers have priority over student groups for certain spaces)? | Clarify with Facility Manager |

---

## 7. Assumptions

| # | Assumption |
|---|---|
| A1 | Each booking involves exactly one space and one requester (no multi-space or multi-requester bookings). |
| A2 | Facilities are tracked as a simple list per space; no separate inventory management or procurement system is needed. |
| A3 | A booking request is for a contiguous block of time (not multiple non-overlapping segments). |
| A4 | The system does not handle billing or cost allocation for space usage. |
| A5 | Maintenance records are informational; no automated scheduling or resource allocation is required. |
| A6 | User authentication and authorization are handled externally by the university; the system only stores user identity and role information. |
| A7 | Bookings cannot be modified after submission; they must be cancelled and re-submitted. |

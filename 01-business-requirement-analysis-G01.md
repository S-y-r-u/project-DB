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
Each user must have a university account.

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

### 3.5 Booking Approval
Records the approval workflow details for a specific Booking Request.

| Attribute | Description | Type / Notes |
|---|---|---|
| Approval ID | Unique identifier | PK |
| Booking ID | The associated booking request | FK → Booking Request |
| Approver ID | Staff member who approved/rejected | FK → User |
| Decision Time | When the approval/rejection decision was made | DateTime |
| Decision | The outcome of the review | Enum: Approved, Rejected |
| Decision Note | Notes accompanying the decision | Text, nullable |
| Rejection Reason | Reason if booking was rejected | Text, nullable |

### 3.6 Usage Session
Captures the actual physical usage of the space (check-in and check-out).

| Attribute | Description | Type / Notes |
|---|---|---|
| Session ID | Unique identifier | PK |
| Booking ID | The associated booking request | FK → Booking Request |
| Check-In Person ID | Who performed the check-in | FK → User |
| Actual Start Time | When the booking was checked in | DateTime |
| Initial Condition | Condition of the space at check-in | Text |
| Actual End Time | When the booking was completed | DateTime, nullable |
| Final Condition | Condition of the space at check-out | Text, nullable |
| Usage Notes | Any notes about the session | Text, nullable |

### 3.7 Maintenance Record
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
| Requires | Booking Request | Booking Approval | 1 : 0..1 | A booking request may have one approval record (if processed). An approval record belongs to exactly one booking request. |
| Decides | User (Staff) | Booking Approval | 1 : N | A staff member can create many approval records. An approval record is made by exactly one staff member. |
| Tracks | Booking Request | Usage Session | 1 : 0..1 | A checked-in booking request has one usage session. A usage session maps to exactly one booking request. |
| Checks In | User (Staff) | Usage Session | 1 : N | One staff member can check in many sessions. A session is checked in by exactly one staff member. |
| Contains | Space | Facility | 1 : N | One space can contain many facilities. A facility belongs to exactly one space. |
| Undergoes | Space | Maintenance Record | 1 : N | One space can have many maintenance records. A maintenance record is for exactly one space. |
| Reports | User | Maintenance Record | 1 : N | One user can report many maintenance issues. A maintenance record is reported by exactly one user. |
| Assigned To | User (Staff) | Maintenance Record | 1 : N | One staff member can be assigned to many maintenance records. |

---

## 5. Traceability Matrix

| Entity/Attribute | Source Requirement (Paragraph/Sentence) |
|---|---|
| **User** (ID, Name, Email, Phone, Role, Dept, Status) | "The system stores basic user information, including user ID, full name, email, phone number, role, department, and account status." |
| **Space** (Code, Name, Type, Building, Floor, Room, Capacity, Status, Policy) | "For each space, the system stores a unique space code, space name, space type, building, floor, room number, capacity, current status, and usage policy." |
| **Facility** (Name) | "...projector, whiteboard, microphone, computer, livestreaming equipment, or air conditioner. The system should store the list of facilities..." |
| **Booking Request** (Start/End Time, Purpose, Expected Participants) | "Users can submit booking requests by selecting a space, requested start time, requested end time, purpose of use, and expected number of participants." |
| **Booking Request** (Booking Type) | "A booking may be for a lecture, examination, seminar, workshop, meeting, student activity, or administrative event." |
| **Booking Request** (Status) | "Each booking request has a status, such as pending, approved, rejected, cancelled, checked in, completed, or no-show." |
| **Booking Approval** | "When a booking is approved or rejected, the system records the staff member who made the decision, the decision time, and a decision note. If the booking is rejected, the rejection reason should be stored." |
| **Usage Session** (Check-in/out details) | "The system records the actual start time, the person who checked in the booking, and the initial condition of the space... actual end time, the final condition of the space, and any usage notes." |

---

## 6. Business Rules

1. **Unique User Identity**: Each user must have a university account. User ID is unique across the system.
2. **Unique Space Identity**: Each space must have a space code. Space code is unique across the system.
3. **Unavailable spaces cannot be booked**: A space that is under maintenance, closed, or retired cannot be booked.
4. **Conflict Prevention**: The same space cannot have two approved bookings with overlapping time periods. The system must reject or flag any new booking that overlaps an existing approved booking for the same space.
5. **Capacity Enforcement**: The expected number of participants in a booking request should not exceed the space's capacity.
6. **Booking Status Lifecycle**:
   - A newly submitted booking starts as `Pending`.
   - A pending booking may be `Approved` or `Rejected` by facility staff/manager.
   - An approved booking may be `Cancelled` (by requester or staff).
   - On arrival, an approved booking is `Checked In`.
   - After the session ends, a checked-in booking is `Completed`.
   - If the requester does not show up, the booking is marked `No-Show`.
7. **Approval Recording**: When a booking is approved or rejected, an Approval record must capture the approving staff member's ID, the decision time, and a decision note. If rejected, a rejection reason must be stored.
8. **Check-In/Check-Out Recording**: On check-in, a Usage Session record captures actual start time, who checked in, and the initial condition of the space. On completion, it records actual end time, final condition, and usage notes.
9. **Historical Retention**: The system must keep historical records of all past bookings and maintenance activities.
10. **Role-Based Actions**: Only Facility Staff and Facility Manager roles can approve/reject bookings, perform check-in/check-out, and manage maintenance records.
11. **Time ordering**: Requested start time must be before requested end time. Actual start time must be before actual end time.
12. **Cancellation constraint**: A booking can only be cancelled while in pending or approved status.

---

## 7. Design Rules & Inferences

1. **Maintenance Status Synchronization**: The requirement states that "A space under maintenance cannot be booked". How a space enters the "Under Maintenance" status is a design decision. It is recommended that a space's `Current Status` is derived from or automatically updated by active Maintenance Records (Reported/In Progress).
2. **Request Booking Block by Maintenance Status**: A space that has an active (non-completed) maintenance record with status `In Progress` or `Reported` is considered under maintenance and cannot accept booking requests.

---

## 8. Open Questions

| # | Question | Suggested Source |
|---|---|---|
| Q1 | Should there be a recurring booking feature (e.g., weekly lecture slot for a semester)? | Clarify with Facility Manager |
| Q2 | What is the maximum advance notice period for booking a space? | Clarify with Facility Manager |
| Q3 | Should the system support waitlisting for popular spaces? | Clarify with Facility Manager |
| Q4 | Are there any capacity restrictions beyond the raw number (e.g., fire safety limits)? | Clarify with School Safety Officer |
| Q5 | What constitutes a "no-show"? A specific grace period after the requested start time? | Clarify with Facility Manager |
| Q6 | Can a booking request span multiple days, or is it limited to a single day? | Clarify with Facility Manager |
| Q7 | Which roles/users can bypass booking approval? The requirement implies some bookings "may require approval" but does not define the exceptions. | Clarify with Facility Manager |

---

## 9. Assumptions

| # | Assumption |
|---|---|
| A1 | Each booking involves exactly one space and one requester (no multi-space or multi-requester bookings). |
| A2 | Facilities are tracked as a simple list per space; no separate inventory management or procurement system is needed. |
| A3 | A booking request is for a contiguous block of time (not multiple non-overlapping segments). |
| A4 | Bookings cannot be modified after submission; they must be cancelled and re-submitted. |
| A5 | Maintenance syncing: Any automatic setting of a Space's status to 'Under Maintenance' when a Maintenance Record is created is an implemented design mechanism, not a strict business rule. |

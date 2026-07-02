USE SpaceBookingDB;
GO

INSERT INTO Facilities (space_code, facility_name, condition)
VALUES
    (N'CS-102', N'Projector',            N'Good');
GO

SELECT * FROM Bookings;
GO

UPDATE Bookings
SET status = 'Approved'
WHERE booking_id = 5
GO

INSERT INTO Bookings (requester_id, space_code,
    requested_start_time, requested_end_time,
    purpose_of_use, expected_participants, booking_type, status,
    approver_id, decision_time, decision_note, rejection_reason,
    actual_start_time, check_in_person_id, initial_condition,
    actual_end_time, final_condition, usage_notes)
VALUES
    (1,        
     N'CS-101',
     '2026-06-23 12:00:00', '2026-06-23 11:00:00',
     N'CS301 — Introduction to Database Systems lecture',
     180, N'Lecture', N'Completed',
     4,        
     '2026-06-16 10:00:00',
     N'Approved — standard lecture slot.',
     NULL,
     '2026-06-23 08:55:00', 3,  
     N'All equipment functional. Room clean and ready.',
     '2026-06-23 11:10:00', 
     N'Projector off. Whiteboard cleaned. Room tidy.',
     N'180 students attended. Finished on time.');
GO

-- 11:50:30 PM
-- Started executing query at  Line 1
-- Commands completed successfully.
-- 11:50:30 PM
-- Started executing query at  Line 3
-- Msg 547, Level 16, State 0, Line 4
-- The INSERT statement conflicted with the FOREIGN KEY constraint "FK_Facilities_SpaceCode". The conflict occurred in database "SpaceBookingDB", table "dbo.Spaces", column 'space_code'.
-- The statement has been terminated.
-- 11:50:30 PM
-- Started executing query at  Line 8
-- (11 rows affected)
-- 11:50:30 PM
-- Started executing query at  Line 11
-- Msg 547, Level 16, State 0, Line 12
-- The UPDATE statement conflicted with the CHECK constraint "CK_Bookings_Decision". The conflict occurred in database "SpaceBookingDB", table "dbo.Bookings".
-- The statement has been terminated.
-- 11:50:30 PM
-- Started executing query at  Line 16
-- Msg 547, Level 16, State 0, Line 17
-- The INSERT statement conflicted with the CHECK constraint "CK_Bookings_TimeRange". The conflict occurred in database "SpaceBookingDB", table "dbo.Bookings".
-- The statement has been terminated.
-- Total execution time: 00:00:00.039
# Student Course & Marks Management System

**Course:** C11665 - DPR400210: Database Programming
**Instructor:** Eric Maniraguha
**Assignment:** Group Assignment III — Design and Implementation of a Simple Database Application Using PL/SQL
**Institution:** UNILAK

## Group Members
- 31603/2025
- 26932/2024
- 32967/2025
- 
- 

## Problem Statement
UNILAK needs a simple system to track students, the courses they enroll in, and the marks they receive, so instructors can compute averages, rank students within a course, and validate marks automatically instead of doing it manually.

## Database Schema
- **students** — student_id, first_name, last_name, email
- **courses** — course_id, course_name, credits
- **marks** — mark_id, student_id (FK), course_id (FK), score

## PL/SQL Concepts Implemented
| Concept | Object Name | Purpose |
|---|---|---|
| Function | `get_student_average` | Returns a student's average score across all courses |
| Stored Procedure | `add_mark` | Inserts a new mark, or updates it if one already exists for that student/course, with score validation (0–100) |
| Anonymous Block | (Step 5 in script) | Calls the procedure and function together, prints a report using `DBMS_OUTPUT` |
| Window Function | `RANK() OVER (PARTITION BY ...)` | Ranks students within each course by score, alongside each course's average |

## How to Run
1. Open `student_marks_project.sql` in Oracle SQL Developer (or SQL*Plus).
2. Run the entire script (Run Script / F5) — it drops old tables if they exist, recreates the schema, loads sample data, creates the function/procedure, runs the anonymous block, and runs the window function query.
3. Ensure `SET SERVEROUTPUT ON` is enabled to see the anonymous block's output.

## File Structure
- `student_marks_project.sql` — full schema, sample data, and all PL/SQL objects, in one script.

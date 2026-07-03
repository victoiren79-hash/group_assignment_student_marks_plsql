/*
====================================================================
  Group Assignment III - Database Programming (DPR400210)
  Project: Student Course & Marks Management System
  Instructor: Eric Maniraguha

  PROBLEM DEFINITION:
  UNILAK needs a simple system to track students, the courses they
  enroll in, and the marks they receive, so instructors can compute
  averages, rank students within a course, and validate marks
  automatically instead of doing it manually.

  This script demonstrates:
    1. Relational schema design (3 tables, FK relationships)
    2. Anonymous PL/SQL Block
    3. Stored Procedure
    4. Function
    5. Window Function
====================================================================
*/

-- ====================================================================
-- STEP 0: CLEAN SLATE (safe to re-run this script from scratch)
-- ====================================================================
BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE marks CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE courses CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE students CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

-- ====================================================================
-- STEP 1: SCHEMA DESIGN
-- ====================================================================

-- Students table
CREATE TABLE students (
    student_id      NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name      VARCHAR2(50)  NOT NULL,
    last_name       VARCHAR2(50)  NOT NULL,
    email           VARCHAR2(100) UNIQUE
);

-- Courses table
CREATE TABLE courses (
    course_id       NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    course_name     VARCHAR2(100) NOT NULL,
    credits         NUMBER DEFAULT 3
);

-- Marks table (junction table: student <-> course, with a score)
CREATE TABLE marks (
    mark_id         NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    student_id      NUMBER NOT NULL REFERENCES students(student_id),
    course_id       NUMBER NOT NULL REFERENCES courses(course_id),
    score           NUMBER(5,2) CHECK (score BETWEEN 0 AND 100),
    CONSTRAINT uq_student_course UNIQUE (student_id, course_id)
);

-- ====================================================================
-- STEP 2: SAMPLE DATA
-- ====================================================================

INSERT INTO students (first_name, last_name, email) VALUES ('Aline', 'Uwase', 'aline.uwase@unilak.ac.rw');
INSERT INTO students (first_name, last_name, email) VALUES ('Eric', 'Habimana', 'eric.habimana@unilak.ac.rw');
INSERT INTO students (first_name, last_name, email) VALUES ('Divine', 'Mukamana', 'divine.mukamana@unilak.ac.rw');
INSERT INTO students (first_name, last_name, email) VALUES ('Jean', 'Bosco', 'jean.bosco@unilak.ac.rw');
INSERT INTO students (first_name, last_name, email) VALUES ('Grace', 'Iradukunda', 'grace.iradukunda@unilak.ac.rw');

INSERT INTO courses (course_name, credits) VALUES ('Database Programming', 4);
INSERT INTO courses (course_name, credits) VALUES ('Data Structures', 3);
INSERT INTO courses (course_name, credits) VALUES ('Web Development', 3);

-- Marks (student_id / course_id values follow insert order above: 1-5 students, 1-3 courses)
INSERT INTO marks (student_id, course_id, score) VALUES (1, 1, 88);
INSERT INTO marks (student_id, course_id, score) VALUES (1, 2, 75);
INSERT INTO marks (student_id, course_id, score) VALUES (2, 1, 92);
INSERT INTO marks (student_id, course_id, score) VALUES (2, 3, 67);
INSERT INTO marks (student_id, course_id, score) VALUES (3, 1, 55);
INSERT INTO marks (student_id, course_id, score) VALUES (3, 2, 81);
INSERT INTO marks (student_id, course_id, score) VALUES (4, 1, 73);
INSERT INTO marks (student_id, course_id, score) VALUES (4, 3, 90);
INSERT INTO marks (student_id, course_id, score) VALUES (5, 1, 64);
INSERT INTO marks (student_id, course_id, score) VALUES (5, 2, 58);

COMMIT;

-- ====================================================================
-- STEP 3: FUNCTION
-- Returns the average score of a given student across all courses
-- ====================================================================

CREATE OR REPLACE FUNCTION get_student_average (
    p_student_id IN students.student_id%TYPE
) RETURN NUMBER
IS
    v_avg NUMBER(5,2);
BEGIN
    SELECT AVG(score)
    INTO v_avg
    FROM marks
    WHERE student_id = p_student_id;

    RETURN NVL(v_avg, 0);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;
END get_student_average;
/

-- ====================================================================
-- STEP 4: STORED PROCEDURE
-- Inserts a new mark for a student in a course, with validation.
-- If the student already has a mark for that course, it updates it
-- instead of failing (uses the UNIQUE constraint we defined above).
-- ====================================================================

CREATE OR REPLACE PROCEDURE add_mark (
    p_student_id IN marks.student_id%TYPE,
    p_course_id  IN marks.course_id%TYPE,
    p_score      IN marks.score%TYPE
)
IS
    v_count NUMBER;
BEGIN
    -- Basic validation
    IF p_score < 0 OR p_score > 100 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Score must be between 0 and 100.');
    END IF;

    SELECT COUNT(*) INTO v_count
    FROM marks
    WHERE student_id = p_student_id AND course_id = p_course_id;

    IF v_count > 0 THEN
        UPDATE marks
        SET score = p_score
        WHERE student_id = p_student_id AND course_id = p_course_id;

        DBMS_OUTPUT.PUT_LINE('Existing mark updated for student ' || p_student_id ||
                              ' in course ' || p_course_id || ' -> ' || p_score);
    ELSE
        INSERT INTO marks (student_id, course_id, score)
        VALUES (p_student_id, p_course_id, p_score);

        DBMS_OUTPUT.PUT_LINE('New mark inserted for student ' || p_student_id ||
                              ' in course ' || p_course_id || ' -> ' || p_score);
    END IF;

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error in add_mark: ' || SQLERRM);
        RAISE;
END add_mark;
/

-- ====================================================================
-- STEP 5: ANONYMOUS BLOCK
-- Demonstrates calling the procedure and function together,
-- and prints a small report to the console.
-- ====================================================================

SET SERVEROUTPUT ON;

DECLARE
    v_avg NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Adding a new mark for student 3 in course 3 ---');
    add_mark(p_student_id => 3, p_course_id => 3, p_score => 84);

    DBMS_OUTPUT.PUT_LINE('--- Calculating average for each student ---');
    FOR rec IN (SELECT student_id, first_name, last_name FROM students ORDER BY student_id) LOOP
        v_avg := get_student_average(rec.student_id);
        DBMS_OUTPUT.PUT_LINE(rec.first_name || ' ' || rec.last_name || ' -> Average: ' || v_avg);
    END LOOP;
END;
/

-- ====================================================================
-- STEP 6: WINDOW FUNCTION
-- Ranks students within each course by score (highest first),
-- and also shows each course's average score for comparison.
-- ====================================================================

SELECT
    c.course_name,
    s.first_name || ' ' || s.last_name AS student_name,
    m.score,
    RANK() OVER (PARTITION BY m.course_id ORDER BY m.score DESC) AS rank_in_course,
    ROUND(AVG(m.score) OVER (PARTITION BY m.course_id), 2) AS course_avg
FROM marks m
JOIN students s ON s.student_id = m.student_id
JOIN courses c ON c.course_id = m.course_id
ORDER BY c.course_name, rank_in_course;

-- ====================================================================
-- BONUS QUICK CHECKS (optional, useful for the presentation demo)
-- ====================================================================

-- Call the function directly
SELECT get_student_average(1) AS aline_average FROM dual;

-- View all marks with names
SELECT s.first_name, s.last_name, c.course_name, m.score
FROM marks m
JOIN students s ON s.student_id = m.student_id
JOIN courses c ON c.course_id = m.course_id
ORDER BY s.student_id;

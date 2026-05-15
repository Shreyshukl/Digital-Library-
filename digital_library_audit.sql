-- ================================================
-- Project  : Digital Library Audit
-- Author   : Shrey Shukla
-- Year     : 2026
-- Purpose  : Track book loans and generate audit
--            reports for a community college
-- ================================================

CREATE DATABASE IF NOT EXISTS DigitalLibrary;
USE DigitalLibrary;

-- ================================================
-- SECTION 1 : TABLE CREATION (DDL)
-- ================================================

-- Table 1: Students
-- Stores information about each student
CREATE TABLE IF NOT EXISTS Students (
    student_id   INT          PRIMARY KEY AUTO_INCREMENT,
    name         VARCHAR(100) NOT NULL,
    email        VARCHAR(100) UNIQUE NOT NULL,
    phone        VARCHAR(15),
    joined_date  DATE         NOT NULL
);

-- Table 2: Books
-- Stores information about each book in the library
CREATE TABLE IF NOT EXISTS Books (
    book_id      INT          PRIMARY KEY AUTO_INCREMENT,
    title        VARCHAR(200) NOT NULL,
    author       VARCHAR(100) NOT NULL,
    category     VARCHAR(50)  NOT NULL,
    total_copies INT          DEFAULT 1
);

-- Table 3: IssuedBooks
-- Tracks which student borrowed which book and when
CREATE TABLE IF NOT EXISTS IssuedBooks (
    issue_id     INT  PRIMARY KEY AUTO_INCREMENT,
    student_id   INT  NOT NULL,
    book_id      INT  NOT NULL,
    issue_date   DATE NOT NULL,
    return_date  DATE DEFAULT NULL,

    -- Links to Students and Books tables
    FOREIGN KEY (student_id) REFERENCES Students(student_id),
    FOREIGN KEY (book_id)    REFERENCES Books(book_id)
);

-- ================================================
-- SECTION 2 : SAMPLE DATA (DML)
-- ================================================

-- Adding Students
INSERT INTO Students (name, email, phone, joined_date) VALUES
('Rahul Sharma',  'rahul@email.com',   '9876543210', '2022-06-01'),
('Priya Patel',   'priya@email.com',   '9876543211', '2021-03-15'),
('Amit Singh',    'amit@email.com',    '9876543212', '2023-01-10'),
('Sneha Verma',   'sneha@email.com',   '9876543213', '2020-08-20'),
('Rohan Gupta',   'rohan@email.com',   '9876543214', '2019-11-05'),
('Kavya Nair',    'kavya@email.com',   '9876543215', '2023-05-18'),
('Arjun Mehta',   'arjun@email.com',   '9876543216', '2022-09-22'),
('Deepika Rao',   'deepika@email.com', '9876543217', '2021-07-30');

-- Adding Books
INSERT INTO Books (title, author, category, total_copies) VALUES
('The Alchemist',           'Paulo Coelho',     'Fiction',     3),
('A Brief History of Time', 'Stephen Hawking',  'Science',     2),
('Sapiens',                 'Yuval Noah Harari','History',     2),
('Atomic Habits',           'James Clear',      'Self-Help',   4),
('Harry Potter',            'J.K. Rowling',     'Fiction',     5),
('Python Crash Course',     'Eric Matthes',     'Technology',  3),
('The Art of War',          'Sun Tzu',          'History',     2),
('Thinking Fast and Slow',  'Daniel Kahneman',  'Science',     2);

-- Adding Issued Books
-- (some overdue, some returned, some recent, one old/inactive)
INSERT INTO IssuedBooks (student_id, book_id, issue_date, return_date) VALUES
-- Overdue: issued more than 14 days ago, NOT returned yet
(1, 1, CURDATE() - INTERVAL 20 DAY, NULL),
(2, 3, CURDATE() - INTERVAL 30 DAY, NULL),
(3, 5, CURDATE() - INTERVAL 16 DAY, NULL),

-- Returned on time
(4, 2, CURDATE() - INTERVAL 10 DAY, CURDATE() - INTERVAL 3 DAY),
(5, 4, CURDATE() - INTERVAL 5  DAY, CURDATE() - INTERVAL 1 DAY),

-- Recently issued, not yet overdue
(6, 6, CURDATE() - INTERVAL 3  DAY, NULL),
(7, 7, CURDATE() - INTERVAL 1  DAY, NULL),

-- Very old record — used to test inactive student cleanup
(8, 8, CURDATE() - INTERVAL 4 YEAR,
        CURDATE() - INTERVAL 4 YEAR + INTERVAL 7 DAY);

-- ================================================
-- SECTION 3 : ANALYTICAL QUERIES (REPORTS)
-- ================================================

-- -----------------------------------------------
-- REPORT 1: Overdue Books — Penalty Report
-- Find all students who have NOT returned a book
-- and their issue date was more than 14 days ago
-- -----------------------------------------------
SELECT
    s.student_id,
    s.name                             AS student_name,
    s.email,
    b.title                            AS book_title,
    ib.issue_date,
    DATEDIFF(CURDATE(), ib.issue_date) AS days_overdue,
    DATEDIFF(CURDATE(), ib.issue_date)
        - 14                           AS penalty_days
FROM
    IssuedBooks ib
JOIN Students s ON ib.student_id = s.student_id
JOIN Books    b ON ib.book_id    = b.book_id
WHERE
    ib.return_date IS NULL
    AND DATEDIFF(CURDATE(), ib.issue_date) > 14
ORDER BY
    days_overdue DESC;

-- -----------------------------------------------
-- REPORT 2: Popularity Index
-- Which book category is borrowed the most?
-- -----------------------------------------------
SELECT
    b.category,
    COUNT(ib.issue_id) AS total_borrows
FROM
    IssuedBooks ib
JOIN Books b ON ib.book_id = b.book_id
GROUP BY
    b.category
ORDER BY
    total_borrows DESC;

-- -----------------------------------------------
-- REPORT 3: Inactive Student Cleanup
-- Step 1 — PREVIEW who will be deleted (safe check)
-- Step 2 — DELETE those inactive accounts
-- -----------------------------------------------

-- Step 1: Preview before deleting
SELECT
    s.student_id,
    s.name,
    s.email,
    MAX(ib.issue_date) AS last_borrow_date
FROM
    Students s
JOIN IssuedBooks ib ON s.student_id = ib.student_id
GROUP BY
    s.student_id, s.name, s.email
HAVING
    MAX(ib.issue_date) < CURDATE() - INTERVAL 3 YEAR;

-- Step 2: Delete inactive students
-- Wrapped in subquery to avoid MySQL safe-update restriction
DELETE FROM Students
WHERE student_id IN (
    SELECT student_id FROM (
        SELECT s.student_id
        FROM   Students s
        JOIN   IssuedBooks ib ON s.student_id = ib.student_id
        GROUP  BY s.student_id
        HAVING MAX(ib.issue_date) < CURDATE() - INTERVAL 3 YEAR
    ) AS inactive
);
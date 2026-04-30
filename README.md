# Digital Library Audit System

## Author
Shrey Shukla  
2026

---

## Overview
A SQL-based backend system designed to manage and audit a digital library.

This project simulates a real-world library system that tracks:
- Student records
- Book inventory
- Book issuance and returns
- Analytical audit reports

---

## Key Features

### 1. Overdue Book Detection
- Identifies students with overdue books
- Calculates delay and penalty days

### 2. Book Popularity Analysis
- Determines most borrowed categories
- Useful for inventory decisions

### 3. Inactive Student Cleanup
- Detects students inactive for more than 3 years
- Includes safe preview before deletion

---

## Database Design

### Tables
- Students
- Books
- IssuedBooks

### Relationships
- One-to-Many: Students to IssuedBooks
- One-to-Many: Books to IssuedBooks

---

## Technologies Used
- SQL (MySQL)
- Relational Database Design
- Joins, Aggregations, Subqueries

---

## How to Run

1. Open MySQL Workbench  
2. Open the file: digital_library_audit.sql  
3. Execute the full script  
4. Run SELECT queries to view outputs  

---
## Learning Outcomes
- Practical database design
- Writing efficient SQL queries
- Using joins and aggregations
- Building analytical reports

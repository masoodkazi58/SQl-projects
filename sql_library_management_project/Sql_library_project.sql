SELECT * FROM books;
SELECT * FROM branch;
SELECT * FROM employees;
SELECT * FROM issued_status;
SELECT * FROM return_status;
SELECT * FROM members;


--  Task. Create a New Book Record -- "978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')"

INSERT INTO books(isbn, book_title, category, rental_price, status, author, publisher)
VALUES
('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.');
SELECT * FROM books;

-- Task 1: Retrieve All Books Issued by a Specific Employee
-- Objective: Select all books issued by the employee with emp_id = 'E101'.
select issued_book_name from issued_status 
where issued_emp_id = 'E101'

-- Task 2: List Members Who Have Issued More Than One Book 
-- Objective: Use GROUP BY to find members who have issued more than one book.
select issued_member_id,count(issued_id) from issued_status
group by 1

-- Task 3: Create Summary Tables: Used CTAS to generate new tables based on query results 
-- each book and total book_issued_cnt**
select b.isbn,b.book_title,count(issued_id) from books b
join issued_status ist on b.isbn = ist.issued_book_isbn
group by 1,2

-- Task 4: Find Total Rental Income by Category:
select category,sum(rental_price),count(*) as c from books b
join issued_status iss on b.isbn = iss.issued_book_isbn
group by 1
order by 3 desc;

-- Task 5 List Members Who Registered in the Last 180 Days:
select * from members
where reg_date >= (select max(reg_date) - 180 from members)

-- task 6) List Employees with Their Branch Manager's Name and their branch details:
select e.emp_name,e.emp_id,e2.emp_name as manager_name,b.manager_id from employees e
join branch b on e.branch_id = b.branch_id
join employees e2 on e2.emp_id = b.manager_id;


-- Task 6: Retrieve the List of Books Not Yet Returned
select distinct issued_book_name,issued_id from issued_status
where issued_id not in (select issued_id from return_status);


---- ADVANCE SQL OPERATION
-- Task : Identify Members with Overdue Books
-- Write a query to identify members who have overdue books (assume a 30-day return period). 
-- Display the member's_id, member's name, book title, issue date, and days overdue.
select m.member_id,m.member_name,b.book_title,iss.issued_date,
((select max(issued_date) from issued_status)- iss.issued_date ) AS over_dues_days
from members m
join issued_status iss on m.member_id = iss.issued_member_id
join books b on b.isbn = iss.issued_book_isbn
left join return_status rs on iss.issued_id = rs.issued_id	
where ((select max(issued_date) from issued_status) - iss.issued_date) > 30 

-- Task 14: Update Book Status on Return
-- Write a query to update the status of books in the books table to "Yes" when they are returned 
-- (based on entries in the return_status table)

create or replace procedure add_return_records(p_return_id varchar(10),p_issued_id VARCHAR(30),p_book_quality VARCHAR(15))	
language plpgsql
as $$
declare
 v_isbn varchar(50);
 v_book_name VARCHAR(80); 
 
begin

	insert into return_status(return_id,issued_id,return_date,book_quality)
	VALUES
	(p_return_id,p_issued_id,current_date,p_book_quality);
 
	select issued_book_isbn,issued_book_name 
	into v_isbn,v_book_name
	from issued_status where issued_id = p_issued_id;
 
	UPDATE books 
	set status = 'yes'
	where isbn = v_isbn;
	
	RAISE NOTICE 'thank you for returning the book:  %', v_book_name;

end;
$$
	 	
CALL add_return_records('RS138','IS135','GOOD');

-- Task 15: Branch Performance Report
-- Create a query that generates a performance report for each branch, showing the number of books issued, 
-- the number of books returned, and the total revenue generated from book rentals.
SELECT * FROM branch;
SELECT * FROM issued_status;
SELECT * from return_status;

CREATE TABLE branch_report as
SELECT br.branch_id,br.manager_id,count(ist.issued_id) as number_of_book_issued,count(rs.return_id) as number_of_book_returned,sum(b.rental_price) as revenue
From books b
join issued_status ist on ist.issued_book_isbn = b.isbn
join employees emp ON emp.emp_id = ist.issued_emp_id
join branch br ON br.branch_id = emp.branch_id
left join return_status rs ON rs.issued_id = ist.issued_id
group by 1
order by sum(b.rental_price) DESC

select * from branch_report;

-- Task 16: CTAS: Create a Table of Active Members
-- Use the CREATE TABLE AS (CTAS) statement to create a new table active_members containing members 
-- who have issued at least one book in the last 2 months.
SELECT * from members
where member_id in(
SELECT distinct issued_member_id from issued_status
where issued_date > (select max(issued_date)- INTERVAL '2 month' from issued_status) )


-- Task 17: Find Employees with the Most Book Issues Processed
-- Write a query to find the top 3 employees who have processed the most book issues. 
-- Display the employee name, number of books processed, and their branch.

select e.emp_name,br.*,count(ist.issued_id) as no_of_books_processed from issued_status ist
join employees e on e.emp_id=ist.issued_emp_id
join branch br on e.branch_id = br.branch_id
group by 1,2

-- Task 19: Stored Procedure Objective: 
-- Create a stored procedure to manage the status of books in a library system. 
-- Description: Write a stored procedure that updates the status of a book in the library based on its issuance. 
-- The procedure should function as follows: 
-- The stored procedure should take the book_id as an input parameter. 
-- The procedure should first check if the book is available (status = 'yes'). 
-- If the book is available, it should be issued, and the status in the books table should be updated to 'no'. 
-- If the book is not available (status = 'no'), the procedure should return an error message indicating that the book is currently not available.















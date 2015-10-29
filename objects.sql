\c employees;

drop function if exists emp_dept_id( employee_id int );
drop function if exists emp_dept_name( employee_id int ) cascade;
drop function if exists emp_name(employee_id int);
drop function if exists current_manager( dept_id char(4) ) cascade;
drop function if exists show_departments();

--
-- returns the department id of a given employee
--
create function emp_dept_id( employee_id int )
returns char(4)
as $$
begin
    return (
        select
            dept_no
        from
            dept_emp
        where
            emp_no = employee_id
            and
            from_date = (
                select
                    max(from_date)
                from
                    dept_emp
                where
                    emp_no = employee_id
            )
            limit 1
    );
end;
$$ language plpgsql;

--
-- returns the department name of a given employee
--

create function emp_dept_name( employee_id int )
returns varchar(40)
as $$
begin
    return (
        select
            dept_name
        from
            departments
        where
            dept_no = emp_dept_id(employee_id)
    );
end;
$$ language plpgsql;

--
-- returns the employee name of a given employee id
--
create function emp_name (employee_id int)
returns varchar(32)
as $$
begin
    return (
        select
            concat(first_name, ' ', last_name) as name
        from
            employees
        where
            emp_no = employee_id
    );
end;
$$ language plpgsql;

--
-- returns the manager of a department
-- choosing the most recent one
-- from the manager list
--
create function current_manager( dept_id char(4) )
returns varchar(32)
as $$
begin
    return (
        select
            emp_name(emp_no)
        from
            dept_manager
        where
            dept_no = dept_id
            and
            from_date = (
                select
                    max(from_date)
                from
                    dept_manager
                where
                    dept_no = dept_id
            )
            limit 1
    );
end;
$$ language plpgsql;

--
--  selects the employee records with the
--  latest department
--

CREATE OR REPLACE VIEW  v_full_employees
AS
SELECT
    emp_no,
    first_name , last_name ,
    birth_date , gender,
    hire_date,
    emp_dept_name(emp_no) as department
from
    employees;

--
-- selects the department list with manager names
--

CREATE OR REPLACE VIEW v_full_departments
AS
SELECT
    dept_no, dept_name, current_manager(dept_no) as manager
FROM
    departments;

--
-- shows the departments with the number of employees
-- per department
--
create function show_departments()
returns table(dept_no char(4), dept_name varchar(40), manager varchar(32), count bigint)
as $$
begin
    DROP TABLE IF EXISTS department_max_date;
    DROP TABLE IF EXISTS department_people;
    CREATE TEMPORARY TABLE department_max_date
    (
        emp_no int not null primary key,
        dept_from_date date not null,
        dept_to_date  date not null -- bug#320513
    );
    CREATE INDEX ON department_max_date (dept_from_date, dept_to_date);
    INSERT INTO department_max_date
    SELECT
        emp_no, max(from_date), max(to_date)
    FROM
        dept_emp
    GROUP BY
        emp_no;

    CREATE TEMPORARY TABLE department_people
    (
        emp_no int not null,
        dept_no char(4) not null,
        primary key (emp_no, dept_no)
    );

    insert into department_people
    select dmd.emp_no, de.dept_no /* ambiguity */
    from
        department_max_date dmd
        inner join dept_emp de
            on dmd.dept_from_date=de.from_date
            and dmd.dept_to_date=de.to_date
            and dmd.emp_no=de.emp_no;
    RETURN QUERY SELECT
        vfd.dept_no,vfd.dept_name,vfd.manager, count(*) /* ambiguity */
        from v_full_departments vfd
            inner join department_people using (dept_no)
        group by vfd.dept_no,vfd.dept_name,vfd.manager;
        -- with rollup;
    DROP TABLE department_max_date;
    DROP TABLE department_people;
end;
$$ language plpgsql;

drop function if exists employees_usage();
drop function if exists employees_help();

CREATE FUNCTION employees_usage ()
RETURNS TEXT
IMMUTABLE
AS $$
BEGIN
    RETURN
'
    == USAGE ==
    ====================

    FUNCTION show_departments()

        shows the departments with the manager and
        number of employees per department

    FUNCTION current_manager (dept_id)

        Shows who is the manager of a given departmennt

    FUNCTION emp_name (emp_id)

        Shows name and surname of a given employee

    FUNCTION emp_dept_id (emp_id)

        Shows the current department of given employee
';
END;
$$ LANGUAGE plpgsql;

create function employees_help()
returns table(usage text)
as $$
begin
    return query select employees_usage() as info;
end;
$$ language plpgsql;


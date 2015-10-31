--  Sample employee database 
--  See changelog for details
--  Copyright (C) 2007,2008, MySQL AB
--  
--  Original data created by Fusheng Wang and Carlo Zaniolo
--  http://www.cs.aau.dk/TimeCenter/software.htm
--  http://www.cs.aau.dk/TimeCenter/Data/employeeTemporalDataSet.zip
-- 
--  Current schema by Giuseppe Maxia 
--  Data conversion from XML to relational by Patrick Crews
--  Porting to PostgreSQL by Jeongho Jeon
-- 
-- This work is licensed under the 
-- Creative Commons Attribution-Share Alike 3.0 Unported License. 
-- To view a copy of this license, visit 
-- http://creativecommons.org/licenses/by-sa/3.0/ or send a letter to 
-- Creative Commons, 171 Second Street, Suite 300, San Francisco, 
-- California, 94105, USA.
-- 
--  DISCLAIMER
--  To the best of our knowledge, this data is fabricated, and
--  it does not correspond to real people. 
--  Any similarity to existing people is purely coincidental.
-- 
 
-- If you use test_employees_sha.sql, pgcrypto module (that is included in
-- "postgresql-contrib" Linux package) should have been installed and you
-- should use the database superuser role like "postgres". This test script
-- recreates sha1() function. Beware if you have sha1() function already. This
-- test script do not remove pgcrypto module at the end.

\c employees;

SELECT 'TESTING INSTALLATION' as "INFO";

DROP TABLE IF EXISTS expected_values, found_values;
DROP FUNCTION IF EXISTS calculate_checksum();

CREATE EXTENSION IF NOT EXISTS pgcrypto;
DROP FUNCTION IF EXISTS sha1(text);
CREATE FUNCTION sha1(text) returns text AS $$
    SELECT encode(digest($1, 'sha1'), 'hex')
$$ LANGUAGE SQL STRICT IMMUTABLE;

\set start_time `date +%s`
CREATE TABLE expected_values (
    table_name varchar(30) not null primary key,
    recs int not null,
    crc_sha varchar(100) not null,
    crc_md5 varchar(100) not null
);

-- In MySQL 5.0, the creation and update time for  memory tables is not recorded
/*!50130 ALTER TABLE expected_values engine=memory */;

CREATE TABLE found_values (LIKE expected_values);

INSERT INTO "expected_values" VALUES 
('employees',   300024,'4d4aa689914d8fd41db7e45c2168e7dcb9697359',
                        '4ec56ab5ba37218d187cf6ab09ce1aa1'),
('departments',      9,'4b315afa0e35ca6649df897b958345bcb3d2b764',
                       'd1af5e170d2d1591d776d5638d71fc5f'),
('dept_manager',    24,'9687a7d6f93ca8847388a42a6d8d93982a841c6c',
                       '8720e2f0853ac9096b689c14664f847e'),
('dept_emp',    331603, 'd95ab9fe07df0865f592574b3b33b9c741d9fd1b',
                       'ccf6fe516f990bdaa49713fc478701b7'),
('titles',      443308,'d12d5f746b88f07e69b9e36675b6067abb01b60e',
                       'bfa016c472df68e70a03facafa1bc0a8'),
('salaries',   2844047,'b5a1785c27d75e33a4173aaa22ccf41ebd7d4a9f',
                       'fd220654e95aea1b169624ffe3fca934');
SELECT table_name, recs AS expected_records, crc_sha AS expected_crc FROM expected_values;

CREATE FUNCTION calculate_checksum() RETURNS void AS $$
DECLARE
    crc varchar(100);
    r record;
BEGIN
    crc := '';
    FOR r IN SELECT * FROM employees ORDER BY emp_no LOOP
        crc := sha1(CONCAT_WS('#',crc,
            r.emp_no,r.birth_date,r.first_name,r.last_name,r.gender,r.hire_date));
    END LOOP;
    INSERT INTO found_values VALUES ('employees', (SELECT COUNT(*) FROM employees), crc,crc);

    crc := '';
    FOR r IN SELECT * FROM departments ORDER BY dept_no LOOP
        crc := sha1(CONCAT_WS('#',crc, r.dept_no,r.dept_name));
    END LOOP;
    INSERT INTO found_values values ('departments', (SELECT COUNT(*) FROM departments), crc,crc);

    crc := '';
    FOR r IN SELECT * FROM dept_manager ORDER BY dept_no,emp_no LOOP
        crc := sha1(CONCAT_WS('#',crc, r.dept_no,r.emp_no, r.from_date,r.to_date));
    END LOOP;
    INSERT INTO found_values values ('dept_manager', (SELECT COUNT(*) FROM dept_manager), crc,crc);

    crc := '';
    FOR r IN SELECT * FROM dept_emp ORDER BY dept_no,emp_no LOOP
        crc := sha1(CONCAT_WS('#',crc, r.dept_no,r.emp_no, r.from_date,r.to_date));
    END LOOP;
    INSERT INTO found_values values ('dept_emp', (SELECT COUNT(*) FROM dept_emp), crc,crc);

    crc := '';
    FOR r IN SELECT * FROM titles order by emp_no,title, from_date LOOP
        crc := sha1(CONCAT_WS('#',crc, r.emp_no, r.title, r.from_date,r.to_date));
    END LOOP;
    INSERT INTO found_values values ('titles', (SELECT COUNT(*) FROM titles), crc,crc);

    crc := '';
    FOR r IN SELECT * FROM salaries order by emp_no,from_date,to_date LOOP
        crc := sha1(CONCAT_WS('#',crc, r.emp_no, r.salary, r.from_date,r.to_date));
    END LOOP;
    INSERT INTO found_values values ('salaries', (SELECT COUNT(*) FROM salaries), crc,crc);
END
$$ LANGUAGE plpgsql;

SELECT calculate_checksum();

SELECT table_name, recs as "found_records   ", crc_sha as found_crc from found_values;

SELECT  
    e.table_name, 
    CASE WHEN e.recs=f.recs THEN 'OK' ELSE 'not ok' END AS records_match, 
    CASE WHEN e.crc_sha=f.crc_sha THEN 'ok' ELSE 'not ok' END AS crc_match 
from 
    expected_values e INNER JOIN found_values f USING (table_name); 


\set end_time `date +%s`

select to_timestamp(:end_time) - to_timestamp(:start_time) as computation_time;

select 'CRC' as summary,  CASE WHEN (select count(*) from expected_values e inner join found_values f on (e.table_name=f.table_name) where f.crc_sha != e.crc_sha) = 0 THEN 'OK' ELSE 'FAIL' END as "result"
union all
select 'count', CASE WHEN (select count(*) from expected_values e inner join found_values f on (e.table_name=f.table_name) where f.recs != e.recs) = 0 THEN 'OK' ELSE 'FAIL' END as "count";

DROP TABLE expected_values,found_values;

DROP FUNCTION calculate_checksum();
DROP FUNCTION sha1(text);



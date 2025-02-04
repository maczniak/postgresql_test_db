# postgresql_test_db
A sample PostgreSQL database with an integrated test suite, used to test your applications and database servers

You can refer to the original [MySQL docs](https://dev.mysql.com/doc/employee/en/index.html)

These non-essential scripts are not ported yet:
* employees_partitioned.sql
* sql_test.sh
* sakila/


## Where it comes from

The original data was created by Fusheng Wang and Carlo Zaniolo at 
Siemens Corporate Research. The data is in XML format.
http://www.cs.aau.dk/TimeCenter/software.htm
http://www.cs.aau.dk/TimeCenter/Data/employeeTemporalDataSet.zip

Giuseppe Maxia made the relational schema and Patrick Crews exported
the data in relational format.
Jeongho Jeon ported MySQL syntax to PostgreSQL one.

The database contains about 300,000 employee records with 2.8 million 
salary entries. The export data is 167 MB, which is not huge, but
heavy enough to be non-trivial for testing.

The data was generated, and as such there are inconsistencies and subtle
problems. Rather than removing them, we decided to leave the contents
untouched, and use these issues as data cleaning exercises.


## Installation:

1. Download the repository
2. Change directory to the repository
3. run (You can ignore "NOTICE" outputs)

    psql -q -f employees.sql


## Testing the installation

After installing, you can run (You can ignore "NOTICE" outputs)

    mysql -q -f test_employees_md5.sql
    # OR
    mysql -q -f test_employees_sha.sql

If you use test_employees_sha.sql, pgcrypto module (that is included in
"postgresql-contrib" Linux package) should have been installed and you
should use the database superuser role like "postgres". This test script
recreates sha1() function. Beware if you have sha1() function already. This
test script do not remove pgcrypto module at the end.

For example:

    mysql  -q -f test_employees_md5.sql
             INFO
    ----------------------
     TESTING INSTALLATION
    (1 row)
    
      table_name  | expected_records |           expected_crc
    --------------+------------------+----------------------------------
     employees    |           300024 | 4ec56ab5ba37218d187cf6ab09ce1aa1
     departments  |                9 | d1af5e170d2d1591d776d5638d71fc5f
     dept_manager |               24 | 8720e2f0853ac9096b689c14664f847e
     dept_emp     |           331603 | ccf6fe516f990bdaa49713fc478701b7
     titles       |           443308 | bfa016c472df68e70a03facafa1bc0a8
     salaries     |          2844047 | fd220654e95aea1b169624ffe3fca934
    (6 rows)
    
     calculate_checksum
    --------------------
    
    (1 row)
    
      table_name  | found_records    |            found_crc
    --------------+------------------+----------------------------------
     employees    |           300024 | 4ec56ab5ba37218d187cf6ab09ce1aa1
     departments  |                9 | d1af5e170d2d1591d776d5638d71fc5f
     dept_manager |               24 | 8720e2f0853ac9096b689c14664f847e
     dept_emp     |           331603 | ccf6fe516f990bdaa49713fc478701b7
     titles       |           443308 | bfa016c472df68e70a03facafa1bc0a8
     salaries     |          2844047 | fd220654e95aea1b169624ffe3fca934
    (6 rows)
    
      table_name  | records_match | crc_match
    --------------+---------------+-----------
     employees    | OK            | ok
     departments  | OK            | ok
     dept_manager | OK            | ok
     dept_emp     | OK            | ok
     titles       | OK            | ok
     salaries     | OK            | ok
    (6 rows)


## DISCLAIMER

To the best of my knowledge, this data is fabricated, and
it does not correspond to real people. 
Any similarity to existing people is purely coincidental.


## LICENSE
This work is licensed under the 
Creative Commons Attribution-Share Alike 3.0 Unported License. 
To view a copy of this license, visit 
http://creativecommons.org/licenses/by-sa/3.0/ or send a letter to 
Creative Commons, 171 Second Street, Suite 300, San Francisco, 
California, 94105, USA.



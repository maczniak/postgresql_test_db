-- assume that "start_time" and "end_time" psql variables are defined

select to_timestamp(:end_time) - to_timestamp(:start_time) as data_load_time_diff;


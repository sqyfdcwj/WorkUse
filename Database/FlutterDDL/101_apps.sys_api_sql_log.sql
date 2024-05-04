create table apps.sys_api_sql_log (
    sql_log_id serial primary key
);

alter table apps.sys_api_sql_log add column created_on timestamp(0) without time zone default now();
alter table apps.sys_api_sql_log add column sql_group_name varchar(200);
alter table apps.sys_api_sql_log add column sql_group_version integer;
alter table apps.sys_api_sql_log add column sql_group_dtl_id integer;
alter table apps.sys_api_sql_log add column sql_name text;
alter table apps.sys_api_sql_log add column sql text;
alter table apps.sys_api_sql_log add column err_msg text;
alter table apps.sys_api_sql_log add column request_user_id integer;
alter table apps.sys_api_sql_log add column request_username varchar(200);
alter table apps.sys_api_sql_log add column request_app_version integer;
alter table apps.sys_api_sql_log add column request_body text;
alter table apps.sys_api_sql_log add column response_body text;
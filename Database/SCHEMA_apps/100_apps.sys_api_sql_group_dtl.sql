create table apps.sys_api_sql_group_dtl (
    sql_group_dtl_id serial primary key
);

alter table apps.sys_api_sql_group_dtl add column sql_group_name varchar(100);
alter table apps.sys_api_sql_group_dtl add column sql_group_version integer;
alter table apps.sys_api_sql_group_dtl add column sql_name varchar(200);
alter table apps.sys_api_sql_group_dtl add column sql text;
alter table apps.sys_api_sql_group_dtl add column sql_display_name varchar(200);
alter table apps.sys_api_sql_group_dtl add column sql_order integer;
alter table apps.sys_api_sql_group_dtl add column key_field varchar(100);
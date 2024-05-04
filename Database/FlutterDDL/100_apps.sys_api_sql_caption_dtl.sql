create table apps.sys_api_sql_caption_dtl (
    sql_caption_dtl_id serial primary key
);

alter table apps.sys_api_sql_caption_dtl add column unique_name varchar(100);
alter table apps.sys_api_sql_caption_dtl add column en text;
alter table apps.sys_api_sql_caption_dtl add column zh_zh text;
alter table apps.sys_api_sql_caption_dtl add column zh_tw text;
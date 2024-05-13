create table ar_so_dtl_comment (
    so_dtl_comment_id serial primary key
);

alter table ar_so_dtl_comment add column so_dtl_id integer;
alter table ar_so_dtl_comment add column comment text;
alter table ar_so_dtl_comment add column created_on timestamp(0) without time zone;
alter table ar_so_dtl_comment alter column created_on set default now;
alter table ar_so_dtl_comment add column created_by varchar(200);
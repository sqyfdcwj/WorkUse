create table ar_so_dtl_comment
(
    so_dtl_comment_id serial primary key,
    so_dtl_id integer,
    comment text,
    created_by varchar(100),
    created_on timestamp(0) without time zone default now()
);
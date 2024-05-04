create table ap_purchase_dtl_comment
(
    purchase_dtl_comment_id serial primary key,
    purchase_dtl_id integer,
    comment text,
    created_by varchar(100),
    created_on timestamp(0) without time zone default now()
);
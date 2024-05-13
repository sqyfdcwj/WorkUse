create table ap_purchase_dtl_comment (
    purchase_dtl_comment_id serial primary key
);

alter table ap_purchase_dtl_comment add column purchase_dtl_id integer;
alter table ap_purchase_dtl_comment add column comment text;
alter table ap_purchase_dtl_comment add column created_on timestamp(0) without time zone;
alter table ap_purchase_dtl_comment alter column created_on set default now;
alter table ap_purchase_dtl_comment add column created_by varchar(200);
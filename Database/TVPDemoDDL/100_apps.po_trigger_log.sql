
create table apps.po_trigger_log
(
    trigger_log_id serial primary key,
    purchase_id integer,
    log text,
    created_by varchar(100),
    created_on timestamp(0) without time zone default now()  
);
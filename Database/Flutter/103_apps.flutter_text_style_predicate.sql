create table apps.flutter_text_style_predicate (
    predicate_id serial primary key
);

alter table apps.flutter_text_style_predicate add column unique_name varchar(100);
alter table apps.flutter_text_style_predicate add column predicate_order integer;
alter table apps.flutter_text_style_predicate add column method varchar(20);
alter table apps.flutter_text_style_predicate add column compare_value varchar(100);
alter table apps.flutter_text_style_predicate add column text_style_id integer;
alter table apps.flutter_text_style_predicate add column remark varchar(100);

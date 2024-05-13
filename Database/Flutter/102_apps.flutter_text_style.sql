create table apps.flutter_text_style (
    style_id serial primary key
);

alter table apps.flutter_text_style add column style_name varchar(50) unique not null;

alter table apps.flutter_text_style add column font_size integer;
alter table apps.flutter_text_style alter column font_size set default 14;
alter table apps.flutter_text_style add column a integer;
alter table apps.flutter_text_style alter column a set default 255;
alter table apps.flutter_text_style add column r integer;
alter table apps.flutter_text_style alter column r set default 0;
alter table apps.flutter_text_style add column g integer;
alter table apps.flutter_text_style alter column g set default 0;
alter table apps.flutter_text_style add column b integer;
alter table apps.flutter_text_style alter column b set default 0;
alter table apps.flutter_text_style add column is_italic boolean;
alter table apps.flutter_text_style alter column is_italic set default false;
alter table apps.flutter_text_style add column font_weight integer;
alter table apps.flutter_text_style alter column font_weight set default 4;
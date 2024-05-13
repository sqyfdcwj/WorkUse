create table apps.flutter_dataset_field_layout (
    layout_id serial primary key
);

alter table apps.flutter_dataset_field_layout add column unique_name varchar(100);
alter table apps.flutter_dataset_field_layout add column layout_type integer;
alter table apps.flutter_dataset_field_layout alter column layout_type set default 0;
alter table apps.flutter_dataset_field_layout add column caption_flex integer;
alter table apps.flutter_dataset_field_layout alter column caption_flex set default 1;
alter table apps.flutter_dataset_field_layout add column content_flex integer;
alter table apps.flutter_dataset_field_layout alter column content_flex set default 1;
alter table apps.flutter_dataset_field_layout add column caption_alignment_x numeric(2, 1);
alter table apps.flutter_dataset_field_layout alter column caption_alignment_x set default -1;
alter table apps.flutter_dataset_field_layout add column caption_alignment_y numeric(2, 1);
alter table apps.flutter_dataset_field_layout alter column caption_alignment_y set default -1;
alter table apps.flutter_dataset_field_layout add column content_alignment_x numeric(2, 1);
alter table apps.flutter_dataset_field_layout alter column content_alignment_x set default -1;
alter table apps.flutter_dataset_field_layout add column content_alignment_y numeric(2, 1);
alter table apps.flutter_dataset_field_layout alter column content_alignment_y set default -1;
alter table apps.flutter_dataset_field_layout add column hide_on_empty boolean;
alter table apps.flutter_dataset_field_layout alter column hide_on_empty set default true;
alter table apps.flutter_dataset_field_layout add column caption_text_style_id integer;
alter table apps.flutter_dataset_field_layout add column main_axis_alignment varchar(15);
alter table apps.flutter_dataset_field_layout add column cross_axis_alignment varchar(10);
alter table apps.flutter_dataset_field_layout add column text_baseline varchar(15);
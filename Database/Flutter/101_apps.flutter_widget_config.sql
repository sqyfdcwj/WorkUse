create table apps.flutter_widget_config (
    config_id serial primary key
);

alter table apps.flutter_widget_config add column parent_config_id integer;
alter table apps.flutter_widget_config add column config_name varchar(100);
alter table apps.flutter_widget_config add column depth integer;
alter table apps.flutter_widget_config add column widget_type varchar(50);
alter table apps.flutter_widget_config add column widget_order integer;
alter table apps.flutter_widget_config add column unique_name varchar(100);
alter table apps.flutter_widget_config add column flex integer;
alter table apps.flutter_widget_config alter column flex set default 0;
alter table apps.flutter_widget_config add column text_style_id integer;

alter table apps.flutter_widget_config add column padding_left integer; 
alter table apps.flutter_widget_config alter column padding_left set default 0; 
alter table apps.flutter_widget_config add column padding_right integer; 
alter table apps.flutter_widget_config alter column padding_right set default 0; 
alter table apps.flutter_widget_config add column padding_top integer; 
alter table apps.flutter_widget_config alter column padding_top set default 0; 
alter table apps.flutter_widget_config add column padding_bottom integer; 
alter table apps.flutter_widget_config alter column padding_bottom set default 0; 

alter table apps.flutter_widget_config add column background_a integer;
alter table apps.flutter_widget_config add column background_r integer;
alter table apps.flutter_widget_config add column background_g integer;
alter table apps.flutter_widget_config add column background_b integer;

alter table apps.flutter_widget_config add column alignment_x numeric(2, 1);
alter table apps.flutter_widget_config alter column alignment_x set default default -1;
alter table apps.flutter_widget_config add column alignment_y numeric(2, 1);
alter table apps.flutter_widget_config alter column alignment_y set default default -1;

alter table apps.flutter_widget_config add column width integer;
alter table apps.flutter_widget_config add column height integer;

alter table apps.flutter_widget_config add column pos_left integer;
alter table apps.flutter_widget_config add column pos_right integer;
alter table apps.flutter_widget_config add column pos_top integer;
alter table apps.flutter_widget_config add column pos_bottom integer;

alter table apps.flutter_widget_config add column main_axis_alignment varchar(15);
alter table apps.flutter_widget_config add column cross_axis_alignment varchar(10);
alter table apps.flutter_widget_config add column text_baseline varchar(15);
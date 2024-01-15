create schema apps;

/* Represents data that used by server API to construct SQL statements to process input,
   and how API should handle result dataset retrieved from the statements.
 */
create table apps.sys_api_sql_group_dtl
(
    sql_group_dtl_id serial primary key,

    /* Used by API to filter rows */
    sql_group_name varchar(50),
    
    /* Used by API to filter rows */
    sql_group_version integer,

    /* For developer to distinguish a row with other rows
       Naming convention:
       1. SELECT statements start with r_
       2. INSERT statements start with c_
       3. UPDATE statements start with u_
       4. DELETE statements start with d_
       5. ALL statements end with __$sql_group_name

       Example: r_unchecked_po_list__20230801
     */
    sql_name varchar(200) unique not null,

    sql text,

    /* The executing order of SQL statement, ascending */
    sql_order integer,

    /* Used as a key to access the dataset that generated by the SQL statement, in the API result */
    sql_display_name varchar(50),

    /* Used by API to perform pivot operation on the dataset, if the field has non-empty value */
    key_field varchar(50)
);

/* Used by server API to log the result or error generated during running queries */
create table apps.sys_api_sql_log
(
    sql_log_id serial primary key,

    /* Snapshot. See [apps.sys_api_sql_group_dtl.sql_group_dtl_id] */
    sql_group_dtl_id integer,

    /* Snapshot. See [apps.sys_api_sql_group_dtl.sql_group_name] */
    sql_group_name varchar(50),

    /* Snapshot. See [apps.sys_api_sql_group_dtl.sql_group_version] */
    sql_group_version integer,

    /* Snapshot. See [apps.sys_api_sql_group_dtl.sql_name] */
    sql_name varchar(200),

    /* Snapshot. See [apps.sys_api_sql_group_dtl.sql] */
    sql text,

    /* Error message generated by API */
    err_msg text,

    /* API path */
    request_xml text,
    
    /* Raw input that processed by API */
    response_xml text,

    created_on timestamp(0) without time zone default now(),
);


/* Caption configurations of a Flutter project */
create table apps.sys_api_sql_caption_dtl
(
    sql_caption_dtl_id serial primary key,

    /* Naming convention (case sensitive):
       1. Captions of dataset fields of [apps.sys_api_sql_group_dtl] queries:
          [apps.sys_api_sql_group_dtl.sql_name]_[fieldName]
          Example: Row where $[sql_name] = r_unchecked_po_list__20230801 contains a field 'purchase_no'
          then the unique name of this field will be 'r_unchecked_po_list__20230801_purchase_no'
       
       2. Captions used in labels (enum): enum$[enumName]$[enumValue]
          Example: A enum case Module.checkPO ($[enumName] = Module, $[enumValue] = checkPO),
          its unique name will be 'enumModulecheckPO'
    
       3. Captions used in labels (except enum): prefixed with 'lbl'
       4. Captions used as dialog messages: prefixed with 'dlg'
     */
    unique_name varchar(100) unique not null,

    en varchar(100),
    zh_cn varchar(100),
    zh_tw varchar(100)
);

/* Text style configurations of a Flutter project */
create table apps.flutter_text_style
(
    style_id serial primary key,

	/* Used by developer. Provide info about what scenario this style is used in. */
    style_name varchar(50) unique not null,

    font_size integer default 14,

    a integer default 255,
    r integer default 0,
    g integer default 0,
    b integer default 0,

    is_bold boolean default false,
    is_italic boolean default false
);

/* Text style predicate configurations of a Flutter project */
create table apps.flutter_text_style_predicate
(
    predicate_id serial primary key,

    /* See naming convention of [apps.sys_api_sql_caption_dtl.unique_name] */
    unique_name varchar(100),

    /* Executing order, ascending */
    predicate_order integer,

    /* Possible values:
       Empty string: return true without any comparison
       'eq': Check whether $input == $[compare_value]
       'regex': Check whether RegExp($[compare_value]).isMatch($input)
     */
    method varchar(20),

    /* An exact string value, or a regular expression used to compare with $input 
       See [method] to see the usage  
     */
    compare_value varchar(100),

    /* See [apps.flutter_text_style] */
    text_style_id integer
);


create table apps.flutter_widget_config
(
    config_id serial primary key,

    /* ID of parent node. For root node, $[parent_config_id] = 0 */
    parent_config_id integer,

    /* Used by API */
    config_name varchar(100),

    /* For root node, $[depth] = 1 */
    depth integer,

    /* If $[widget_type] is 'Row' or 'Column', it will be handled by the Flutter project file;
	   otherwise developer should handle the case.
	   If $[widget_type] is 'Data', developer should also maintain the records in [apps.flutter_dataset_field_layout]
     */
    widget_type varchar(50),

    /* This field is used by the parent node.
	   If $[widget_type] of parent is neither 'Row' nor 'Column', the child node with smallest $[widget_order] will be used;
	   otherwise all children nodes are used.
	 */
    widget_order integer,

    /* Ignored if $[widget_type] is 'Row' or 'Column'.
       If $[widget_type] is 'Data', it represents the field name of a dataset;
       otherwise it represents the unique name of the widget, which is usually hard-coded in project, set by developer
       Developer should handle the case other than 'Row' or 'Column'.
     */
    unique_name varchar(100),

    /* Ignored if $[widget_type] of parent is neither 'Row' nor 'Column', or $[flex] < 1;
       otherwise it will be used to build a [Expanded] widget in Flutter
     */
    flex integer default 0,

	/* See [apps.flutter_text_style] 
       If set, the text style will be applied to the current widget and all its children, 
	   until overriden by another text style in child widget
     */
    text_style_id integer,

    padding_left integer default 0,
    padding_right integer default 0,
    padding_top integer default 0,
    padding_bottom integer default 0,

    background_a integer,
    background_r integer,
    background_g integer,
    background_b integer,

    /* Valid range is from -1 to 1 (left to right) 
	   Ignored if $[widget_type] is 'Data'. $[apps.flutter_dataset_field_layout.content_alignment_x] will be used
	 */
    alignment_x numeric(2, 1) default -1,

    /* Valid range is from -1 to 1 (top to bottom) 
	   Ignored if $[widget_type] is 'Data'. $[apps.flutter_dataset_field_layout.content_alignment_y] will be used
	 */
    alignment_y numeric(2, 1) default -1,

	width integer,
	height integer
);

/* Configuration used by custom defined widget of Flutter project: [DatasetField] 
   This table is also used with [apps.flutter_widget_config] and overrides some configs in [apps.flutter_widget_config]
   
   When display the data from dataset, we may want to give a label caption to provide hints,
   and we can configure the layout of the label and value in this table
 */
create table apps.flutter_dataset_field_layout
(
	layout_id serial primary key,

	/* See naming convention of [apps.sys_api_sql_caption_dtl.unique_name] 
	   Used by Flutter file to link to a caption
	 */
	unique_name varchar(100),

	/* Flutter file will do different layout according to the value set:
	   0 - Display $value only
	   1 - Display $caption and $value and put them in a row
	   2 - Display $caption and $value and put them in a column
	   default - Same as case 0
	 */
	layout_type integer default 0,

    /* Ignored if $[layout_type] is not 1 */
	caption_flex integer default 1,

    /* Ignored if $[layout_type] is not 1 */
	content_flex integer default 1,

	caption_alignment_x numeric(2, 1) default -1,
	caption_alignment_y numeric(2, 1) default -1,

	/* Overrides [apps.flutter_widget_config.alignment_x] */
	content_alignment_x numeric(2, 1) default -1,

	/* Overrides [apps.flutter_widget_config.alignment_y] */
	content_alignment_y numeric(2, 1) default -1,

	/* Whether should hide the field if $value is empty */
	hide_on_empty boolean default true,

    /* See [apps.flutter_text_style] */
	caption_text_style_id integer
);


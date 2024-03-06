--frmCaptionList.FDList
SELECT * FROM apps.sys_api_sql_caption_dtl ORDER BY unique_name;

--frmTextStyleList.FDList
SELECT * FROM apps.flutter_text_style ORDER BY style_name;

--frmTextStyleInfo.FDInfo
SELECT * FROM apps.flutter_text_style WHERE style_id = :style_id;

--frmTextStyleInfo.FDUseByWidget
SELECT *
FROM apps.flutter_text_style ts
WHERE EXISTS (
    SELECT 1
    FROM apps.flutter_widget_config wc
    WHERE wc.text_style_id = ts.style_id
)
ORDER BY ts.style_name;

--frmTextStyleInfo.FDUseByCaption
SELECT *
FROM apps.flutter_text_style ts
WHERE EXISTS (
    SELECT 1
    FROM apps.flutter_dataset_field_layout cd
    WHERE cd.caption_text_style_id = ts.style_id
)
ORDER BY ts.style_name;
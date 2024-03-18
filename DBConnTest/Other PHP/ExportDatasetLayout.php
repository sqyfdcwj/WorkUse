<?php 

header("Content-type:text/plain");

require_once 'DBConn.php';
require_once 'SQLUtil.php';

$sql = "
    SELECT l.*, ts.style_name
    FROM apps.flutter_dataset_field_layout l
    LEFT JOIN apps.flutter_text_style ts ON l.caption_text_style_id = ts.style_id;
";

$conn = DBConn::pg("10.50.50.226", 5434, "erp_kayue_trading__20231228", "postgres", "xtra!@#$%");

$opResult = $conn->exec($sql);

$dataSet = $opResult->getDataSet();

$map = [];

foreach ($dataSet as &$row) {
    unset($row["caption_text_style_id"]);
    if (empty($row["layout_type"])) { unset($row["layout_type"]); }
    if (empty($row["style_name"])) { unset($row["style_name"]); }
    if ($row["caption_alignment_x"] === NULL || $row["caption_alignment_x"] == -1) { unset($row["caption_alignment_x"]); }
    if ($row["caption_alignment_y"] === NULL || $row["caption_alignment_y"] == -1) { unset($row["caption_alignment_y"]); }
    if ($row["content_alignment_x"] === NULL || $row["content_alignment_x"] == -1) { unset($row["content_alignment_x"]); }
    if ($row["content_alignment_y"] === NULL || $row["content_alignment_y"] == -1) { unset($row["content_alignment_y"]); }
    if ($row["type"] !== 1) {
        unset($row["layout_id"], $row["caption_flex"], $row["content_flex"]);
    }
    if ($row["hide_on_empty"]) {
        unset($row["hide_on_empty"]);
    }
}

$result = json_encode($dataSet, JSON_NUMERIC_CHECK);
$result = str_replace("},", "},\n", $result);
$result = str_replace("[{", "[\n{", $result);
$result = str_replace("}]", "}\n]", $result);
$result = str_replace("],", "],\n", $result);
$result = str_replace("\/", "/", $result);

$lines = explode("\n", $result);
$len = count($lines);
foreach ($lines as $idx => &$line) {
    if ($idx == 0 || $idx == $len - 1) {
        continue;
    } 
    $line = "    ".$line;
}

$file = fopen("DatasetLayout.json", "w");
fwrite($file, implode("\n", $lines));
fclose($file);

echo implode("\n", $lines);
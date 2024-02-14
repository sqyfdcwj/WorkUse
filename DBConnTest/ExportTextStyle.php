<?php 

header("Content-type:text/plain");

require_once 'DBConn.php';
require_once 'SQLUtil.php';

$sql = "
    SELECT style_name, font_size, is_bold, is_italic, a, r, g, b
    FROM apps.flutter_text_style
    ORDER BY style_name;
";

$conn = DBConn::pg("10.50.50.226", 5434, "erp_kayue_trading__20231228", "postgres", "xtra!@#$%");

$opResult = $conn->exec($sql);

$dataSet = $opResult->getDataSet();

$map = [];

foreach ($dataSet as &$row) {
    if (empty($row["is_bold"])) { unset($row["is_bold"]); }
    if (empty($row["is_italic"])) { unset($row["is_italic"]); }
    if (empty($row["a"])) { unset($row["ar"]); }
    if (empty($row["r"])) { unset($row["r"]); }
    if (empty($row["g"])) { unset($row["g"]); }
    if (empty($row["b"])) { unset($row["b"]); }
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

$file = fopen("TextStyle.json", "w");
fwrite($file, implode("\n", $lines));
fclose($file);

echo implode("\n", $lines);
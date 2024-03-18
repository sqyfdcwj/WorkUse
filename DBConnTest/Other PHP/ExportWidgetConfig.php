<?php 

header("Content-type:text/plain");

require_once 'DBConn.php';
require_once 'SQLUtil.php';

$sql = "
WITH RECURSIVE flutter_widget_config AS (
    SELECT lhs.config_id, lhs.parent_config_id, lhs.config_name, 
        lhs.depth, lhs.widget_order, 
        lhs.depth || '-' || lhs.widget_type AS path,
        lhs.flex, lhs.unique_name,
        ts.style_name AS text_style_name, 
        lhs.alignment_x, lhs.alignment_y,
        lhs.padding_left, lhs.padding_right, lhs.padding_top, lhs.padding_bottom,
        lhs.background_a, lhs.background_r, lhs.background_g, lhs.background_b,
        lhs.width, lhs.height
        
    FROM apps.flutter_widget_config lhs
    LEFT JOIN apps.flutter_text_style ts ON lhs.text_style_id = ts.style_id
    WHERE coalesce(lhs.parent_config_id, 0) = 0
    AND (coalesce(:config_name, '') = '' OR lhs.config_name = :config_name)
    AND lhs.depth = 1
    
    UNION ALL
    
    SELECT rhs.config_id, rhs.parent_config_id, rhs.config_name, 
        rhs.depth, rhs.widget_order,
        lhs.path || '/' || rhs.widget_order || '-' || rhs.widget_type,
        rhs.flex, rhs.unique_name, 
        ts.style_name AS text_style_name, 
        rhs.alignment_x, rhs.alignment_y,
        rhs.padding_left, rhs.padding_right, rhs.padding_top, rhs.padding_bottom,
        rhs.background_a, rhs.background_r, rhs.background_g, rhs.background_b,
        rhs.width, rhs.height
    FROM flutter_widget_config lhs
    JOIN apps.flutter_widget_config rhs ON lhs.config_id = rhs.parent_config_id
        AND lhs.config_name = rhs.config_name
        AND lhs.depth + 1 = rhs.depth
    LEFT JOIN apps.flutter_text_style ts ON rhs.text_style_id = ts.style_id
)
SELECT config_name, path, flex, unique_name,
    text_style_name, 
    alignment_x, alignment_y,
    padding_left, padding_right, padding_top, padding_bottom,
    background_a, background_r, background_g, background_b,
    width, height
    
FROM flutter_widget_config
ORDER BY config_name, path;
";

$conn = DBConn::pg("10.50.50.226", 5434, "erp_kayue_trading__20231228", "postgres", "xtra!@#$%");

$opResult = $conn->exec($sql, ["config_name" => $_GET["config_name"]]);

$dataSet = $opResult->getDataSet();

$map = [];

foreach ($dataSet as &$row) {
    if (empty($row["text_style_name"])) { unset($row["text_style_name"]); }
    if (empty($row["unique_name"])) { unset($row["unique_name"]); }
    if (empty($row["padding_left"])) { unset($row["padding_left"]); }
    if (empty($row["padding_right"])) { unset($row["padding_right"]); }
    if (empty($row["padding_top"])) { unset($row["padding_top"]); }
    if (empty($row["padding_bottom"])) { unset($row["padding_bottom"]); }
    if (empty($row["background_a"])) { unset($row["background_a"]); }
    if (empty($row["background_r"])) { unset($row["background_r"]); }
    if (empty($row["background_g"])) { unset($row["background_g"]); }
    if (empty($row["background_b"])) { unset($row["background_b"]); }
    if (empty($row["width"])) { unset($row["width"]); }
    if (empty($row["height"])) { unset($row["height"]); }
    if (empty($row["flex"])) { unset($row["flex"]); }
    if ($row["alignment_x"] === NULL || $row["alignment_x"] == -1) { unset($row["alignment_x"]); }
    if ($row["alignment_y"] === NULL || $row["alignment_y"] == -1) { unset($row["alignment_y"]); }

    $configName = $row["config_name"];
    unset($row["config_name"]);

    $map[$configName][] = $row;
}

$result = json_encode($map, JSON_NUMERIC_CHECK);
$result = str_replace("},", "},\n", $result);
$result = str_replace("[{", "[\n{", $result);
$result = str_replace("}]", "}\n]", $result);
$result = str_replace("],", "],\n", $result);
$result = str_replace("\/", "/", $result);
$result = "{\n".ltrim($result, "{");
$result = rtrim($result, "}")."\n}";

$lines = explode("\n", $result);
$len = count($lines);
foreach ($lines as $idx => &$line) {
    if ($idx == 0 || $idx == $len - 1) {
        continue;
    } 
    if (strpos($line, "{") === 0) {
        $line = "        ".$line;
    } else {
        $line = "    ".$line;
    }
}

$file = fopen("DynamicWidgetData.json", "w");
fwrite($file, implode("\n", $lines));
fclose($file);

echo implode("\n", $lines);
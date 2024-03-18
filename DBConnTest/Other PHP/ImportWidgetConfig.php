<?php 

require_once 'DBConn.php';
require_once 'SQLUtil.php';

$deleteSql = "
DELETE FROM apps.flutter_widget_config
WHERE config_name = :config_name;
";

$insertSql = "
INSERT INTO apps.flutter_widget_config (
    config_name,
    widget_type, depth, flex, widget_order, unique_name, 
    alignment_x, alignment_y, width, height,
    background_a, background_r, background_g, background_b,
    padding_left, padding_right, padding_top, padding_bottom
)
SELECT :config_name, 
    :widget_type, :depth, :flex, :widget_order, :unique_name, 
    :alignment_x, :alignment_y, :width, :height,
    :background_a, :background_r, :background_g, :background_b,
    :padding_left, :padding_right, :padding_top, :padding_bottom

RETURNING config_id;
";

$updateSql = "
UPDATE apps.flutter_widget_config lhs SET
parent_config_id = :parent_config_id,
text_style_id = (SELECT style_id FROM apps.flutter_text_style WHERE style_name = :text_style_name)

WHERE lhs.config_id = :config_id;
";

$raw = file_get_contents("php://input");

$json = json_decode($raw, true);

$conn = DBConn::pg("10.50.50.226", 5434, "erp_kayue_trading__20231228", "postgres", "xtra!@#$%");

$isError = false;
$opResult = $conn->beginTransaction();

$configIdList = [];

if (!$isError) {
    foreach ($json as $configName => $widgetList) {
        $opResult = $conn->exec($deleteSql, [ "config_name" => $configName ]);
        if (!$opResult->getIsSuccess()) {
            $isError = true;
            goto END;
        }


        $list = [];

        foreach ($widgetList as $cfg) {
            $path = $cfg["path"];
            $components = explode("/", $path);
            $depth = count($components);

            $selfPath = $components[$depth - 1];
            $parentPath = implode("/", array_slice($components, 0, $depth - 1));
            $fieldList = explode("-", $components[$depth - 1]);

            $cfg["parent_path"] = $parentPath;
            $cfg["depth"] = $depth;
            $cfg["widget_order"] = $fieldList[0];
            $cfg["widget_type"] = $fieldList[1];
            $cfg["config_name"] = $configName;

            $list[] = $cfg;
            // print_r($cfg);
        }

        foreach ($list as &$cfg) {
            $opResult = $conn->exec($insertSql, SQLUtil::getParamList($insertSql, $cfg));
            if (!$opResult->getIsSuccess()) {
                $isError = true;
                echo "Insert Error".PHP_EOL;
                goto END;
            } else {
                $configIdList[$cfg["path"]] = $opResult->getDataSet()[0]["config_id"];
            }
        }

        foreach ($list as &$cfg) {
            $cfg["config_id"] = $configIdList[$cfg["path"]];
            $cfg["parent_config_id"] = $configIdList[$cfg["parent_path"]];
            $opResult = $conn->exec($updateSql, SQLUtil::getParamList($updateSql, $cfg));
            if (!$opResult->getIsSuccess()) {
                $isError = true;
                echo "Update Error".PHP_EOL;
                goto END;
            }
        }
    }
}
END:

if ($isError) {
    echo $opResult->getErrMsg().PHP_EOL;
    $opResult = $conn->rollBack();
} else {
    echo "COMMIT".PHP_EOL;
    $opResult = $conn->commit();
}
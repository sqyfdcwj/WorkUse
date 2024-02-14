<?php

require_once 'DataSource.php';
require_once 'DBConn.php';
require_once 'DBConnExtension.php';
require_once 'WebApiRequest.php';
require_once 'EmailSender.php';

try {
    $dbNameList = [
        "erp_hingfat__20230502",
        "erp_hingfat__20230802",
        "erp_hingfat__20230825",
        "erp_hingfat__20230918",
        "erp_hingfat__20231031",
        "erp_hingfat__20231124"
    ];

    $sql = "
        SELECT :dbname AS dbname, max(log.created_on) AS latest
        FROM apps.sys_api_sql_log log;
    ";

    foreach ($dbNameList as $dbName) {
        $conn = DBConn::pg("192.168.2.241", 5438, $dbName, "postgres", "xtra!@#$%");
        $opResult = $conn->exec($sql, ["dbname" => $dbName]);
        if ($opResult->getRowCount() > 0) {
            $dataSet = $opResult->getDataSet();
            echo "DBName = ".$dataSet[0]["dbname"].", latest = ".$dataSet[0]["latest"].PHP_EOL;
        }
    }

} catch (PDOException $e) {
    echo "catch PDOException".PHP_EOL;
    var_dump($e->getCode());
    echo PHP_EOL;
    echo $e->getMessage();
} catch (Exception $e) {
    echo "Catch Exception".PHP_EOL;
    echo $e->getMessage();
} catch (\Exception $e) {
    echo "Catch \Exception".PHP_EOL;
    echo $e->getMessage();
}

?>
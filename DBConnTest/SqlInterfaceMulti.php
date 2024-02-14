<?php

header("Content-type:application/json");

require_once 'DataSource.php';
require_once 'DBConn.php';
require_once 'DBConnExtension.php';
require_once 'WebApiRequest.php';
require_once 'SQLUtil.php';

try {
    $conn = DBConnExtension::xtra("10.50.50.226", 5434, "erp_kayue_trading__20231228");
    $request = new WebApiRequest(99999999);
    $result = $request->run($conn, TRUE);


    $lastError = $result->getLastError();
    $isError = $lastError !== NULL;
    $body = [];

    if (!$isError) {
        $opResultList = $result->getOpResultList();
        foreach ($opResultList as $opResult) {
            if ($opResult instanceof OpResult) {
                $opContext = $opResult->getContext();
                if ($opContext->getIsTcl()) { continue; }

                $dataSet = $opResult->getDataSet();
                $sqlDisplayName = $opContext->getTag("sql_display_name");
                $keyField = $opContext->getTag("key_field");

                if (empty($keyField)) {
                    $body[$sqlDisplayName] = $dataSet;
                } else {
                    foreach ($dataSet as &$row) {
                        SQLUtil::castBoolToInt($row);
                        SQLUtil::castToStr($row);
                    }
                    $body[$sqlDisplayName] = SQLUtil::pivot($dataSet, $keyField);
                    $body[$sqlDisplayName."_keys"] = array_keys($body[$sqlDisplayName]);
                }
            }
        }
    }
    
    $json = [
        "code" => $isError ? 1 : 0,
        "message" => $isError ? $lastError->getErrMsg() : "",
        "body" => $body
    ];

    echo json_encode($json);
} catch (PDOException $e) {
    echo "catch PDOException".PHP_EOL;
    var_dump($e->getCode());
    echo PHP_EOL;
    echo $e->getMessage();
} catch (\Exception $e) {
    echo "Catch \Exception".PHP_EOL;
    echo $e->getMessage();
}

?>
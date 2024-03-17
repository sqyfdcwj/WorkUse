<?php

header("Content-type:application/json");

require_once '20240304/lib/DBConn.php';
require_once '20240304/lib/WebApiRequest.php';

// $isError = false;
// $message = "";
$body = [];

try {
    // $conn = DBConnExtension::xtraWithKey($_GET["key"]);
    // $conn = DBConn::pg("10.50.50.226", 5434, "erp_kayue_trading__20231228", "postgres", "xtra!@#$%");
    $conn = DBConn::pg("localhost", 54322, "postgres", "postgres", "1234");

    $raw = file_get_contents("php://input");
    $version = intval(basename(getcwd()));  // 0 if failed to convert
    $request = new WebApiRequest($raw, $version === 0 ? 99999999 : $version);
    $result = $request->run($conn, TRUE);   // 

    if ($result->getIsSuccess()) {
        $opResultList = $result->getOpResultList();
        foreach ($opResultList as $opResult) {
            if (!($opResult instanceof OpResult)) {
                continue;
            }

            $opContext = $opResult->getContext();
            if ($opContext->getIsTcl()) { continue; }

            $dataSet = $opResult->getDataSet();
            $sqlDisplayName = $opContext->getTag("sql_display_name");
            $keyField = $opContext->getTag("key_field");

            foreach ($dataSet as &$row) {
                DataSetUtil::castBoolToInt($row);
                DataSetUtil::castToStr($row);
            }

            if (empty($keyField)) {
                $body[$sqlDisplayName] = $dataSet;
            } else {
                $body[$sqlDisplayName] = DataSetUtil::pivot($dataSet, $keyField);
                $body[$sqlDisplayName."_keys"] = array_keys($body[$sqlDisplayName]);
            }
        }

        $responseBody = json_encode([
            "code" => 0,
            "message" => "",
            "body" => $body
        ]);

        /**
         * Insert database log when the request contains at least 1 SqlGroupName
         */
        /*
        $sqlGroupNameList = $request->getSqlGroupNameList();
        if (empty($sqlGroupNameList)) {
            return;
        }

        $sqlGroupName = $sqlGroupNameList[0];
        $row = $request->getInput()[$sqlGroupName][0];

        $sql = "
        INSERT INTO apps.sys_api_sql_log (
            sql_group_dtl_id, sql_group_name,
            sql_group_version, sql_name, sql, err_msg,
            request_user_id, request_username,
            request_body, response_body, request_app_version
        )
        SELECT :sql_group_dtl_id, :sql_group_name,
            :sql_group_version, :sql_name, :sql, :err_msg,
            :request_user_id, :request_username,
            :request_body, :response_body, :request_app_version;
            ";

        var_dump(SQLUtil::getParamList($sql, 
            $row,
            [
                "sql_group_name" => implode("-", $sqlGroupNameList),
                "request_app_version" => $request->getVersion(),
                "request_body" => $request->getRaw(),
                "response_body" => $responseBody
            ]
        ));
        */

    } else {
        $lastError = $result->getLastError();
        $lastErrorContext = $result->getLastError()->getContext();
        $responseBody = json_encode([
            "code" => 1,
            "message" => $lastError->getErrMsg(),
            "body" => $body
        ]);

/*
        $sql = "
        INSERT INTO apps.sys_api_sql_log (
            sql_group_dtl_id, sql_group_name,
            sql_group_version, sql_name, sql, err_msg,
            request_user_id, request_username,
            request_body, response_body, request_app_version
        )
        SELECT :sql_group_dtl_id, :sql_group_name,
            :sql_group_version, :sql_name, :sql, :err_msg,
            :request_user_id, :request_username,
            :request_body, :response_body, :request_app_version;
            ";

        $lastErrorContext = $lastError->getContext();
        var_dump(SQLUtil::getParamList($sql, 
            $lastErrorContext->getRawParam(),
            $lastErrorContext->getTags(),
            [
                "err_msg" => $lastError->getErrMsg(),
                "request_app_version" => $request->getVersion(),
                "request_body" => $request->getRaw(),
                "response_body" => $responseBody
            ]
        ));
        // Insert database log
        // $opLog = insertLog($conn, [
        //     "sql_group_dtl_id" => $lastErrorContext->getTag("sql_group_dtl_id"),
        //     "sql_group_name" => $lastErrorContext->getTag("sql_group_name"),
        //     "sql_group_version" => $lastErrorContext->getTag("sql_group_version"),
        //     "sql_name" => $lastErrorContext->getTag("sql_group_dtl_id"),
        //     "sql_group_dtl_id" => $lastErrorContext->getTag("sql_group_dtl_id"),
        // ]);



    //     SELECT :sql_group_dtl_id, :sql_group_name,
    // :sql_group_version, :sql_name, :sql, :err_msg,
    // :request_user_id, :request_username,
    // :request_body, :response_body, :request_app_version;

        // Save to server
        // saveErrorReport($raw, $lastError);


        // Send email

        // (new WebApiEmail())->send(
        //     $_SERVER["HTTP_HOST"].$_SERVER['SCRIPT_NAME'],
        //     $conn->getDBInfo()["dsn2"],
        //     $message
        // );
*/
    }

    echo "OK";
} catch (PDOException $e) {
    $isError = TRUE;
    // $message = $e->getMessage();
    // (new WebApiEmail())->send(
    //     $_SERVER["HTTP_HOST"].$_SERVER['SCRIPT_NAME'],
    //     $conn->getDBInfo()["dsn2"],
    //     $message
    // );
    // echo $e->getMessage().PHP_EOL;
} catch (\Exception $e) {
    // $isError = TRUE;
    // $message = $e->getMessage();
    // (new WebApiEmail())->send(
    //     $_SERVER["HTTP_HOST"].$_SERVER['SCRIPT_NAME'],
    //     "",
    //     "Failed to connect database"
    // );
    echo "EX".PHP_EOL;
    echo $e->getMessage();
}

function insertLog(DBConn $conn, array ...$paramList): OpResult
{
    $sql = "
INSERT INTO apps.sys_api_sql_log (
    sql_group_dtl_id, sql_group_name,
    sql_group_version, sql_name, sql, err_msg,
    request_user_id, request_username,
    request_body, response_body, request_app_version
)
SELECT :sql_group_dtl_id, :sql_group_name,
    :sql_group_version, :sql_name, :sql, :err_msg,
    :request_user_id, :request_username,
    :request_body, :response_body, :request_app_version;
    ";
    return $conn->exec($sql, SQLUtil::getParamList($sql, ...$paramList));
}

/**
 * Handles OpResult error. Does not handle DB connection error.
 */
function saveErrorReport(string $raw, OpResult $error): void
{
    $errorContext = $error->getContext();
    $sqlGroupName = $errorContext->getTag("sql_group_name");
    $errRow = $errorContext->getRawParam();
    $param = $errorContext->getSqlParam();
    $errMsg = $error->getErrMsg();
    $dir = "ErrorReport/$sqlGroupName";
    mkdir($dir, 0755, TRUE);    // Auto create directory if it doesn't exists.

    $fileName = $dir."/".date("Ymd_His", $_SERVER["REQUEST_TIME"]).".txt";
    $file = fopen($fileName, "w");
    if (!$file) {
        return;
    }

    fwrite($file, "Script name: ".$_SERVER["SCRIPT_NAME"]."\n");
    fwrite($file, "Query string: ".$_SERVER["QUERY_STRING"]."\n");
    fwrite($file, "Database: ".$errorContext->getTag("dsn2")."\n\n");
    fwrite($file, "Error message: \n$errMsg\n\n");
    fwrite($file, "Request body: \n$raw\n\n");
    fwrite($file, "Error row: \n".json_encode($errRow)."\n\n");
    fwrite($file, "Error sql: \n".$errorContext->getTag("sql")."\n\n");
    fwrite($file, "Required param: \n".json_encode($param)."\n\n");
    fwrite($file, "sql_group_dtl_id: ".$errorContext->getTag("sql_group_dtl_id")."\n\n");

    if ($file) {
        fclose($file);
    }

    chmod($fileName, 0755); // Grant permission so we can delete the file with terminal
}
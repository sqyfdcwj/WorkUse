<?php

header("Content-type:application/json");

require_once 'WebApiEmail.php';
require_once 'WebApiRequest.php';   // This file has required DBConn.php and SQLUtils.php

$webApiEmail = new WebApiEmail($_SERVER["HTTP_HOST"].$_SERVER['SCRIPT_NAME']);
$responseBody = ""; // The string to be returned

try {
    // $conn = DBConnExtension::xtraWithKey($_GET["key"]);
    $conn = DBConn::pg("10.50.50.226", 5434, "erp_kayue_trading__20231228", "postgres", "xtra!@#$%");
    $dsnShort = $conn->getDBInfo()["dsn2"];

    $request = new WebApiRequest(
        file_get_contents("php://input"), 
        is_numeric(basename(getcwd())) ? intval(basename(getcwd())) : 99999999
    );
    $result = $request->run($conn, TRUE);

    if ($result->getIsSuccess()) {
        $opResultList = $result->getOpResultList();
        foreach ($opResultList as $opResult) {
            if (!($opResult instanceof OpResult)) { continue; }

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

        $responseBody = getResponseBody(0, "", $body);
        $opLog = insertLog($conn, 
            $request->getRequestInfo(),     // request_app_version, request_user_id, request_username, request_body
            [ "sql_group_name" => implode("-", $request->getSqlGroupNameList()), "response_body" => $responseBody ]
        );
        if (!$opLog->getIsSuccess()) {
            $webApiEmail->sendDBOperationFailure($dsnShort, $opLog->getErrMsg());
        }
    } else {
        $lastError = $result->getLastError();
        $responseBody = getResponseBody(1, $lastError->getErrMsg());

        $opLog = insertLog($conn, 
            $request->getRequestInfo(),             // request_app_version, request_user_id, request_username, request_body
            $lastError->getContext()->getTags(),    // sql_group_dtl_id, sql_group_name, sql_id, sql_name, sql_group_version
            [ "err_msg" => $lastError->getErrMsg(), "response_body" => $responseBody ]
        );

        saveErrorReport($request->getRaw(), $lastError);    // save local copy

        $webApiEmail->sendDBOperationFailure($dsnShort, $lastError->getErrMsg());
        if (!$opLog->getIsSuccess()) {
            $webApiEmail->sendDBOperationFailure($dsnShort, $opLog->getErrMsg());
        }
    }
} catch (PDOException $e) {
    $webApiEmail->sendDBConnectionFailure($e->getMessage());
    $responseBody = getResponseBody(1, $e->getMessage());
} catch (\JsonException $e) {
    $webApiEmail->sendFree("Json Exception", [ "Message" => $e->getMessage() ]);
    $responseBody = getResponseBody(1, $e->getMessage());
} catch (\Exception $e) {
    $webApiEmail->sendFree("Exception", [ "Message" => $e->getMessage() ]);
    $responseBody = getResponseBody(1, $e->getMessage());
}

echo $responseBody;

# End of business logic

################################################################

function getResponseBody(int $code, string $message, array $body = []): string
{
    return json_encode([ "code" => $code, "message" => $message, "body" => $body ], JSON_UNESCAPED_UNICODE);
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
 * Write OpResult error to local file
 * 
 * @param string $requestBody
 * @param OpResult $error
 * @return void
 */
function saveErrorReport(string $requestBody, OpResult $error): void
{
    $errorContext = $error->getContext();
    $sqlGroupName = $errorContext->getTag("sql_group_name");
    $errRow = $errorContext->getRawParam();
    $param = $errorContext->getSqlParam();
    $errMsg = $error->getErrMsg();

    $requestDate = date("Ymd", $_SERVER["REQUEST_TIME"]);
    $requestTime = date("His", $_SERVER["REQUEST_TIME"]);

    $dir = "ErrorReport/$requestDate/$sqlGroupName";
    if (!is_dir($dir)) {
        if (mkdir($dir, 0755, TRUE)) {
            echo "mkdir success: $dir".PHP_EOL;
        } else {
            echo "mkdir failed: $dir".PHP_EOL;
        }
    } else {
        echo "$dir is dir".PHP_EOL;
    }

    $fileName = "$dir/$requestTime.txt";
    $file = fopen("$dir/$requestTime.txt", "w");
    if (!$file) {
        return;
    }

    $contentList = [
        "Script name" => $_SERVER["SCRIPT_NAME"],
        "Query string" => $_SERVER["QUERY_STRING"],
        "Database" => $errorContext->getTag("dsn2"),
        "Error message" => $errMsg,
        "Request body" => $requestBody,
        "Error row" => json_encode($errRow),
        "Required param" => json_encode($param),
        "sql_group_dtl_id" => $errorContext->getTag("sql_group_dtl_id"),
        "sql" => $errorContext->getTag("sql")
    ];

    foreach ($contentList as $k => $v) {
        fwrite($file, "$k:\n$v\n\n");
    }

    if ($file) {
        fclose($file);
    }

    chmod($fileName, 0755); // Grant permission so we can delete the file with terminal
}
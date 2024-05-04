<?php

require_once 'Lib/DBTask.php';

/**
 * DBTask::$body is confirmed to be Map<String, List>
 */
final class WebApiRequest extends DBTask
{
    private int $version = 0;
    public function getVersion(): int { return $this->version; }

    private string $raw = "";
    public function getRaw(): string { return $this->raw; }

    private ?int $requestUserId = NULL;
    private ?string $requestUsername = NULL;

    public function getRequestInfo(): array 
    { 
        return [
            "request_app_version" => $this->version,
            "request_user_id" => $this->requestUserId,
            "request_username" => $this->requestUsername,
            "request_body" => $this->raw,
            "request_ip" => $_SERVER["REMOTE_ADDR"],
            "request_port" => $_SERVER["REMOTE_PORT"]
        ];
    }

    /**
     * @return array All keys of DBTask::$body
     */
    public function getSqlGroupNameList(): array { return array_keys($this->body); }

    /**
     * @param $defaultVersion When failed to decode $version from the request body
     */
    public function __construct($raw, int $defaultVersion)
    {
        $this->raw = $raw;
        $json = json_decode($this->raw, TRUE);
        if ($json === NULL) {
            throw new \JsonException("Failed to decode JSON");
        }
        if (!isset($json["request"])) {
            throw new \JsonException("Field 'request' is not set");
        }
        if (!is_array($json["request"])) {
            throw new \JsonException("Field 'request' is not array");
        }
        $this->body = array_filter($json["request"], function ($k, $v) {
            return is_string($k) && is_array($v);
        }, ARRAY_FILTER_USE_BOTH);

        if (is_array($json["request_info"])) {
            $requestInfo = $json["request_info"];
            $this->version = is_numeric($requestInfo["request_app_version"])
                ? intval($requestInfo["request_app_version"])
                : $defaultVersion;
            $this->requestUserId = is_numeric($requestInfo["request_user_id"])
                ? intval($requestInfo["request_user_id"])
                : NULL;
            $this->requestUsername = is_string($requestInfo["request_username"])
                ? $requestInfo["request_username"]
                : NULL;
        } else {
            $this->version = $defaultVersion;
        }
    }

    /**
     * We don't need to append DBConn info in this function. DBTask::run will do that.
     */
    public function dryRun(DBConn $conn): array
    {
        $result = [];
        foreach ($this->body as $sqlGroupName => $sqlGroupNameRows) {
            // Assert this will never fail
            $opSqlGroupDtl = $this->getSqlGroupDtl($conn, [
                "sql_group_name" => $sqlGroupName, 
                "sql_group_version" => $this->version
            ]);
            foreach ($sqlGroupNameRows as $rowIdx => $row) {
                if (!is_array($row)) { continue; }
                foreach ($opSqlGroupDtl->getDataSet() as $sqlGroupDtl) {
                    $result[] = OpContext::nonTcl(
                        $sqlGroupDtl["sql"], 
                        $row,
                        array_merge($sqlGroupDtl, $this->getRequestInfo(), [ "row" => $rowIdx ])
                    );
                }
            }
        }
        return $result;
    }

    private function getSqlGroupDtl(DBConn $conn, array $param, array $tags = []): OpResult
    {
        $sql = "
SELECT sql_group_dtl_id, sql_group_name, sql_group_version,
    sql_name, sql, sql_order, sql_display_name, key_field
      
FROM apps.sys_api_sql_group_dtl
WHERE upper(sql_group_name) = upper(:sql_group_name)
AND sql_group_version IN (
    SELECT max(sql_group_version)
    FROM apps.sys_api_sql_group_dtl
    WHERE upper(sql_group_name) = upper(:sql_group_name)
    AND sql_group_version BETWEEN 0 AND :sql_group_version
)
ORDER BY sql_order;
        ";
        return $conn->exec($sql, $param, array_merge($tags, $conn->getDBInfo()));
    }

    protected function onTaskGetOpResult(OpResult $opResult): void
    {
        $this->errLog($opResult);
    }

    private function errLog(OpResult $opResult): void
    {
        $opContext = $opResult->getContext();
        $dsn2 = $opContext->getTag("dsn2");
        $scriptName = $_SERVER["SCRIPT_NAME"];
        if ($opContext->getIsTcl()) {
            $msg = $opContext->getSql();
            $this->outputMsg("$dsn2 | $msg | $scriptName");
        } else if ($opResult->getIsSuccess()) {
            $msg = "Success";
            $sqlName = $opContext->getTag("sql_name");
            $this->outputMsg("$dsn2 | $msg | $sqlName | $scriptName");
        } else {
            $msg = $opResult->getErrMsg();
            $sqlGroupName = $opContext->getTag("sql_group_name");
            $row = $opContext->getTag("row");
            $this->outputMsg("$dsn2 | $msg | sql_group_name = $sqlGroupName, row = $row | $scriptName");
        }
    }

    /**
     * Output message to error_log or output buffer (Display on screen) 
     */
    private function outputMsg(string $message, bool $toErrorLog = TRUE): void
    {
        if ($toErrorLog) {
            error_log($message);
        } else {
            echo $message.PHP_EOL;
        }
    }
}

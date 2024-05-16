<?php

namespace WebApiRequest;

use DBTask\DBTask;
use DBConn\DBConn;
use DBConn\DBResult;

/**
 * DBTask::$body is Map<String, List>
 */
class WebApiRequest extends DBTask
{
    private int $version = 0;
    public function getVersion(): int { return $this->version; }

    private string $raw = "";
    public function getRaw(): string { return $this->raw; }

    private ?int $requestUserId = null;
    private ?string $requestUsername = null;

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
     * @param mixed $raw The raw input
     * @param $defaultVersion When failed to decode $version from the request body
     * @throws \JsonException If failed to decode JSON, or decoded JSON does not fulfill requirement 
     */
    public function __construct($raw, int $defaultVersion)
    {
        $this->raw = $raw;
        $json = json_decode($this->raw, true);
        if ($json === null) {
            throw new \JsonException("Invalid JSON format");
        }
        if (!isset($json["request"])) {
            throw new \JsonException("Field 'request' is not set");
        } else if (!is_array($json["request"])) {
            throw new \JsonException("Field 'request' is not array");
        }

        parent::__construct(array_filter($json["request"], function ($v, $k) {
            return is_string($k) && is_array($v);
        }, ARRAY_FILTER_USE_BOTH));

        if (isset($json["request_info"]) && is_array($json["request_info"])) {
            $requestInfo = $json["request_info"];
            $this->version = is_numeric($requestInfo["request_app_version"])
                ? intval($requestInfo["request_app_version"])
                : $defaultVersion;
            $this->requestUserId = is_numeric($requestInfo["request_user_id"])
                ? intval($requestInfo["request_user_id"])
                : null;
            $this->requestUsername = is_string($requestInfo["request_username"])
                ? $requestInfo["request_username"]
                : null;
        } else {
            $this->version = $defaultVersion;
        }
    }

    protected function execBody(DBConn $conn): array
    {
        $opResultList = [];
        foreach ($this->body as $sqlGroupName => $sqlGroupNameRows) {
            $opSqlGroupDtl = $this->getSqlGroupDtl($conn, [
                "sql_group_name" => $sqlGroupName, 
                "sql_group_version" => $this->version
            ]);

            // If failed, log and return immediately
            if (!$opSqlGroupDtl->getIsSuccess()) {
                $this->onOpResult($opSqlGroupDtl);
                return [ $opSqlGroupDtl ];
            }

            foreach ($sqlGroupNameRows as $rowIdx => $row) {
                if (!is_array($row)) { continue; }
                foreach ($opSqlGroupDtl->getDataSet() as $sqlGroupDtl) {
                    $opResult = $conn->exec(
                        $sqlGroupDtl["sql"], 
                        $row,
                        array_merge($sqlGroupDtl, $this->getRequestInfo(), [ "row" => $rowIdx ])
                    );
                    $opResultList[] = $opResult;
                    $this->onOpResult($opSqlGroupDtl);
                    // If failed, return immediately
                    if (!$opResult->getIsSuccess()) {
                        return $opResultList;
                    }
                }
            }
        }
        return $opResultList;
    }

    /**
     * Get list of queries to be executed
     * @return DBResult
     */
    protected function getSqlGroupDtl(DBConn $conn, array $param): DBResult
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
        return $conn->exec($sql, $param, array_merge(
            $conn->getDBInfo(), 
            [ "function" => "getSqlGroupDtl" ]
        ));
    }

    protected function onOpResult(DBResult $opResult): void
    {
        $opContext = $opResult->getStmt();
        $dsnShort = $opContext->getTag("dsn_short");
        $scriptName = $_SERVER["SCRIPT_NAME"];

        $state = $opResult->getIsSuccess() ? "Succ" : "Fail";
        if ($opContext->getIsTcl()) {
            $sqlName = $opContext->getSql();
            error_log("$dsnShort | $state | $sqlName | $scriptName");
        } else {
            $sqlName = $opContext->getTag("sql_name");
            if ($opResult->getIsSuccess()) {
                error_log("$dsnShort | $state | $sqlName | $scriptName");
            } else {
                if ($opContext->getTag("function") === "getSqlGroupDtl") {
                    $sqlName = "WebApiRequest::getSqlGroupDtl";
                    error_log("$dsnShort | $state | $sqlName | $scriptName");
                    error_log($opResult->getErrMsg());
                    return;
                } 

                $sqlGroupName = $opContext->getTag("sql_group_name");
                $row = $opContext->getTag("row");
                error_log("$dsnShort | $state | $sqlName | Error loc: $sqlGroupName[$row] | $scriptName");
                error_log($opResult->getErrMsg());
            }
        }
    }
}

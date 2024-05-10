<?php

namespace WebApiRequest;

use DBTask\DBTask;
use DBConn\DBConn;
use DBConn\OpContext;
use DBConn\OpResult;
use DBTask\DBTaskResult;

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
        $this->body = array_filter($json["request"], function ($v, $k) {
            return is_string($k) && is_array($v);
        }, ARRAY_FILTER_USE_BOTH);

        if (isset($json["request_info"]) && is_array($json["request_info"])) {
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

    public function run(DBConn $conn, bool $useTransaction): DBTaskResult
    {
        $isError = FALSE;
        $opContextList = [];
        $opResultList = [];
        
        foreach ($this->body as $sqlGroupName => $sqlGroupNameRows) {
            $opSqlGroupDtl = $this->getSqlGroupDtl($conn, [
                "sql_group_name" => $sqlGroupName, 
                "sql_group_version" => $this->version
            ]);

            if (!$opSqlGroupDtl->getIsSuccess()) {
                $this->log($opSqlGroupDtl);
                return new DBTaskResult([ $opSqlGroupDtl ]);
            }

            foreach ($sqlGroupNameRows as $rowIdx => $row) {
                if (!is_array($row)) { continue; }
                foreach ($opSqlGroupDtl->getDataSet() as $sqlGroupDtl) {
                    $opContextList[] = OpContext::nonTcl(
                        $sqlGroupDtl["sql"], 
                        $row,
                        array_merge($sqlGroupDtl, $this->getRequestInfo(), [ "row" => $rowIdx ])
                    );
                }
            }
        }

        if ($useTransaction) {
            $opContext = OpContext::beginTransaction();
            $opContext->setTags($conn->getDBInfo());
            $opContextList = array_merge([ $opContext ], $opContextList);
        }

        foreach ($opContextList as $opContext) {
            if ($isError || !($opContext instanceof OpContext)) { 
                continue; 
            }
            $opContext->setTags($conn->getDBInfo());
            $opResult = $conn->execContext($opContext);
            $opResultList[] = $opResult;
            $this->log($opResult);
            if (!$opResult->getIsSuccess()) {
                $isError = TRUE;
            }
        }

        if ($useTransaction) {
            if (!$isError) {
                $opContext = OpContext::commit();
            } else {
                $opContext = OpContext::rollBack();
            }
            $opContext->setTags($conn->getDBInfo());
            $opContextList[] = $opContext;
            $opResult = $conn->execContext($opContext);
            $opResultList[] = $opResult;
            $this->log($opResult);
        }
        return new DBTaskResult($opResultList);
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

    /**
     * Write OpResult into error_log
     * @param OpResult $opResult 
     * @return void
     */
    private function log(OpResult $opResult): void
    {
        $opContext = $opResult->getContext();
        $dsnShort = $opContext->getTag("dsn_short");
        $scriptName = $_SERVER["SCRIPT_NAME"];
        if ($opContext->getIsTcl()) {
            $msg = $opContext->getSql();
            error_log("$dsnShort | $msg | $scriptName");
        } else if ($opResult->getIsSuccess()) {
            $msg = "Success";
            $sqlName = $opContext->getTag("sql_name");
            error_log("$dsnShort | $msg | $sqlName | $scriptName");
        } else {
            $msg = $opResult->getErrMsg();
            $sqlGroupName = $opContext->getTag("sql_group_name");
            $row = $opContext->getTag("row");
            error_log("$dsnShort | $msg | sql_group_name = $sqlGroupName, row = $row | $scriptName");
        }
    }
}
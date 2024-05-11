<?php

namespace WebApiRequest;

use DBTask\DBTask;
use DBTask\DBTaskResult;
use DBConn\DBConn;
use DBConn\OpContext;
use DBConn\OpResult;

/**
 * DBTask::$body is Map<String, List>
 */
class WebApiRequest extends DBTask
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
     * @param mixed $raw The raw input
     * @param $defaultVersion When failed to decode $version from the request body
     * @throws \JsonException
     */
    public function __construct($raw, int $defaultVersion)
    {
        $this->raw = $raw;
        $json = json_decode($this->raw, TRUE);
        if ($json === NULL) {
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
                : NULL;
            $this->requestUsername = is_string($requestInfo["request_username"])
                ? $requestInfo["request_username"]
                : NULL;
        } else {
            $this->version = $defaultVersion;
        }
    }

    /**
     * @param DBConn $conn
     * @param bool $useTransaction
     * @return DBTaskResult
     */
    public function run(DBConn $conn, bool $useTransaction = TRUE): DBTaskResult
    {
        $isError = FALSE;
        // Return directly if failed to open transaction 
        $opResultList = $this->beginTransaction($conn, $useTransaction);
        if (!$this->isAllSuccess($opResultList)) {
            return new DBTaskResult($opResultList);
        }

        $list = $this->execBody($conn);
        $opResultList = array_merge($opResultList, $list);
        $isError = !$this->isAllSuccess($opResultList);

        $list = $this->endTransaction($conn, $useTransaction, $isError);
        $opResultList = array_merge($opResultList, $list);
        return new DBTaskResult($opResultList);
    }

    protected function beginTransaction(DBConn $conn, bool $useTransaction): array
    {
        if (!$useTransaction) { return []; }
        $opResult = $conn->execContext(OpContext::begin($conn->getDBInfo()));
        $this->log($conn->getDSNShort(), $opResult);
        return [ $opResult ];
    }

    protected function endTransaction(DBConn $conn, bool $useTransaction, bool $isError): array
    {
        if (!$useTransaction) { return []; }
        $opResult = $isError
            ? $conn->execContext(OpContext::rollback($conn->getDBInfo()))
            : $conn->execContext(OpContext::commit($conn->getDBInfo()));
        $this->log($conn->getDSNShort(), $opResult);
        return [ $opResult ];
    }

    /**
     * Iterate DBTask::body and exec SQL for each element.
     * @param DBConn $conn
     * @return array
     */
    protected function execBody(DBConn $conn): array
    {
        $opResultList = [];
        $dsnShort = $conn->getDSNShort();
        foreach ($this->body as $sqlGroupName => $sqlGroupNameRows) {
            $opSqlGroupDtl = $this->getSqlGroupDtl($conn, [
                "sql_group_name" => $sqlGroupName, 
                "sql_group_version" => $this->version
            ]);

            // If failed, log and return immediately
            if (!$opSqlGroupDtl->getIsSuccess()) {
                $this->log($dsnShort, $opSqlGroupDtl);
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
                    $this->log($dsnShort, $opResult);   // Always log
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
     * Whether given OpResult array has no element where failed
     * @param array $opResultList OpResult array
     * @return bool
     */
    protected function isAllSuccess(array $opResultList): bool
    {
        $fnIsError = function ($v) { return ($v instanceof OpResult) && !$v->getIsSuccess(); };
        return empty(array_filter($opResultList, $fnIsError));
    }

    /**
     * Get list of queries to be executed
     * @return OpResult
     */
    protected function getSqlGroupDtl(DBConn $conn, array $param): OpResult
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

    /**
     * Write OpResult info to error_log
     * @param OpResult $opResult 
     * @return void
     */
    private function log(string $dsnShort, OpResult $opResult): void
    {
        $opContext = $opResult->getContext();
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

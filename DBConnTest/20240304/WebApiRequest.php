<?php

require_once 'Lib/DBTask.php';

/**
 * In this class, ADBTask::$body is confirmed to be Map<String, List>
 */
final class WebApiRequest extends DBTask
{
    protected int $version = 0;
    public function getVersion(): int { return $this->version; }

    protected string $raw = "";
    public function getRaw(): string { return $this->raw; }

    /**
     * @param $version The value should be retrieved by calling intval(basename(getcwd()))
     */
    public function __construct($raw, int $version)
    {
        $this->raw = $raw;
        $this->version = $version;
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
        $this->body = $json["request"];
    }

    /**
     * We don't need to append DBConn info in this function.
     * ADBTask::run will do it for us
     */
    public function dryRun(DBConn $conn): DBTaskMidResult
    {
        $result = [];
        foreach ($this->body as $sqlGroupName => $sqlGroupNameRows) {
            // Assert this will never fail ...
            $opSqlGroupDtl = $this->getSqlGroupDtl($conn, [
                "sql_group_name" => $sqlGroupName, 
                "sql_group_version" => $this->version
            ]);
            foreach ($sqlGroupNameRows as $rowIdx => $row) {
                foreach ($opSqlGroupDtl->getDataSet() as $sqlGroupDtl) {
                    $result[] = OpContext::nonTcl(
                        $sqlGroupDtl["sql"], 
                        $row,
                        array_merge($sqlGroupDtl, [ "row" => $rowIdx + 1 ])
                    );
                }
            }
        }
        return new DBTaskMidResult($result);
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
        // If you need to write error log, do it inside this function
        // var_dump($opResult);

        $opContext = $opResult->getContext();
        $dsn2 = $opContext->getTag("dsn2");
        $scriptName = $_SERVER["SCRIPT_NAME"];
        if ($opContext->getIsTcl()) {
            $msg = $opContext->getSql();
            echo "$dsn2 | $msg | $scriptName".PHP_EOL;
        } else if ($opResult->getIsSuccess()) {
            $msg = "Success";
            $sqlName = $opContext->getTag("sql_name");
            echo "$dsn2 | $msg | $sqlName | $scriptName".PHP_EOL;
        } else {
            $msg = $opResult->getErrMsg();
            $sqlGroupName = $opContext->getTag("sql_group_name");
            $row = $opContext->getTag("row");
            echo "$dsn2 | $msg | sql_group_name = $sqlGroupName, row = $row | $scriptName".PHP_EOL;
        }
    }

    public function getSqlGroupNameList(): array
    {
        return array_keys($this->body);
    }
}

<?php

require_once 'DataSource.php';  // This file has required DBConn.php

/**
 * Concrete class
 */
class WebApiRequest extends DBTask
{
    protected int $version = 0;
    public function getVersion(): int { return $this->version; }

    protected string $raw = "";
    public function getRaw(): string { return $this->raw; }

    public function __construct(int $version = 0)
    {
        $this->raw = file_get_contents("php://input");
        $json = json_decode($this->raw, TRUE);
        if ($json === NULL) {
            throw new JsonException("Failed to decode JSON");
        }
        if (!isset($json["request"])) {
            throw new JsonException("Field 'request' is not set");
        }
        if (!is_array($json["request"])) {
            throw new JsonException("Field 'request' is not array");
        }
        $this->input = $json["request"];
        if ($version > 0) {
            $this->version = $version;
        } else {
            $this->version = intval(basename(getcwd()));
            if ($this->version === 0) {
                $this->version = 20231119;  // Default version. User should maintain this
            }
        }
    }

    public function dryRun(DBConn $conn): DBTaskMidResult
    {
        $result = [];
        foreach ($this->input as $sqlGroupName => $paramList) {
            $opSqlGroupDtl = $this->getSqlGroupDtl($conn, [
                "sql_group_name" => $sqlGroupName, 
                "sql_group_version" => $this->version
            ]);
            foreach ($paramList as $param) {
                foreach ($opSqlGroupDtl->getDataSet() as $sqlGroupDtl) {
                    $result[] = OpContext::nonTcl(
                        $sqlGroupDtl["sql"], 
                        SQLUtil::getParamList($sqlGroupDtl["sql"], $param), 
                        $sqlGroupDtl
                    );
                }
            }
        }
        return new DBTaskMidResult($result);
    }

    private function getSqlGroupDtl(DBConn $conn, array $param, array $tags = []): OpResult
    {
        $sql = "
SELECT d.sql_group_dtl_id, d.sql_group_name, d.sql_group_version,
    d.sql_name, d.sql, d.sql_order, d.sql_display_name, d.key_field

FROM apps.sys_api_sql_group_dtl d
WHERE upper(d.sql_group_name) = upper(:sql_group_name)
AND d.sql_group_version IN (
    SELECT max(sql_group_version)
    FROM apps.sys_api_sql_group_dtl
    WHERE upper(sql_group_name) = upper(:sql_group_name)
    AND sql_group_version BETWEEN 0 AND :sql_group_version
)
ORDER BY d.sql_order;
        ";
        return $conn->exec($sql, $param, $tags);
    }

    /**
     * This function SHOULD guarantee that the connection is not in an active transaction
     * Do something that needs to be done after calling parent::run
     * E.g. Insert into log table
     */
    public function run(DBConn $conn, $useTransaction = TRUE): DBTaskResult
    {
        $dbTaskResult = parent::run($conn, $useTransaction);
        $lastError = $dbTaskResult->getLastError();
        $isError = $lastError !== NULL;

        $sql = "
INSERT INTO apps.sys_api_sql_log (
    sql_group_dtl_id, sql_group_name, sql_group_version,
    sql_name, sql, err_msg,
    request_xml, response_xml
)
SELECT :sql_group_dtl_id, :sql_group_name, :sql_group_version,
    :sql_name, :sql,
    :response_xml, :response_xml;
        ";
        
        if ($isError) {
            $param = SQLUtil::getParamList(
                $sql, 
                $lastError->getContext()->getTags(),
                [
                    "request_xml" => $_SERVER["SERVER_NAME"].$_SERVER["REQUEST_URI"],
                    "response_xml" => file_get_contents("php://input")
                ]
            );
        } else {
            $param = SQLUtil::getParamList(
                $sql, 
                [
                    "request_xml" => $_SERVER["SERVER_NAME"].$_SERVER["REQUEST_URI"],
                    "response_xml" => file_get_contents("php://input")
                ]
            );
        }

        // $conn->exec($sql, $param);

        return $dbTaskResult;
    }

    /**
     * Called after invoked function that returns a OpResult
     */
    protected function onTaskGetOpResult(OpResult $opResult): void
    {
        // If you need to writer error log, do it inside this function
    }
}

?>
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
        $this->body = $json["request"];
        $this->body = array_filter($this->body, function ($k, $v) {
            return is_string($k) && is_array($v);
        }, ARRAY_FILTER_USE_BOTH);
        if ($version > 0) {
            $this->version = $version;
        } else {
            $this->version = intval(basename(getcwd()));
            if ($this->version === 0) {
                $this->version = 20231119;  // Default version. User should maintain this
            }
        }
    }

    public function dryRun(DBConn $conn): array
    {
        $result = [];
        foreach ($this->body as $sqlGroupName => $paramList) {
            $opSqlGroupDtl = $this->getSqlGroupDtl($conn, [
                "sql_group_name" => $sqlGroupName, 
                "sql_group_version" => $this->version
            ]);
            foreach ($paramList as $param) {
                if (!is_array($param)) { continue; }
                foreach ($opSqlGroupDtl->getDataSet() as $sqlGroupDtl) {
                    $result[] = OpContext::nonTcl($sqlGroupDtl["sql"], $param, $sqlGroupDtl);
                }
            }
        }
        return $result;
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
}
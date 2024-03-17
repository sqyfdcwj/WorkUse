<?php

/**
 * Provides PDO functionality and holds database connection info
 */
final class DBConn
{
    private array $dbInfo = [];

    /**
     * Available keys:
     * driver: Database driver. Possible values:
     * pgsql - PostgreSQL
     * mssql - Microsoft Server
     * 
     * host: Database host
     * port: Database port
     * dbname: Database name
     * dsn: DataSource name which can be used in PDO::__construct
     * dsn2: DataSource name which is more readable, does not contain driver name.
     * @return array Database info
     */
    public function getDBInfo(): array { return $this->dbInfo; }
    
    private \PDO $pdo;

    public function __construct(
        string $driver, string $host, int $port, string $dbname, 
        string $user, string $pwd
    ) {
        $dsn = self::getDSN($driver, $host, $port, $dbname);
        $this->dbInfo["driver"] = $driver;
        $this->dbInfo["host"] = $host;
        $this->dbInfo["port"] = $port;
        $this->dbInfo["dbname"] = $dbname;
        $this->dbInfo["dsn"] = $dsn;
        $this->dbInfo["dsn2"] = "$host:$port $dbname";
        $options = [
            \PDO::ATTR_ERRMODE => \PDO::ERRMODE_EXCEPTION,
            \PDO::ATTR_TIMEOUT => 1
        ];
        // Potential PDOException, should be handled properly.
        $this->pdo = new \PDO($dsn, $user, $pwd, $options);
    }

    public static function getDSN(string $driver, string $host, int $port, string $dbname): string 
    {
        if ($driver === "pgsql") {
            return "pgsql:host=$host;port=$port;dbname=$dbname";
        } else if ($driver === "sqlsrv") {
            return "sqlsrv:Server=$host,$port;Database=$dbname";
        } else {
            return "";
        }
    }
    public static function pg(string $host, int $port, string $dbname, string $user, string $pwd): self 
    { return new DBConn("pgsql", $host, $port, $dbname, $user, $pwd); }

    public static function mssql(string $host, int $port, string $dbname, string $user, string $pwd): self
    { return new DBConn("sqlsrv", $host, $port, $dbname, $user, $pwd); }

    public function inTransaction(): bool { return $this->pdo->inTransaction(); }

    public function beginTransaction(): OpResult { return $this->execContext(OpContext::beginTransaction()); }

    public function commit(): OpResult { return $this->execContext(OpContext::commit()); }

    public function rollBack(): OpResult { return $this->execContext(OpContext::rollBack()); }

    /**
     * 
     */
    public function exec(
        string $sql, 
        array $rawParam = [],
        array $tags = [], 
        bool $isThrowEx = FALSE
    ): OpResult
    { return $this->execContext(OpContext::nonTcl($sql, $rawParam, $tags), $isThrowEx); }

    /**
     * Perform database action with given OpContext.
     * 
     * @param OpContext $opContext 
     * @param bool $isThrowEx Whether to rethrow the PDOException caught in this function
     * 
     * @throws \PDOException
     * @return OpResult 
     */
    public function execContext(OpContext $opContext, bool $isThrowEx = FALSE): OpResult
    {
        $isSuccess = TRUE;
        $sqlState = "";
        $errMsg = "";
        $rowCount = 0;
        $dataSet = [];
        $trace = "";
        try {
            if ($opContext->getIsTcl()) {
                switch ($opContext->getSql()) {
                    case "beginTransaction":
                        $isSuccess = $this->pdo->beginTransaction();
                        break;
                    case "commit":
                        $isSuccess = $this->pdo->commit();
                        break;
                    case "rollBack":
                        $isSuccess = $this->pdo->rollBack();
                        break;
                }
            } else {
                $stmt = $this->pdo->prepare($opContext->getSql());            
                $isSuccess = $stmt->execute($opContext->getSqlParam());
                $sqlState = $stmt->errorCode() ?? "";
                $dataSet = $stmt->fetchAll(\PDO::FETCH_ASSOC);
                $rowCount = $stmt->rowCount();
            }
            $trace = "";
        } catch (\PDOException $e) {
            if ($isThrowEx) {
                throw $e;
            } else {
                $isSuccess = FALSE;
                $errMsg = $e->getMessage();
                $trace = $e->getTraceAsString();
            }
        }
        return new OpResult($opContext, $isSuccess, $sqlState, $errMsg, $rowCount, $dataSet, $trace);
    }
}
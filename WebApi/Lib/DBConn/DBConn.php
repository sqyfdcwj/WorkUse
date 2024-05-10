<?php

namespace DBConn;

use DBConn\OpContext;
use DBConn\OpResult;


/**
 * Provides PDO functionality and holds database connection info
 */
final class DBConn
{
    private array $dbInfo = [];

    /**
     * @return array Database info, available keys:
     * host: Database host
     * port: Database port
     * dbname: Database name
     * dsn: DataSource name which can be used in PDO::__construct
     * dsn2: DataSource name which is more readable, does not contain driver name
     */
    public function getDBInfo(): array { return $this->dbInfo; }

    public function getDriver(): string { return $this->dbInfo["driver"]; }
    public function getHost(): string { return $this->dbInfo["host"]; }
    public function getPort(): int { return $this->dbInfo["port"]; }
    public function getDBName(): string { return $this->dbInfo["dbname"]; }
    public function getDSN(): string { return $this->dbInfo["dsn"]; }
    public function getDSNShort(): string { return $this->dbInfo["dsn_short"]; }
    
    private \PDO $pdo;

    public function __construct(
        string $driver, string $host, int $port, string $dbname, 
        string $user, string $pwd
    ) {
        $dsn = self::makeDSN($driver, $host, $port, $dbname);
        $this->dbInfo["driver"] = $driver;
        $this->dbInfo["host"] = $host;
        $this->dbInfo["port"] = $port;
        $this->dbInfo["dbname"] = $dbname;
        $this->dbInfo["dsn"] = $dsn;
        $this->dbInfo["dsn_short"] = self::makeDSNShort($host, $port, $dbname);
        $options = [
            \PDO::ATTR_ERRMODE => \PDO::ERRMODE_EXCEPTION
        ];
        $this->pdo = new \PDO($dsn, $user, $pwd, $options); // PDOException
    }

    public static function makeDSN(string $driver, string $host, int $port, string $dbname): string 
    {
        if ($driver === "pgsql") {
            return "pgsql:host=$host;port=$port;dbname=$dbname";
        } else if ($driver === "sqlsrv") {
            return "sqlsrv:Server=$host,$port;Database=$dbname";
        } else {
            return "";
        }
    }

    public static function makeDSNShort(string $host, int $port, string $dbname): string 
    {
        return "$host:$port $dbname";   
    }

    public static function pg(string $host, int $port, string $dbname, string $user, string $pwd): self 
    { return new DBConn("pgsql", $host, $port, $dbname, $user, $pwd); }

    public static function mssql(string $host, int $port, string $dbname, string $user, string $pwd): self
    { return new DBConn("sqlsrv", $host, $port, $dbname, $user, $pwd); }

    public function inTransaction(): bool { return $this->pdo->inTransaction(); }

    /**
     * @throws \PDOException Active transaction
     * @return OpResult
     */
    public function beginTransaction(bool $isThrowEx = FALSE): OpResult 
    { 
        return $this->execContext(OpContext::beginTransaction(), $isThrowEx); 
    }

    /**
     * @throws \PDOException No active transaction
     * @return OpResult
     */
    public function commit(bool $isThrowEx = FALSE): OpResult 
    { 
        return $this->execContext(OpContext::commit(), $isThrowEx); 
    }

    /**
     * @throws \PDOException No active transaction
     * @return OpResult
     */
    public function rollBack(bool $isThrowEx = FALSE): OpResult 
    { 
        return $this->execContext(OpContext::rollBack(), $isThrowEx); 
    }

    /**
     * Execute a query with parameter and get result
     * @var string $sql SQL string
     * @var array $param Parameters
     * @var array $tags Custom tags
     * @var bool $isThrowEx Whether to throw caught PDOException
     * @throws \PDOException 
     * @return OpResult
     */
    public function exec(string $sql, array $param = [], array $tags = [], bool $isThrowEx = FALSE): OpResult
    { 
        return $this->execContext(OpContext::nonTcl($sql, $param, $tags), $isThrowEx); 
    }

    /**
     * Perform database action with given OpContext.
     * @param OpContext $opContext 
     * @param bool $isThrowEx Whether to throw caught PDOException
     * @throws \PDOException
     * @return OpResult 
     */
    public function execContext(OpContext $opContext, bool $isThrowEx = FALSE): OpResult
    {
        $sqlState = "";
        $rowCount = 0;
        $dataSet = [];
        $caughtEx = NULL;
        try {
            if ($opContext->getIsTcl()) {
                // If TCL operation raised exception, sqlState will be NULL
                switch ($opContext->getSql()) {
                    case "beginTransaction":
                        $this->pdo->beginTransaction();
                        break;
                    case "commit":
                        $this->pdo->commit();
                        break;
                    case "rollBack":
                        $this->pdo->rollBack();
                        break;
                }
            } else {
                $stmt = $this->pdo->prepare($opContext->getSql());            
                $stmt->execute($opContext->getSqlParam());
                $sqlState = $stmt->errorCode() ?? "";
                $dataSet = $stmt->fetchAll(\PDO::FETCH_ASSOC);
                $rowCount = $stmt->rowCount();
            }
        } catch (\PDOException $e) {
            if ($isThrowEx) {
                throw $e;
            } else {
                $caughtEx = $e;
                $sqlState = $e->getCode() ?? "";
            }
        }

        return new OpResult(
            $opContext,
            $caughtEx,
            $sqlState,
            $rowCount,
            $dataSet
        );
    }
}
<?php

namespace DBConn;

use DBConn\DBStmt;
use DBConn\DBResult;

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
     * @param array $tags
     * @param bool $isThrowEx
     * @throws \PDOException Active transaction
     * @return DBResult
     */
    public function begin(array $tags = [], bool $isThrowEx = false): DBResult 
    { 
        return $this->execContext(DBStmt::begin($tags), $isThrowEx); 
    }

    /**
     * @param array $tags
     * @param bool $isThrowEx
     * @throws \PDOException No active transaction
     * @return DBResult
     */
    public function commit(array $tags = [], bool $isThrowEx = false): DBResult 
    { 
        return $this->execContext(DBStmt::commit($tags), $isThrowEx); 
    }

    /**
     * @param array $tags
     * @param bool $isThrowEx
     * @throws \PDOException No active transaction
     * @return DBResult
     */
    public function rollback(array $tags = [], bool $isThrowEx = false): DBResult 
    { 
        return $this->execContext(DBStmt::rollback($tags), $isThrowEx); 
    }

    /**
     * Execute a query with parameter and get result
     * @var string $sql SQL string
     * @var array $param Parameters
     * @var array $tags Custom tags
     * @var bool $isThrowEx Whether to throw caught PDOException
     * @throws \PDOException 
     * @return DBResult
     */
    public function exec(string $sql, array $param = [], array $tags = [], bool $isThrowEx = false): DBResult
    { 
        return $this->execContext(DBStmt::nonTcl($sql, $param, $tags), $isThrowEx); 
    }

    /**
     * Perform database action with given DBStmt.
     * @param DBStmt $stmt 
     * @param bool $isThrowEx Whether to throw caught PDOException
     * @throws \PDOException
     * @return DBResult 
     */
    public function execContext(DBStmt $stmt, bool $isThrowEx = false): DBResult
    {
        $sqlState = "";
        $rowCount = 0;
        $dataSet = [];
        $caughtEx = null;
        $execTime = 0;
        try {
            if ($stmt->getIsTcl()) {
                // If TCL operation raised exception, sqlState will be null
                switch ($stmt->getSql()) {
                    case "begin":
                        $this->pdo->beginTransaction();
                        break;
                    case "commit":
                        $this->pdo->commit();
                        break;
                    case "rollback":
                        $this->pdo->rollback();
                        break;
                }
            } else {
                $pdoStmt = $this->pdo->prepare($stmt->getSql());     
                $startTime = microtime(true);       
                $pdoStmt->execute($stmt->getSqlParam());
                $endTime = microtime(true);
                $execTime = $endTime - $startTime;
                $sqlState = $pdoStmt->errorCode() ?? "";
                $dataSet = $pdoStmt->fetchAll(\PDO::FETCH_ASSOC);
                $rowCount = $pdoStmt->rowCount();
            }
        } catch (\PDOException $e) {
            if ($isThrowEx) {
                throw $e;
            } else {
                $caughtEx = $e;
                $sqlState = $e->getCode() ?? "";
            }
        }

        return new DBResult(
            $stmt,
            $caughtEx,
            $sqlState,
            $rowCount,
            $dataSet
        );
    }
}
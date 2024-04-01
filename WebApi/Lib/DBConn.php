<?php

require_once 'SQLUtil.php';

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
    
    private PDO $pdo;

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
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION
        ];
        // Potential PDOException, should be handled properly.
        $this->pdo = new PDO($dsn, $user, $pwd, $options);
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

    public function beginTransaction(bool $isThrowEx = FALSE): OpResult 
    { 
        return $this->execContext(OpContext::beginTransaction(), $isThrowEx); 
    }

    public function commit(bool $isThrowEx = FALSE): OpResult 
    { 
        return $this->execContext(OpContext::commit(), $isThrowEx); 
    }

    public function rollBack(bool $isThrowEx = FALSE): OpResult 
    { 
        return $this->execContext(OpContext::rollBack(), $isThrowEx); 
    }

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
     * @throws PDOException
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
                $dataSet = $stmt->fetchAll(PDO::FETCH_ASSOC);
                $rowCount = $stmt->rowCount();
            }
        } catch (PDOException $e) {
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

################################################################

final class OpContext
{
    /**
     * If $this->isTcl is true, the value is one of the following values:
     * beginTransaction
     * commit
     * rollBack
     * 
     * otherwise, the value will be the SQL string  
     */
    private string $sql = "";
    public function getSql(): string { return $this->sql; }


    private array $rawParam = [];
    public function getRawParam(): array { return $this->rawParam; }

    private array $sqlParam = [];
    public function getSqlParam(): array { return $this->sqlParam; }

    /**
     * Is Transaction Control Language (begin / commit / rollBack)
     */
    private bool $isTcl = FALSE;
    public function getIsTcl(): bool { return $this->isTcl; }

    /**
     * Custom tags used for storing external info or fields
     */
    private array $tags = [];
    public function setTags(array $tags): void
    {
        foreach ($tags as $key => $val) {
            if (is_int($val) || is_string($val) || is_float($val)) {
                $this->setTag($key, $val);
            }
        }
    }

    public function getTags(): array { return $this->tags; }

    public function setTag(string $key, string $tag): void { $this->tags[$key] = $tag; }
    public function getTag(string $key): string { return $this->tags[$key] ?? ""; }

    private function __construct(string $sql, array $rawParam, bool $isTcl, array $tags = []) 
    {
        $this->sql = $sql;
        $this->rawParam = $rawParam;
        $this->sqlParam = SQLUtil::getParamList($sql, $rawParam);
        $this->isTcl = $isTcl;
        $this->tags = $tags;
    }

    public static function beginTransaction(): self { return new OpContext(__FUNCTION__, [], TRUE); }
    public static function commit(): self { return new OpContext(__FUNCTION__, [], TRUE); }
    public static function rollBack(): self { return new OpContext(__FUNCTION__, [], TRUE); }

    public static function nonTcl(string $sql, array $rawParam, array $tags = []): self 
    { return new OpContext($sql, $rawParam, FALSE, $tags); }
}

################################################################

final class OpResult
{
    private OpContext $ctxt;
    public function getContext(): OpContext { return $this->ctxt; }

    /**
     * @var string $sqlState 5-Digit String
     */
    private string $sqlState = "";
    public function getSqlState(): string { return $this->sqlState; }

    private ?Exception $ex = NULL;
    public function getException(): ?Exception { return $this->ex; }

    public function getIsSuccess(): bool { return $this->ex === NULL; }

    /**
     * @var string $errMsg Error message. Empty when there is no error.
     */
    public function getErrMsg(): string 
    { 
        return $this->ex === NULL ? "" : $this->ex->getMessage(); 
    }

    /**
     * @var string PDOException::getTraceAsString(). Empty when there is no error.
     */
    public function getTrace(): string 
    { 
        return $this->ex === NULL ? "" : $this->ex->getTraceAsString(); 
    }

    /**
     * The number of rows affected by a INSERT / UPDATE / DELETE statement,
     * or the number of rows returned by a SELECT statement
     */
    private int $rowCount = 0;
    public function getRowCount(): int { return $this->rowCount; }

    private array $dataSet = [];
    public function getDataSet(): array { return $this->dataSet; }

    public function __construct(
        OpContext $ctxt,
        ?Exception $ex,
        string $sqlState, 
        int $rowCount, 
        array $dataSet
    ) {
        $this->ctxt = $ctxt;
        $this->ex = $ex;
        $this->sqlState = $sqlState;
        $this->rowCount = $rowCount;
        $this->dataSet = $dataSet;
    }
}
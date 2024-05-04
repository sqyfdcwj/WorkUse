<?php

require_once 'SQLUtil.php';

/**
 * Provides PDO functionality and holds database connection info
 */
final class DBConn
{
    /**
     * @var array $dbInfo Database info, available keys:
     * host: Database host
     * port: Database port
     * dbname: Database name
     * dsn: DataSource name which can be used in PDO::__construct
     * dsn2: DataSource name which is more readable, does not contain driver name
     */
    private array $dbInfo = [];
    public function getDBInfo(): array { return $this->dbInfo; }
    
    /**
     * The internal PDO object which provides database functionality
     * @var PDO $pdo
     */
    private PDO $pdo;

    /**
     * @param string $driver Database driver
     * @param string $host Database host
     * @param int $port Database port
     * @param string $dbname Database name
     * @param string $user Database user
     * @param string $pwd Database password
     * @throws PDOException When failed to connect database
     */
    public function __construct(
        string $driver, string $host, int $port, string $dbname, 
        string $user, string $pwd
    ) {
        $dsn = self::getDSN($driver, $host, $port, $dbname);
        $this->dbInfo = [
            "driver" => $driver, "host" => $host, "port" => $port, 
            "dbname" => $dbname, "dsn" => $dsn, "dsn2" => "$host:$port $dbname"
        ];
        $options = [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION
        ];
        $this->pdo = new PDO($dsn, $user, $pwd, $options);  // Potential PDOException
    }

    /**
     * Get a datasource name string which can be used as 1st param of PDO::__construct
     * @param string $driver Database driver, supported values: pgsql(PostgreSQL), mssql(Microsoft Server)
     * @param string $host Database host
     * @param int $port Database port
     * @param string $dbname Database name
     * @return string
     */
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

    /**
     * Get a PostgreSQL connection
     * @return self
     */
    public static function pg(string $host, int $port, string $dbname, string $user, string $pwd): self 
    { return new DBConn("pgsql", $host, $port, $dbname, $user, $pwd); }

    /**
     * Get a Microsoft Server connection
     */
    public static function mssql(string $host, int $port, string $dbname, string $user, string $pwd): self
    { return new DBConn("sqlsrv", $host, $port, $dbname, $user, $pwd); }

    public function inTransaction(): bool { return $this->pdo->inTransaction(); }

    /**
     * @throws PDOException If the connection has already an active transaction
     * @return OpResult
     */
    public function beginTransaction(bool $isThrowEx = FALSE): OpResult 
    { 
        return $this->execContext(OpContext::beginTransaction(), $isThrowEx); 
    }

    /**
     * @throws PDOException If the connection has no active transaction
     * @return OpResult
     */
    public function commit(bool $isThrowEx = FALSE): OpResult 
    { 
        return $this->execContext(OpContext::commit(), $isThrowEx); 
    }

    /**
     * @throws PDOException If the connection has no active transaction
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
     * @throws PDOException 
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
                // sqlState will be NULL if PDOException is raised by a TCL operation
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

        return new OpResult($opContext, $caughtEx, $sqlState, $rowCount, $dataSet);
    }
}

################################################################

final class OpContext
{
    /**
     * @var string $sql The SQL string used to construct a PDOStatement.
     * If $isTcl is true, the value will be replaced by the corresponding value (begin / commit / rollBack)
     */
    private string $sql = "";
    public function getSql(): string { return $this->sql; }

    /**
     * @var array $rawParam Parameters injected into this class
     * It is not necessarily that each value in this array will be used by the PDOStatement
     */
    private array $rawParam = [];
    public function getRawParam(): array { return $this->rawParam; }

    /**
     * @var array $sqlParam Params used by the PDOStatement
     */
    private array $sqlParam = [];
    public function getSqlParam(): array { return $this->sqlParam; }

    /**
     * @var bool $isTcl Whether the statement is a transaction control language (begin / commit / rollBack)
     */
    private bool $isTcl = FALSE;
    public function getIsTcl(): bool { return $this->isTcl; }

    /**
     * @var array $tags Custom assoc array storing external info for reference
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

    /**
     * @param string $sql SQL query string
     * @param array $rawParam SQL statement parameter
     * @param bool $isTcl Whether the statement is a transaction control language (begin / commit / rollBack)
     * @param array $tags Custom string key-value paired array storing external info for reference
     */
    private function __construct(string $sql, array $rawParam, bool $isTcl, array $tags = []) 
    {
        $this->sql = $sql;
        $this->rawParam = $rawParam;
        $this->sqlParam = SQLUtil::getParamList($sql, $rawParam);
        $this->isTcl = $isTcl;
        $this->tags = $tags;
    }

    /**
     * Get a beginTransaction tcl command
     * @return self
     */
    public static function beginTransaction(array $tags = []): self { return new OpContext(__FUNCTION__, [], TRUE, $tags); }
    
    /**
     * Get a commit tcl command
     * @return self
     */
    public static function commit(array $tags = []): self { return new OpContext(__FUNCTION__, [], TRUE, $tags); }
    
    /**
     * Get a rollBack tcl command
     * @return self
     */
    public static function rollBack(array $tags = []): self { return new OpContext(__FUNCTION__, [], TRUE, $tags); }

    /**
     * Create a non-tcl command
     * @return self
     */
    public static function nonTcl(string $sql, array $rawParam, array $tags = []): self 
    { return new OpContext($sql, $rawParam, FALSE, $tags); }
}

################################################################

final class OpResult
{
    private OpContext $ctxt;
    public function getContext(): OpContext { return $this->ctxt; }

    /**
     * @var string $sqlState 5-Digit String retrievied from PDO::errorInfo / PDOStatement::errorInfo / PDOException::errorInfo
     */
    private string $sqlState = "";
    public function getSqlState(): string { return $this->sqlState; }

    /**
     * @var ?Exception $ex Caught exception. In most case this is a PDOException instance
     */
    private ?Exception $ex = NULL;
    public function getException(): ?Exception { return $this->ex; }

    public function getIsSuccess(): bool { return $this->ex === NULL; }

    /**
     * @return string Exception message if not null, otherwise empty string
     */
    public function getErrMsg(): string { return $this->ex === NULL ? "" : $this->ex->getMessage(); }

    /**
     * @return string Exception trace if not null, otherwise empty string
     */
    public function getTrace(): string { return $this->ex === NULL ? "" : $this->ex->getTraceAsString(); }

    /**
     * @var int $rowCount Number of rows returned from SELECT statement, or affected by INSERT / UPDATE / DELETE statement
     */
    private int $rowCount = 0;
    public function getRowCount(): int { return $this->rowCount; }

    /**
     * @var array $dataSet Rows returned by SELECT statement, or INSERT / UPDATE / DELETE statement with keyword 'RETURNING'
     */
    private array $dataSet = [];
    public function getDataSet(): array { return $this->dataSet; }

    /**
     * @param OpContext
     * @param ?Exception $ex Caught exception
     * @param string $sqlState
     * @param int $rowCount Number of rows returned from SELECT statement, or affected by INSERT / UPDATE / DELETE statement
     * @param array $dataSet Rows returned from a SELECT statement or INSERT / UPDATE / DELETE statement with keyword 'RETURNING'
     */
    public function __construct(OpContext $ctxt, ?Exception $ex, string $sqlState, int $rowCount, array $dataSet) 
    {
        $this->ctxt = $ctxt;
        $this->ex = $ex;
        $this->sqlState = $sqlState;
        $this->rowCount = $rowCount;
        $this->dataSet = $dataSet;
    }
}
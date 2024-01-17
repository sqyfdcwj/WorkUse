<?php

namespace Eric;

/**
 * The core class used to perform database action
 */
class DBConn
{
    private array $dbInfo = [];
    public function getDBInfo(): array { return $this->dbInfo; }
    
    private \PDO $pdo;

    /**
     * @throws \PDOException When failed to connect database
     */
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
        $options = [
            \PDO::ATTR_ERRMODE => \PDO::ERRMODE_EXCEPTION
        ];

        // Potential PDOException 
        $this->pdo = new \PDO($dsn, $user, $pwd, $options);
    }

    /**
     * Get a datasource name string
     * Supported driver: PostgreSQL, Microsoft Server
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
     * Construct a Postgresql connection
     */
    public static function pg(string $host, int $port, string $dbname, string $user, string $pwd): self 
    { return new DBConn("pgsql", $host, $port, $dbname, $user, $pwd); }

    /**
     * Construct a Microsoft Server connection
     */
    public static function mssql(string $host, int $port, string $dbname, string $user, string $pwd): self
    { return new DBConn("sqlsrv", $host, $port, $dbname, $user, $pwd); }

    /**
     * Check if the connection is inside an active transacton
     * @return bool
     */
    public function inTransaction(): bool { return $this->pdo->inTransaction(); }

    /**
     * Begin an active transaction
     * @return OpResult
     */
    public function beginTransaction(): OpResult { return $this->execContext(OpContext::beginTransaction()); }

    /**
     * Commit the current transaction
     * @return OpResult
     */
    public function commit(): OpResult { return $this->execContext(OpContext::commit()); }

    /**
     * Rollback the current transaction
     * @return OpResult
     */
    public function rollBack(): OpResult { return $this->execContext(OpContext::rollBack()); }

    /**
     * Construct a [OpContext] instance and call function execContext
     * see execContext
     * @return OpContext
     */
    public function exec(string $sql, array $param = [], array $tags = []): OpResult
    { return $this->execContext(OpContext::nonTcl($sql, $param, $tags)); }

    /**
     * Perform database action with given OpContext.
     * @param OpContext $opContext 
     * @param bool $isThrowEx
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
            $isSuccess = FALSE;
            $errMsg = $e->getMessage();
            $trace = $e->getTraceAsString();
        }
        return new OpResult($opContext, $isSuccess, $sqlState, $errMsg, $rowCount, $dataSet, $trace);
    }
}

/**
 * Provides an external integer field $id which is unique
 * Used by @@O 
 */
trait TraitId
{
    /**
     * This value is guaranteed to be unique. Larger value represents later creation time.
     * Classes use this trait SHOULD NEVER set this value
     */
    private int $id = 0;
    public function getId(): int { return $this->id; }

    private static int $nextId = 0;
    
    private static function getNextId(): int { return ++self::$nextId; }

    public static function sortById(self $lhs, self $rhs): bool { return $lhs->id >= $rhs->id; }
}

/**
 * Contains info that is used to construct a PDOStatement
 */
final class OpContext
{
    use TraitId;

    /**
     * The sql string used to construct a PDOStatement
     * If $isTcl is true, $sql will be replaced by specific value
     * See @param isTcl
     */
    private string $sql = "";
    public function getSql(): string { return $this->sql; }

    /**
     * Parameters used to populate generated PDOStatement
     */
    private array $sqlParam = [];
    public function getSqlParam(): array { return $this->sqlParam; }

    /**
     * Whether the statement is a transaction control language (one of 'begin' / 'commit' / 'update')
     * 
     * If $isTcl true, $sql will be replaced by one of 'begin' / 'commit' / 'update',
     * and the class that used this class should call beginTransaction / commit / update function directly,
     * but not constructing a PDOStatement with $sql.
     */
    private bool $isTcl = FALSE;
    public function getIsTcl(): bool { return $this->isTcl; }

    /**
     * Custom tags set by client for filtering
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

    public function setTag(string $key, string $tag): void { $this->tags[$key] = $tag; }
    public function getTag(string $key): string { return $this->tags[$key] ?? ""; }

    private function __construct(string $sql, array $sqlParam, bool $isTcl, array $tags = []) 
    {
        $this->id = self::getNextId();
        $this->sql = $sql;
        $this->sqlParam = $sqlParam;
        $this->isTcl = $isTcl;
        $this->tags = $tags;
    }

    public static function beginTransaction(): self { return new OpContext(__FUNCTION__, [], TRUE); }
    public static function commit(): self { return new OpContext(__FUNCTION__, [], TRUE); }
    public static function rollBack(): self { return new OpContext(__FUNCTION__, [], TRUE); }

    public static function nonTcl(string $sql, array $sqlParam, array $tags = []): self 
    { return new OpContext($sql, $sqlParam, FALSE, $tags); }
}

/**
 * Represents a database operation result
 */
final class OpResult
{
    use TraitId;

    private OpContext $ctxt;
    public function getContext(): OpContext { return $this->ctxt; }

    /**
     * A string with 5 character
     * @see https://www.postgresql.org/docs/current/errcodes-appendix.html
     */
    private string $sqlState = "";
    public function getSqlState(): string { return $this->sqlState; }

    /**
     * The exception error message. Empty if the operation is successful.
     */
    private string $errMsg = "";    
    public function getErrMsg(): string { return $this->errMsg; }

    /**
     * The exception stack trace. Empty if the operation is successful.
     */
    private string $trace = "";
    public function getTrace(): string { return $this->trace; }

    private bool $isSuccess = false;
    public function getIsSuccess(): bool { return $this->isSuccess; }

    /**
     * Number of rows returned by a SELECT statement,
     * or the number of rows affected by a INSERT / UPDATE / DELETE statement
     */
    private int $rowCount = 0;
    public function getRowCount(): int { return $this->rowCount; }

    /**
     * The rows returned by a SELECT statement,
     * or the rows returned by a INSERT / UPDATE / DELETE statement 
     * when the keyword 'RETURNING' is specified. 
     * 
     * Note that when you call count($dataSet), the result is not always equal to $rowCount
     */
    private array $dataSet = [];
    public function getDataSet(): array { return $this->dataSet; }

    public function __construct(OpContext $ctxt, bool $isSuccess,
        string $sqlState, string $errMsg, int $rowCount, 
        array $dataSet, string $trace = ""
    ) {
        $this->id = self::getNextId();
        $this->ctxt = $ctxt;
        $this->isSuccess = $isSuccess;
        $this->sqlState = $sqlState;
        $this->errMsg = $errMsg;
        $this->rowCount = $rowCount;
        $this->dataSet = $dataSet;
        $this->trace = $trace;
    }
}
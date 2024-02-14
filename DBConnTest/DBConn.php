<?php

/**
 * A class which encapsulated PDO and holds database connection info
 */
class DBConn
{
    private array $dbInfo = [];
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
        $options = [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION
        ];
        $this->pdo = new PDO($dsn, $user, $pwd, $options);  # potential PDOException, should be handled by caller
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

    public function exec(string $sql, array $param = [], array $tags = []): OpResult
    { return $this->execContext(OpContext::nonTcl($sql, $param, $tags)); }

    /**
     * Perform database action with given OpContext.
     * @param OpContext $opContext 
     * @param bool $isThrowEx
     * @throws PDOException
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
                $dataSet = $stmt->fetchAll(PDO::FETCH_ASSOC);
                $rowCount = $stmt->rowCount();
            }
            $trace = "";
        } catch (PDOException $e) {
            $isSuccess = FALSE;
            $errMsg = $e->getMessage();
            $trace = $e->getTraceAsString();
        }
        return new OpResult($opContext, $isSuccess, $sqlState, $errMsg, $rowCount, $dataSet, $trace);
    }
}

/**
 * Provides an external integer field $id which is unique
 * This trait is mainly used by class OpContext and OpResult
 */
trait TraitId
{
    /**
     * The values is guaranteed to be unique. Larger value represents later creation time.
     * Classes use this trait SHOULD NEVER set this value
     */
    private int $id = 0;
    public function getId(): int { return $this->id; }

    private static int $nextId = 0;
    
    private static function getNextId(): int { return ++self::$nextId; }

    public static function sortById(self $lhs, self $rhs): bool { return $lhs->id >= $rhs->id; }
}

final class OpContext
{
    use TraitId;

    /**
     * If $this->isTcl is true, the value will be ONE of beginTransaction / commit / rollBack
     * otherwise the value will be a SQL string 
     */
    private string $sql = "";
    public function getSql(): string { return $this->sql; }

    private array $sqlParam = [];
    public function getSqlParam(): array { return $this->sqlParam; }

    /**
     * Is Transaction Control Language (begin / commit / rollBack)
     */
    private bool $isTcl = FALSE;
    public function getIsTcl(): bool { return $this->isTcl; }

    /**
     * Custom tags set by client
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

final class OpResult
{
    use TraitId;

    private OpContext $ctxt;
    public function getContext(): OpContext { return $this->ctxt; }

    private string $sqlState = "";
    public function getSqlState(): string { return $this->sqlState; }

    private string $errMsg = "";    
    public function getErrMsg(): string { return $this->errMsg; }

    private string $trace = "";
    public function getTrace(): string { return $this->trace; }

    private bool $isSuccess = false;
    public function getIsSuccess(): bool { return $this->isSuccess; }

    private int $rowCount = 0;
    public function getRowCount(): int { return $this->rowCount; }

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

?>
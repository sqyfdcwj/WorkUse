<?php

require_once 'DBConn.php';

abstract class ADBTask
{
    /**
     * The data structure to be iterated
     */
    protected array $body = [];
    public function getInput(): array { return $this->body; }

    /**
     * This function MUST be overriden by derived class, 
     * and SHOULD guarantee that the returning DBTaskMidResult contains a list of OpContext 
     * @param DBConn $conn Database connection
     * @return DBTaskMidResult
     */
    abstract function dryRun(DBConn $conn): DBTaskMidResult;   

    /**
     * Perform batch task with given database connection
     * @param DBConn $conn Database connection
     * @param bool $useTransaction Should the task run inside a transaction ?
     * @throws PDOException If DBConn already has an active transaction and $useTransaction is TRUE
     * @return DBTaskResult A list of OpResult, and extra info
     */
    abstract function run(DBConn $conn, bool $useTransaction): DBTaskResult;
}

/**
 * A class which implemented default run function 
 */
abstract class DBTask extends ADBTask
{
    public function run(DBConn $conn, bool $useTransaction = TRUE): DBTaskResult
    {
        $isError = FALSE;
        
        $opContextList = [];
        $opResultList = [];
        
        if ($useTransaction) {
            $opContext = OpContext::beginTransaction();
            $opContext->setTags($conn->getDBInfo());
            $opContextList[] = $opContext;
        }

        $dryRunResult = $this->dryRun($conn);
        $opContextList = array_merge($opContextList, $dryRunResult->getOpContextList());
        
        foreach ($opContextList as $opContext) {
            if ($isError || !($opContext instanceof OpContext)) { 
                continue; 
            }
            $opContext->setTags($conn->getDBInfo());
            $opResult = $conn->execContext($opContext);
            $opResultList[] = $opResult;
            $this->onTaskGetOpResult($opResult);
            if (!$opResult->getIsSuccess()) {
                $isError = TRUE;
            }
        }

        if ($useTransaction) {
            if (!$isError) {
                $opContext = OpContext::commit();
            } else {
                $opContext = OpContext::rollBack();
            }
            $opContext->setTags($conn->getDBInfo());
            $opContextList[] = $opContext;
            $opResult = $conn->execContext($opContext);
            $opResultList[] = $opResult;
            $this->onTaskGetOpResult($opResult);
        }
        return new DBTaskResult($opResultList);
    }

    /**
     * No-op in this class.
     * 
     * This function is called inside ADBTask::run, 
     * and is called immediately after calling DBConn::execContext(OpContext),
     * which returns a OpResult instance.
     * 
     * Do something that requires immediate handle of OpResult (E.g. write result into to error log)
     * @param OpResult $opResult
     */
    protected function onTaskGetOpResult(OpResult $opResult): void { }
}

/**
 * Contains a list of OpContext and is used by ADBTask
 */
class DBTaskMidResult
{
    /**
     * List of OpContext. All elements are ordered by the field $id in ascending order
     */
    private array $opContextList = [];
    public function getOpContextList(): array { return $this->opContextList; }

    public function __construct(array $list)
    {
        foreach ($list as $opContext) {
            if ($opContext instanceof OpContext) {
                $this->opContextList[] = $opContext;
            }
        }
        usort($this->opContextList, [ "OpContext", "sortById" ]);
    }
}

class DBTaskResult
{
    private ?OpResult $lastError = NULL;
    public function getLastError(): ?OpResult { return $this->lastError; }

    private array $opResultList = [];
    public function getOpResultList(): array { return $this->opResultList; }

    public function __construct(array $arrOpResult)
    {
        foreach ($arrOpResult as $opResult) {
            if ($opResult instanceof OpResult) {
                $this->opResultList[] = $opResult;
            }
        }
        usort($this->opResultList, [ "OpResult", "sortById" ]);
        foreach ($this->opResultList as $opResult) {
            if (!$opResult->getIsSuccess()) {
                $this->lastError = $opResult;
            }
        }
    }
}

<?php

namespace DBTask;

use DBConn\DBConn;
use DBConn\DBStmt;
use DBConn\DBResult;

abstract class DBTask
{
    /**
     * @var array $body The data structure to be iterated
     */
    protected array $body = [];
    public function getBody(): array { return $this->body; }

    public function __construct(array $body)
    {
        $this->body = $body;
    }

    /**
     * Iterate DBTask::$body and perform database action for each element in collection
     * @param DBConn $conn Database connection
     * @param bool $useTransaction Whether to open a transaction
     * @return DBTaskResult A list of DBResult, and extra info
     */
    public function run(DBConn $conn, bool $useTransaction = true): DBTaskResult
    {
        $isError = false;
        $opResultList = [];

        if ($useTransaction) {
            $opResultList[] = $this->beginTransaction($conn);
            if (!$this->isAllSuccess($opResultList)) {
                /* Return immediately if beginTransaction failed
                 * So we can assert endTransaction never fails
                 */ 
                return new DBTaskResult($opResultList);
            }
        }

        $opResultList = array_merge($opResultList, $this->execBody($conn));
        $isError = !$this->isAllSuccess($opResultList);

        if ($useTransaction) {
            // Assert endTransaction never fails
            $opResultList[] = $this->endTransaction($conn, $isError);
        }

        return new DBTaskResult($opResultList);
    }

    /**
     * @param DBConn $conn DB connection
     * @return DBResult Result of beginTransaction
     */
    protected function beginTransaction(DBConn $conn): DBResult
    {
        $opResult = $conn->execContext(DBStmt::begin($conn->getDBInfo()));
        $this->onOpResult($opResult);
        return $opResult;
    }

    /**
     * @param DBConn $conn DB connection
     * @param bool $isError If true then rollback else commit
     * @return DBResult Result of rollback or commit
     */
    protected function endTransaction(DBConn $conn, bool $isError): DBResult
    {
        $opResult = $isError
            ? $conn->execContext(DBStmt::rollback($conn->getDBInfo()))
            : $conn->execContext(DBStmt::commit($conn->getDBInfo()));
        $this->onOpResult($opResult);
        return $opResult;
    }

    /** 
     * Iterate DBTask::$body and perform database action for each elment in collection.
     * @param DBConn $conn DB connection
     * @return array List of DBResult
     */
    abstract protected function execBody(DBConn $conn): array;

    /**
     * Whether given DBResult array has no element where failed
     * @param array $opResultList List of DBResult
     * @return bool 
     */
    protected function isAllSuccess(array $opResultList): bool
    {
        foreach ($opResultList as $opResult) {
            if (($opResult instanceof DBResult) && !$opResult->getIsSuccess()) {
                return false;
            }
        }
        return true;
    }

    /**
     * Customized action when receiving an DBResult
     * @param DBResult $opResult 
     * @return void
     */
    protected function onOpResult(DBResult $opResult): void { }
}
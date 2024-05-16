<?php

namespace WebApiRequest;

use DBConn\DBResult;
use DBTask\DBTaskResult;
use SQLUtil\DataSetUtil;

final class WebApiResponse
{
    private ?DBTaskResult $taskResult = null;
    public function getDBTaskResult(): ?DBTaskResult { return $this->taskResult; }

    private ?DBResult $lastError = null;
    public function getLastError(): ?DBResult { return $this->lastError; }

    private ?\Exception $ex = null;
    public function getException(): ?\Exception { return $this->ex; }

    private bool $isSuccess;
    public function getIsSuccess(): bool { return $this->isSuccess; }

    private string $responseBody = "";
    public function getResponseBody(): string { return $this->responseBody; }

    private int $state = 0;
    public function getState(): int { return $this->state; }

    /**
     * WebApiRequest::run finished without any error
     */
    public const STATE_SUCC = 0;

    /**
     * WebApiRequest::run finished with error
     */
    public const STATE_DBTASK_FAIL = 1;

    /**
     * WebApiRequest::run is not exectued due to other error
     */
    public const STATE_OTHER_FAIL = 2;

    /**
     * @param ?DBTaskResult $taskResult
     * @param ?\Exception $ex 
     */
    private function __construct(?DBTaskResult $taskResult, ?\Exception $ex)
    {
        if ($taskResult !== null) {
            $this->taskResult = $taskResult;
            $this->isSuccess = $taskResult->getIsSuccess();
            if ($this->isSuccess) {
                $this->state = self::STATE_SUCC;
            } else {
                $this->lastError = $taskResult->getLastError();
                $this->ex = $this->lastError->getException();
                $this->state = self::STATE_DBTASK_FAIL;
            }
        } else {
            $this->taskResult = null;
            $this->lastError = null;
            $this->ex = $ex;
            $this->isSuccess = false;
            $this->state = self::STATE_OTHER_FAIL;
        }

        $json = [];
        if ($this->isSuccess) {
            $json["code"] = 0;
        } else {
            $code = $this->ex->getCode();
            if (is_numeric($code)) {
                if ($code == 0) { 
                    $code = 1; 
                } else {
                    $code = intval($code);
                }
            } else {
                $code = 1;
            }
            $json["code"] = $code;
        }

        $json["message"] = $this->isSuccess ? "" : $this->ex->getMessage();
        $json["body"] = [];
        $opResultList = $this->isSuccess ? $this->taskResult->getOpResultList() : [];
        
        foreach ($opResultList as $opResult) {
            $opContext = $opResult->getStmt();
            if ($opContext->getIsTcl()) { continue; }

            $dataSet = $opResult->getDataSet();
            $sqlDisplayName = $opContext->getTag("sql_display_name");
            $keyField = $opContext->getTag("key_field");

            foreach ($dataSet as &$row) {
                DataSetUtil::castBoolToInt($row);
                DataSetUtil::castToStr($row);
            }

            if (empty($keyField)) {
                $json["body"][$sqlDisplayName] = $dataSet;
            } else {
                $json["body"][$sqlDisplayName] = DataSetUtil::pivot($dataSet, $keyField);
                $json["body"][$sqlDisplayName."_keys"] = array_keys($json["body"][$sqlDisplayName]);
            }
        }

        $this->responseBody = json_encode($json, JSON_UNESCAPED_UNICODE);
    }

    public static function fromTaskResult(DBTaskResult $taskResult): self
    {
        return new self($taskResult, null);
    }

    public static function fromEx(\Exception $ex): self 
    {
        return new self(null, $ex);
    }
}
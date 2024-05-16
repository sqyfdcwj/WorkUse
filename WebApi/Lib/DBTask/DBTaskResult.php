<?php

namespace DBTask;

use DBConn\DBResult;

/**
 * Generated by DBTask::run
 */
final class DBTaskResult
{
    private ?DBResult $lastError = null;
    public function getLastError(): ?DBResult { return $this->lastError; }

    private ?DBResult $lastTclError = null;
    public function getLastTclError(): ?DBResult { return $this->lastTclError; }

    private ?DBResult $lastNonTclError = null;
    public function getLastNonTclError(): ?DBResult { return $this->lastNonTclError; }

    public function getIsSuccess(): bool { return $this->lastError === null; }

    private array $opResultList = [];

    /**
     * This function guarantees that the returning array contains **ONLY** DBResult
     * @return array List of DBResult
     */
    public function getOpResultList(): array { return $this->opResultList; }

    public function __construct(array $opResultList)
    {
        /* Guarantees that $this->opResultList contains only DBResult */
        $this->opResultList = array_filter(
            $opResultList, 
            function ($v) { return $v instanceof DBResult; }
        );
        foreach ($this->opResultList as $dbResult) {
            if (!$dbResult->getIsSuccess()) {
                $this->lastError = $dbResult;
                if ($dbResult->getIsTcl()) {
                    $this->lastTclError = $dbResult;
                } else {
                    $this->lastNonTclError = $dbResult;
                }
            }
        }
    }
}

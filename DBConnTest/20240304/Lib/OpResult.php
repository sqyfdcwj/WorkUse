<?php

require_once 'OpContext.php';

final class OpResult
{
    private OpContext $ctxt;
    public function getContext(): OpContext { return $this->ctxt; }

    /**
     * @var string $sqlState 5-Digit String
     */
    private string $sqlState = "";
    public function getSqlState(): string { return $this->sqlState; }

    /**
     * @var string $errMsg Error message. Empty when there is no error.
     */
    private string $errMsg = "";    
    public function getErrMsg(): string { return $this->errMsg; }

    /**
     * @var string $trace Retrieved by PDOException::getTraceAsString(). Empty when there is no error.
     */
    private string $trace = "";
    public function getTrace(): string { return $this->trace; }

    private bool $isSuccess = FALSE;
    public function getIsSuccess(): bool { return $this->isSuccess; }

    /**
     * The number of rows affected by a INSERT / UPDATE / DELETE statement,
     * or the number of rows returned by a SELECT statement
     */
    private int $affectedRow = 0;
    public function getAffectedRow(): int { return $this->affectedRow; }

    public function getRowCount(): int { return count($this->dataSet); }

    private array $dataSet = [];
    public function getDataSet(): array { return $this->dataSet; }

    public function __construct(OpContext $ctxt, bool $isSuccess,
        string $sqlState, string $errMsg, int $affectedRow, 
        array $dataSet, string $trace = ""
    ) {
        $this->ctxt = $ctxt;
        $this->isSuccess = $isSuccess;
        $this->sqlState = $sqlState;
        $this->errMsg = $errMsg;
        $this->affectedRow = $affectedRow;
        $this->dataSet = $dataSet;
        $this->trace = $trace;
    }
}
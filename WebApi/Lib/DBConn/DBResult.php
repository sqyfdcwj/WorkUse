<?php

namespace DBConn;

use DBConn\DBStmt;

final class DBResult
{
    private DBStmt $stmt;
    public function getStmt(): DBStmt { return $this->stmt; }

    /**
     * @var string $sqlState 5-Digit String retrievied from
     * PDO::errorInfo or PDOStatement::errorInfo or PDOException::errorInfo
     */
    private string $sqlState = "";
    public function getSqlState(): string { return $this->sqlState; }

    /**
     * @var ?\PDOException $ex The PDOException instance, null if the database operation is successful.
     */
    private ?\PDOException $ex = null;
    public function getException(): ?\PDOException { return $this->ex; }

    public function getIsSuccess(): bool { return $this->ex === null; }

    /**
     * @return string Exception message if not null, otherwise empty string
     */
    public function getErrMsg(): string 
    { 
        return $this->ex === null ? "" : $this->ex->getMessage(); 
    }

    /**
     * @return string Exception trace if not null, otherwise empty string
     */
    public function getTrace(): string 
    { 
        return $this->ex === null ? "" : $this->ex->getTraceAsString(); 
    }

    /**
     * @var int $rowCount Number of rows affected by INSERT / UPDATE / DELETE statement,
     * or the number of rows returned by SELECT statement
     */
    private int $rowCount = 0;
    public function getRowCount(): int { return $this->rowCount; }

    /**
     * @var array $dataSet Rows returned by SELECT statement,
     * or INSERT / UPDATE / DELETE statement with keyword 'RETURNING'
     */
    private array $dataSet = [];
    public function getDataSet(): array { return $this->dataSet; }

    public function __construct(
        DBStmt $stmt,
        ?\Exception $ex,
        string $sqlState, 
        int $rowCount, 
        array $dataSet
    ) {
        $this->stmt = $stmt;
        $this->ex = $ex;
        $this->sqlState = $sqlState;
        $this->rowCount = $rowCount;
        $this->dataSet = $dataSet;
    }
}
<?php

namespace DBTask;

use DBConn\DBConn;

abstract class DBTask
{
    /**
     * @var array $body The data structure to be iterated
     */
    protected array $body = [];
    public function getBody(): array { return $this->body; }

    /**
     * Perform batch task with given database connection
     * @param DBConn $conn Database connection
     * @param bool $useTransaction Should the task run inside a transaction ?
     * @throws \PDOException If DBConn already has an active transaction and $useTransaction is TRUE
     * @return DBTaskResult A list of OpResult, and extra info
     */
    abstract function run(DBConn $conn, bool $useTransaction): DBTaskResult;
}
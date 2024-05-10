<?php

namespace DBConn;

use SQLUtil\SQLUtil;

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

    private function __construct(string $sql, array $rawParam, bool $isTcl, array $tags = []) 
    {
        $this->sql = $sql;
        $this->rawParam = $rawParam;
        $this->sqlParam = SQLUtil::getParamList($sql, $rawParam);
        $this->isTcl = $isTcl;
        $this->tags = $tags;
    }

    public static function beginTransaction(): self { return new self(__FUNCTION__, [], TRUE); }
    public static function commit(): self { return new self(__FUNCTION__, [], TRUE); }
    public static function rollBack(): self { return new self(__FUNCTION__, [], TRUE); }

    public static function nonTcl(string $sql, array $rawParam, array $tags = []): self 
    { return new self($sql, $rawParam, FALSE, $tags); }
}
<?php

final class OpContext
{
    /**
     * If $this->isTcl is true, the value is one of the following values:
     * beginTransaction
     * commit
     * rollBack
     * 
     * otherwise, the value will be the SQL string  
     */
    private string $sql = "";
    public function getSql(): string { return $this->sql; }


    private array $rawParam = [];
    public function getRawParam(): array { return $this->rawParam; }

    private array $sqlParam = [];
    public function getSqlParam(): array { return $this->sqlParam; }

    /**
     * Is Transaction Control Language (begin / commit / rollBack)
     */
    private bool $isTcl = FALSE;
    public function getIsTcl(): bool { return $this->isTcl; }

    /**
     * Custom tags used for storing external info or fields
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

    public static function beginTransaction(): self { return new OpContext(__FUNCTION__, [], TRUE); }
    public static function commit(): self { return new OpContext(__FUNCTION__, [], TRUE); }
    public static function rollBack(): self { return new OpContext(__FUNCTION__, [], TRUE); }

    public static function nonTcl(string $sql, array $rawParam, array $tags = []): self 
    { return new OpContext($sql, $rawParam, FALSE, $tags); }
}

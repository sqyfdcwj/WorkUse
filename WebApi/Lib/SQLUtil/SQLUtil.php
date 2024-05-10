<?php 

namespace SQLUtil;

final class SQLUtil
{
    /**
     * Remove colon word occurances (e.g. :word) 
     * which is enclosed by comment block, single quote,
     * or after the single comment --
     */
    public static function handleSql(string $sql): string
    {
        $fn = function($_) { return ""; };
        $openCmt = "\/\*";  // /*
        $closeCmt = "\*\/"; // */
        $slcmt = "--";      // Single line comment --
        $sq = "\'";         // Single quote
        $sqlReplaced = preg_replace_callback("/$openCmt\s+.*\s+$closeCmt/", $fn, $sql);
        $sqlReplaced = preg_replace_callback("/$slcmt.*/", $fn, $sqlReplaced);
        $sqlReplaced = preg_replace_callback("/$sq$sq/", $fn, $sqlReplaced);
        $sqlReplaced = preg_replace_callback("/$sq.+$sq/", $fn, $sqlReplaced);
        $sqlReplaced = preg_replace_callback("/$sq\s+.+\s+$sq/", $fn, $sqlReplaced);
        return $sqlReplaced;
    }

    /**
     * Internally calls SQLUtil::handleSql
     */
    public static function getParamNameList(string $sql): array
    {
        $matches = [];
        $fnRemoveColon = function ($name) { return substr($name, 1); };
        $result = preg_match_all("/:\\w+/", self::handleSql($sql), $matches) 
            ? array_map($fnRemoveColon, reset($matches)) 
            : [];
        return array_unique($result);
    }
    
    public static function getParamList(string $sql, array ...$paramList): array
    {
        $result = [];
        $sqlParamNameList = self::getParamNameList($sql);
        foreach ($sqlParamNameList as $name) {
            $result[$name] = self::getValue($name, ...$paramList);
        }
        return $result;
    }

    public static function isValid($v): bool
    {
        return is_null($v) || is_string($v) || is_numeric($v) || is_bool($v);
    }

    public static function getValue(string $name, array ...$paramList)
    {
        foreach ($paramList as $param) {
            if (isset($param[$name]) && self::isValid($param[$name])) {
                return $param[$name];
            }
        }
        return NULL;
    }
}
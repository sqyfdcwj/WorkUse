<?php 

namespace Eric;

final class SQLUtil
{
    /**
     * Remove all comment in the sql string
     */
    public static function reserveParam(string $sql): string
    {
        $fn = function($_) { return ""; };
        $openCmt = "\/\*";  // /*
        $closeCmt = "\*\/"; // */
        $slcmt = "--";      // Single line comment --
        $sq = "\'";         // Single quote
        $sqlReplaced = \preg_replace_callback("/$openCmt\s+.*\s+$closeCmt/", $fn, $sql);
        $sqlReplaced = \preg_replace_callback("/$slcmt.*/", $fn, $sqlReplaced);
        $sqlReplaced = \preg_replace_callback("/$sq$sq/", $fn, $sqlReplaced);
        $sqlReplaced = \preg_replace_callback("/$sq.+$sq/", $fn, $sqlReplaced);
        $sqlReplaced = \preg_replace_callback("/$sq\s+.+\s+$sq/", $fn, $sqlReplaced);
        return $sqlReplaced;
    }

    /**
     * Internally calls SQLUtil::reserveParam
     */
    public static function getParamNameList(string $sql): array
    {
        $matches = [];
        $fnRemoveColon = function ($name) { return \substr($name, 1); };
        $result = \preg_match_all("/:\\w+/", self::reserveParam($sql), $matches) 
            ? \array_map($fnRemoveColon, \reset($matches)) 
            : [];
        return \array_unique($result);
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

    public static function isValid($v): bool { return \is_null($v) || \is_bool($v) || self::isStrOrNum($v); }

    public static function isStrOrNum($v): bool { return \is_int($v) || \is_float($v) || \is_string($v); }

    public static function getValue(string $name, array ...$paramList)
    {
        $fnIsValid = function ($v) { return self::isStrOrNum($v) || \is_bool($v); };
        foreach ($paramList as $param) {
            if (isset($param[$name]) && $fnIsValid($param[$name])) {
                return $param[$name];
            }
        }
        return NULL;
    }
}
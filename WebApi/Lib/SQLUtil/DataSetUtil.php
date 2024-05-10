<?php 

namespace SQLUtil;

final class DataSetUtil
{
    public static function pivot(array $dataSet, string $keyFieldName): array
    {
        $result = [];
        foreach ($dataSet as $row) {
            $keyFieldValue = $row[$keyFieldName] ?? "";
            $result[$keyFieldValue][] = $row;
        }
        return $result;
    }

    public static function castToStr(array &$row): void
    {
        foreach ($row as $name => $value) {
            $row[$name] = strval($value);
        }
    }

    public static function castBoolToInt(array &$row): void
    {
        foreach ($row as $name => $value) {
            if (is_bool($value)) {
                $row[$name] = intval($value);
            }
        }
    }
}
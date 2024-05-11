<?php

namespace WebApiRequest;

final class ErrorFileLogger
{
    public function log(WebApiResponse $response, array $env): bool
    {
        $state = $response->getState();
        if ($state === WebApiResponse::STATE_SUCC) {
            return TRUE;
        }

        $env = array_filter($env, function ($v, $k) {
            return is_string($k) && (is_string($v) || is_numeric($v));
        }, ARRAY_FILTER_USE_BOTH);

        $other = [];
        if ($state === WebApiResponse::STATE_DBTASK_FAIL) {
            $error = $response->getLastError();
            $context = $error->getContext();
            $other = [
                "Database" => $context->getTag("dsn_short"),
                "Error" => $error->getErrMsg(),
                "sql_group_name" => $context->getTag("sql_group_name"),
                "sql_group_dtl_id" => $context->getTag("sql_group_dtl_id"),
                "sql_name" => $context->getTag("sql_name"),
                "sql" => $context->getTag("sql"),
                "Error row" => json_encode($context->getRawParam()),
                "Required param" => json_encode($context->getSqlParam()),
            ];
        } else {
            $other = [
                "Error" => $response->getException()->getMessage()
            ];
        }

        $lines = [];
        foreach (array_merge($env, $other) as $k => $v) {
            $lines[] = "$k:\n$v";
        }

        $dir = "ErrorReport/".date("Ymd");
        if (!is_dir($dir)) {
            mkdir($dir, 0755, TRUE);
        }

        $fileName = date("Ymd_His", $_SERVER["REQUEST_TIME"]).".txt";

        $result = file_put_contents(
            $dir.DIRECTORY_SEPARATOR.$fileName, 
            implode("\n\n", $lines), 
            FILE_APPEND | LOCK_EX
        );   

        if (!$result) {
            error_log(__METHOD__.": file_put_contents returned false or 0");
        }
        return $result;
    }
}
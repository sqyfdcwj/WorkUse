<?php

namespace WebApiRequest;

use DBConn\DBConn;
use DBConn\OpResult;
use WebApiRequest\WebApiResponse;

final class DBLogger
{
    private DBConn $conn;

    public function __construct(DBConn $conn)
    {
        $this->conn = $conn;
    }

    public function log(WebApiResponse $response, array $env): OpResult
    {
        /*
            sql_group_dtl_id,       NULL if succ, else OpResult::getTags
            sql_group_name,         NULL if succ, else OpResult::getTags
            sql_group_version,      NULL if succ, else OpResult::getTags
            sql_name,               NULL if succ, else OpResult::getTags
            sql,                    NULL if succ, else OpResult::getTags
            err_msg,                NULL if succ, else OpResult::getTags
            request_user_id,        env
            request_username,       env
            request_body,           env
            response_body,          $response->getResponseBody()
            request_app_version,    env
            sender_endpoint,        env
            receiver_endpoint       env
         */
        $sql = "
INSERT INTO apps.sys_api_sql_log (
    sql_group_dtl_id, sql_group_name,
    sql_group_version, sql_name, sql, err_msg,
    request_user_id, request_username,
    request_body, response_body, request_app_version,
    sender_endpoint, receiver_endpoint
)
SELECT :sql_group_dtl_id, :sql_group_name,
    :sql_group_version, :sql_name, :sql, :err_msg,
    :request_user_id, :request_username,
    :request_body, :response_body, :request_app_version,
    :sender_endpoint, :receiver_endpoint;
        ";
        $state = $response->getState();
        $responseBodyParam = [ "response_body" => $response->getResponseBody() ];
        if ($state === WebApiResponse::STATE_SUCC) {
            $opResult = $this->conn->exec($sql, array_merge($env, $responseBodyParam));
        } else if ($state === WebApiResponse::STATE_DBTASK_FAIL) {
            $lastError = $response->getLastError();
            $opResult = $this->conn->exec($sql, array_merge(
                $env, 
                $responseBodyParam,
                $lastError->getContext()->getTags(),
                [ "err_msg" => $lastError->getErrMsg() ]
            ));
        } else {
            $opResult = $this->conn->exec($sql, array_merge(
                $env, 
                $responseBodyParam,
                [ "err_msg" => $response->getException()->getMessage() ]
            ));
        }
        if (!$opResult->getIsSuccess()) {
            error_log(__METHOD__.": Failed to log");
            error_log($opResult->getErrMsg());
        }
        return $opResult;
    }
}
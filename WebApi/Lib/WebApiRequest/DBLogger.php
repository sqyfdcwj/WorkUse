<?php

namespace WebApiRequest;

use DBConn\DBConn;
use DBConn\DBResult;
use WebApiRequest\WebApiResponse;

final class DBLogger
{
    private DBConn $conn;

    public function __construct(DBConn $conn)
    {
        $this->conn = $conn;
    }

    public function log(WebApiResponse $response, array $env): DBResult
    {
        /*
            sql_group_dtl_id,       null if succ, else DBResult::getTags
            sql_group_name,         null if succ, else DBResult::getTags
            sql_group_version,      null if succ, else DBResult::getTags
            sql_name,               null if succ, else DBResult::getTags
            sql,                    null if succ, else DBResult::getTags
            err_msg,                null if succ, else DBResult::getTags
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
            $dbResult = $this->conn->exec($sql, array_merge($env, $responseBodyParam));
        } else if ($state === WebApiResponse::STATE_DBTASK_FAIL) {
            $lastError = $response->getLastError();
            $dbResult = $this->conn->exec($sql, array_merge(
                $env, 
                $responseBodyParam,
                $lastError->getStmt()->getTags(),
                [ "err_msg" => $lastError->getErrMsg() ]
            ));
        } else {
            $dbResult = $this->conn->exec($sql, array_merge(
                $env, 
                $responseBodyParam,
                [ "err_msg" => $response->getException()->getMessage() ]
            ));
        }
        if (!$dbResult->getIsSuccess()) {
            error_log($this->conn->getDSNShort()." | ".__METHOD__." failed");
            error_log($dbResult->getErrMsg());
        }
        return $dbResult;
    }
}
<?php

namespace WebApiRequest;

final class ErrorLogger
{
    public function log(string $message): bool
    {
        return error_log($message);
    }
}
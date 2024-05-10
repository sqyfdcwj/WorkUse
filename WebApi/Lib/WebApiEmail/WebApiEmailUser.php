<?php

namespace WebApiEmail;

final class WebApiEmailUser
{
    public string $host = "";
    public int $port = 0;
    public string $username = "";
    public string $password = "";
    public string $from = "";
    public string $fromName = "";

    public function __construct(
        string $host, 
        int $port, 
        string $username, 
        string $password,
        string $from, 
        string $fromName
    )
    {
        $this->host = $host;
        $this->port = $port;
        $this->username = $username;
        $this->password = $password;
        $this->from = $from;
        $this->fromName = $fromName;
    }
}
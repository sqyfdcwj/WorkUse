<?php

require_once 'Lib/DBConn.php';
require_once 'Lib/WebApiEmail.php';

$emailSender = new WebApiEmailSender(
    new WebApiEmailUser(
        "smtp.gmail.com",
        587,
        "cmlau1998@gmail.com",
        "vpmduvglejznhwbi",
        "cmlau1998@gmail.com",
        "PHPMailer"
    ),
    [ "File" => __FILE__ ],
    [ "cmlau1998@gmail.com" => "Eric" ]
);

try {
    $conn = DBConn::pg("localhost", 5432, "postgres", "postgres", "1234");
    $opResult = $conn->exec("SELECT * FROM account;");
} catch (PDOException $e) {
    $emailSender->send(WebApiEmail::fromException("PDOException", $e));
}

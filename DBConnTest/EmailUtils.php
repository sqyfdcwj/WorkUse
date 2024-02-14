<?php

include 'PHPMailer/Exception.php';
include 'PHPMailer/PHPMailer.php';
include 'PHPMailer/SMTP.php';
use PHPMailer\PHPMailer\PHPMailer;

$emailTable = [];

function setEmailTable(string $key, ?string $value): void
{
    if ($value === null) {
        unset($GLOBALS["emailTable"][$key]);
    } else {
        $GLOBALS["emailTable"][$key] = $value;
    }
}

function SendMail(string $subject): void
{
    global $emailTable;

    $mail = new PHPMailer();
    $mail->IsSMTP();
    $mail->IsHTML(true);

    $mail->From = 'phpadmin@xtrapower.net';
    $mail->FromName = 'PHPAdmin';
    
    $mail->Host = 'm.xtrapower.net';
    $mail->Port = 25;
    $mail->Username = 'phpadmin@xtrapower.net';
    $mail->Password = 'n5k82j3q';
    $mail->SMTPAuth = true;
    $mail->SMTPAutoTLS = false;
    $mail->SMTPSecure = false;
    
    $mail->Subject = $subject;
    $mail->Body = GetTable($emailTable);
    $mail->CharSet = "UTF-8";
    
    $mail->addAddress('eric@xtrapower.net', 'eric');
    // $mail->addAddress('jacky@xtrapower.net', 'jacky');
    
    $mail->Send();
}

function GetTable(array $arr)
{
    $table = '<table border="1">';
    foreach ($arr as $k => $v) {
        $table .= GetRow(GetHeader($k).GetCell($v));
    }
    $table .= '</table>';
    return $table;
}

function GetCell($content) 
{ 
    return "<td>$content</td>";
}

function GetHeader($content)
{
    return "<th>$content</th>";
}

function GetRow($content)
{
    return "<tr>$content</tr>";
}

?>
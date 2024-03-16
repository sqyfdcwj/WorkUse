<?php

include 'PHPMailer/Exception.php';
include 'PHPMailer/PHPMailer.php';
include 'PHPMailer/SMTP.php';
use PHPMailer\PHPMailer\PHPMailer;

$emailTable = [];

class WebApiEmail {

    private PHPMailer $phpMailer;

    public function __construct()
    {
        $this->phpMailer = new PHPMailer();
        $this->phpMailer->IsSMTP();
        $this->phpMailer->IsHTML(true);
    
        $this->phpMailer->From = 'phpadmin@xtrapower.net';
        $this->phpMailer->FromName = 'PHPAdmin';
        
        $this->phpMailer->Host = 'm.xtrapower.net';
        $this->phpMailer->Port = 25;
        $this->phpMailer->Username = 'phpadmin@xtrapower.net';
        $this->phpMailer->Password = 'n5k82j3q';
        $this->phpMailer->SMTPAuth = true;
        $this->phpMailer->SMTPAutoTLS = false;
        $this->phpMailer->SMTPSecure = false;

        $this->phpMailer->CharSet = "UTF-8";
        $this->phpMailer->addAddress('eric@xtrapower.net', 'eric');
    }

    public function send(
        string $fileName, 
        string $connStr, 
        string $error
    ): void 
    {
        $emailTable = [];
        $emailTable["Filename"] = $fileName;
        $emailTable["DB Info"] = $connStr;
        $emailTable["Pgsql error detail"] = $error;

        $this->phpMailer->Subject = "WebAPI insert error";
        $this->phpMailer->Body = $this->getTable($emailTable);
        $this->phpMailer->Send();
    }

    private function getTable(array $arr): string
    {
        $table = '<table border="1">';
        foreach ($arr as $k => $v) {
            $table .= $this->getRow($this->getHeader($k).$this->getCell($v));
        }
        $table .= '</table>';
        return $table;
    }

    private function getCell($content): string
    { 
        return "<td>$content</td>";
    }

    private function getHeader($content): string
    {
        return "<th>$content</th>";
    }

    private function getRow($content): string
    {
        return "<tr>$content</tr>";
    }
}
<?php

include 'PHPMailer/Exception.php';
include 'PHPMailer/PHPMailer.php';
include 'PHPMailer/SMTP.php';
use PHPMailer\PHPMailer\PHPMailer;

final class WebApiEmail {

    private PHPMailer $phpMailer;
    private array $basicInfo = [];

    public function __construct(string $fileName)
    {
        $this->basicInfo = [ "File name" => $fileName ];

        $this->phpMailer = new PHPMailer();
        $this->phpMailer->IsSMTP();
        $this->phpMailer->IsHTML(TRUE);
    
        $this->phpMailer->From = 'phpadmin@xtrapower.net';
        $this->phpMailer->FromName = 'PHPAdmin';
        
        $this->phpMailer->Host = 'm.xtrapower.net';
        $this->phpMailer->Port = 25;
        $this->phpMailer->Username = 'phpadmin@xtrapower.net';
        $this->phpMailer->Password = 'n5k82j3q';
        $this->phpMailer->SMTPAuth = TRUE;
        $this->phpMailer->SMTPAutoTLS = FALSE;
        $this->phpMailer->SMTPSecure = FALSE;

        $this->phpMailer->CharSet = "UTF-8";
        $this->phpMailer->addAddress('eric@xtrapower.net', 'eric');
    }

    public function sendRaw(string $subject, string $body): void
    {
        $this->phpMailer->Subject = $subject;
        $this->phpMailer->Body = $body;
        $this->phpMailer->Send();
    }

    public function sendDBOperationFailure(string $connStr, string $error): void 
    {
        $this->sendRaw("DB insertion error", $this->getTable(
            $this->basicInfo, 
            [ "Database" => $connStr, "Pgsql error detail" => $error ]
        ));
    }

    public function sendDBConnectionFailure(string $error): void 
    {
        $this->sendRaw("DB insertion error", $this->getTable(
            $this->basicInfo, 
            [ "Error detail" => $error ]
        ));
    }

    public function sendFree(string $subject, array $fieldList): void
    {
        $emailTable = [];
        foreach ($fieldList as $k => $v) {
            if (is_string($k) && is_string($v)) {
                $emailTable[$k] = $v;
            }
        }
        $this->sendRaw($subject, $this->getTable($this->basicInfo, $emailTable));
    }

    private function getTable(array ...$arr): string
    {
        $merged = array_merge(...$arr);
        $table = '<table border="1">';
        foreach ($merged as $k => $v) {
            $table .= $this->getRow($this->getHeader($k).$this->getCell($v));
        }
        $table .= '</table>';
        return $table;
    }

    private function getCell(string $content): string { return "<td>$content</td>"; }

    private function getHeader(string $content): string { return "<th>$content</th>"; }

    private function getRow(string $content): string { return "<tr>$content</tr>"; }
}
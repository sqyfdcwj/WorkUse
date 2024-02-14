<?php

require_once 'DBConn.php';
require_once 'PHPMailer/Exception.php';
require_once 'PHPMailer/PHPMailer.php';
require_once 'PHPMailer/SMTP.php';

use PHPMailer\PHPMailer\PHPMailer;

/**
 * This class is used by WebApiRequest.php to send error report files
 * 
 */
class XtraEmailSender
{
    private PHPMailer $mail;

    public function __construct()
    {
        $this->mail = new PHPMailer(TRUE);  // Throw exception
        $this->mail->IsSMTP();
        $this->mail->IsHTML(TRUE);
        $this->mail->SMTPAuth = TRUE;
        $this->mail->SMTPAutoTLS = FALSE;
        $this->mail->SMTPSecure = FALSE;

        $this->mail->Host = "m.xtrapower.net";
        $this->mail->Port = 25;
        $this->mail->Username = "phpadmin@xtrapower.net";
        $this->mail->Password = "n5k82j3q";

        $this->mail->addAddress("eric@xtrapower.net", "eric");
    }

    public function addAddress(array $addressList): void
    {
        foreach ($addressList as $addr => $user) {
            if (is_string($addr) && is_string($user)) {
                $this->mail->addAddress($addr, $user);
            }
        }
    }

    /**
     * Send a email to given 
     * @return bool
     */
    public function send(
        string $subject,
        string $body,
        string $charSet
    ): bool
    {
        
        return FALSE;
    }
}

?>
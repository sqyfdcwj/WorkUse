<?php

/**
 * @author Eric
 */

require_once 'PHPMailer/Exception.php';
require_once 'PHPMailer/PHPMailer.php';
require_once 'PHPMailer/SMTP.php';

use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception as PHPMailerException;

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

final class WebApiEmailSender 
{

    private PHPMailer $mail;

    private array $baseInfoList = [];

    private array $savedAddrList = [];

    private array $savedEmailList = [];

    public function __construct(
        WebApiEmailUser $user, 
        array $baseInfoList, 
        array $addrList
    )
    {
        $this->mail = new PHPMailer(TRUE);  // Set true to throw caught PHPMailerException
        $this->mail->IsSMTP();
        $this->mail->IsHTML(TRUE);
        $this->mail->CharSet = "UTF-8";
        $this->mail->SMTPAuth = TRUE;
        $this->mail->SMTPAutoTLS = FALSE;
        $this->mail->SMTPSecure = PHPMailer::ENCRYPTION_STARTTLS;   // Default value = ''

        $this->mail->Host = $user->host;
        $this->mail->Port = $user->port;
        $this->mail->Username = $user->username;
        $this->mail->Password = $user->password;
        $this->mail->From = $user->from;
        $this->mail->FromName = $user->fromName;
        
        $this->addBaseInfo($baseInfoList);
        $this->addAddress($addrList);
    }

    public function addAddress(array $addrList): void
    {
        foreach ($addrList as $addr => $name) {
            if (is_string($addr) && is_string($name)) {
                $this->savedAddrList[$addr] = $name;
                $this->mail->addAddress($addr, $name);
            }
        }
    }

    public function delAddress(array $addrList): void
    {
        foreach ($addrList as $addr) {
            if (!is_string($addr)) { continue; }
            unset($this->savedAddrList[$addr]);
        }
        $this->mail->clearAddresses();
        foreach ($this->savedAddrList as $addr => $name) {
            $this->mail->addAddress($addr, $name);
        }
    }

    public function addBaseInfo(array $baseInfoList): void
    {
        foreach ($baseInfoList as $k => $v) {
            if (is_string($k) && is_string($v)) {
                $this->baseInfoList[$k] = $v;
            }
        }
    }

    public function addEmail(WebApiEmail $email): void
    {
        $this->savedEmailList[spl_object_hash($email)] = $email;
    }

    public function delEmail(WebApiEmail $email): void
    {
        unset($this->savedEmailList[spl_object_hash($email)]);
    }

    public function sendAllSavedEmail(): void
    {
        foreach ($this->savedEmailList as $email) {
            if ($this->send($email)) {
                $this->delEmail($email);
            }
        }
    }

    public function clearAllSavedEmail(): void
    {
        $this->savedEmailList = [];
    }

    /**
     * @param bool $isThrowEx Whether to throw caught exception
     * @throws PHPMailerException
     * @return bool
     */
    public function send(WebApiEmail $email, bool $isThrowEx = FALSE): bool
    {
        $caughtEx = NULL;
        $result = TRUE;
        $emailAddrList = $email->getAddrList();
        try {
            // if not empty then override WebApiEmailSender::$savedAddrList
            if (!empty($emailAddrList)) {
                $this->mail->clearAddresses();
                foreach ($emailAddrList as $addr => $name) {
                    $this->mail->addAddress($addr, $name);
                }
            }
            $result = $this->sendRaw(
                $email->getSubject(), 
                $this->getTable(array_merge($this->baseInfoList, $email->getRows()))
            );
        } catch (PHPMailerException $e) {
            $caughtEx = $e;
            $result = FALSE;
        } finally {
            // if not empty then restore WebApiEmailSender::$savedAddrList
            if (!empty($emailAddrList)) {
                $this->mail->clearAddresses();
                foreach ($this->savedAddrList as $addr => $name) {
                    $this->mail->addAddress($addr, $name);
                }
            }
            if ($caughtEx !== NULL) {
                if ($isThrowEx) {
                    throw $e;
                } else {
                    $msg = "[".basename(__FILE__)."][".__METHOD__."] ".$e->getMessage();
                    error_log($msg);
                    $result = FALSE;
                }
            }
            return $result;
        }
    }

    /**
     * @param string $subject Email subject
     * @param string $body Email body
     * @throws PHPMailerException
     * @return bool Whether the mail is sent successfully
     */
    public function sendRaw(string $subject, string $body): bool
    {
        $this->mail->Subject = $subject;
        $this->mail->Body = $body;
        return $this->mail->send();
    }

    private function getTable(array $arr): string
    {
        $table = '<table border="1">';
        foreach ($arr as $k => $v) {
            $table .= "<tr><th>$k</th><td>$v</td></tr>";
        }
        $table .= '</table>';
        return $table;
    }
}

final class WebApiEmail
{
    private string $subject = "";
    public function getSubject(): string { return $this->subject; }

    private array $rows = [];
    public function getRows(): array { return $this->rows; }

    /**
     * @var array $addrList Overrides WebApiEmailSender::$savedAddrList
     */
    private array $addrList = [];
    public function getAddrList(): array { return $this->addrList; }

    public function __construct(string $subject, array $rows, array $addrList = [])
    {
        $this->subject = $subject;
        foreach ($rows as $k => $v) {
            if (is_string($k) && is_string($v)) {
                $this->rows[$k] = $v;
            }
        }
        foreach ($addrList as $addr => $name) {
            if (is_string($addr) && is_string($addr)) {
                $this->addrList[$addr] = $name;
            }
        }
    }

    public static function fromException(string $subject, Exception $e, array $other = []): self
    {
        foreach ($other as $k => $v) {
            if (!(is_string($k) && is_string($v))) {
                unset($other[$k]);
            }
        }
        return new self($subject, array_merge($other, [ 
            "Error" => str_replace("\n", "<br>", $e->getMessage()), 
            "Trace" => str_replace("\n", "<br>", $e->getTraceAsString())
        ]));
    }

    public static function errorOnly(string $subject, string $errMsg): self 
    {
        return new self($subject, [ "Error" => $errMsg ]);
    }
}
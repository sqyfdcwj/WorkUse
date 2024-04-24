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

trait WebApiEmailAddrTrait
{
    protected array $addrList = [];
    public function getAddrList(): array { return $this->addrList; }

    public function addAddr(string $addr, string $name): void { $this->addrList[$addr] = $name; }

    public function addAddrList(array $addrList): void
    {
        foreach ($addrList as $addr => $name) {
            if (is_string($addr) && (is_string($name) || is_numeric($name))) {
                $this->addAddr($addr, $name);
            }
        }
    }

    public function delAddr(string $addr): void { unset($this->addrList[$addr]); }

    public function delAddrList(array $addrList): void
    {
        foreach ($addrList as $addr) { 
            if (is_string($addr)) { 
                $this->delAddr($addr); 
            } 
        }
    }
}

final class WebApiEmailSender 
{
    use WebApiEmailAddrTrait;

    private PHPMailer $mail;

    private array $savedEmailList = [];

    public function __construct(WebApiEmailUser $user, array $addrList, bool $isUseTLS = FALSE)
    {
        $this->mail = new PHPMailer(TRUE);  // Set true to throw caught PHPMailerException
        $this->mail->IsSMTP();
        $this->mail->IsHTML(TRUE);
        $this->mail->CharSet = "UTF-8";
        $this->mail->SMTPAuth = TRUE;
        $this->mail->SMTPAutoTLS = FALSE;
        if ($isUseTLS) {
            $this->mail->SMTPSecure = PHPMailer::ENCRYPTION_STARTTLS;   // Default value = ''
        } else {
            $this->mail->SMTPSecure = "";
        }
        $this->mail->Host = $user->host;
        $this->mail->Port = $user->port;
        $this->mail->Username = $user->username;
        $this->mail->Password = $user->password;
        $this->mail->From = $user->from;
        $this->mail->FromName = $user->fromName;
        
        $this->addAddrList($addrList);
    }

    public function addEmail(AWebApiEmail $email): void
    {
        $this->savedEmailList[spl_object_hash($email)] = $email;
    }

    public function delEmail(AWebApiEmail $email): void
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
    public function send(AWebApiEmail $email, bool $isThrowEx = FALSE): bool
    {
        $caughtEx = NULL;
        $result = TRUE;
        $emailAddrList = $email->getAddrList();
        try {
            // if not empty then override WebApiEmailSender::$savedAddrList
            if (!empty($emailAddrList)) {
                $this->switchAddr($emailAddrList);
            }
            $result = $this->sendRaw($email->getSubject(), $email->getBody());
        } catch (PHPMailerException $e) {
            $caughtEx = $e;
            $result = FALSE;
        } finally {
            // if not empty then restore WebApiEmailSender::$savedAddrList
            if (!empty($emailAddrList)) {
                $this->switchAddr($this->addrList);
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

    private function switchAddr(array $addrList): void
    {
        $this->mail->clearAddresses();
        foreach ($addrList as $addr => $name) {
            $this->mail->addAddress($addr, $name);
        }
    }
}

abstract class AWebApiEmail
{
    use WebApiEmailAddrTrait;

    /**
     * @var string $subject Email Subject
     */
    protected string $subject;
    public function getSubject(): string { return $this->subject; }

    abstract public function getBody(): string;

    public function __construct(string $subject, array $addrList = [])
    {
        $this->subject = $subject;
        $this->addAddrList($addrList);
    }
}

/**
 * Default WebApiEmail which contains HTML table content
 */
final class WebApiEmailHtmlDefault extends AWebApiEmail
{
    private array $fieldList;

    public function __construct(string $subject, array $fieldList, array $addrList = [])
    {
        parent::__construct($subject, $addrList);
        $this->fieldList = array_filter($fieldList, function ($k, $v) {
            return (is_string($k) || is_numeric($k))
                && (is_string($v) || is_numeric($v));
        }, ARRAY_FILTER_USE_BOTH);
    }

    public function getBody(): string
    {
        if (empty($this->fieldList)) { return ""; }
        ob_start();
?>
        <table border="1">
        <?php foreach ($this->fieldList as $k => $v): ?>
            <tr><td><?=$k;?></td><td><?=$v;?></td></tr>
        <?php endforeach; ?>
        </table>
<?php
        $result = ob_get_contents();
        ob_clean();
        return $result;
    }

    public static function fromException(string $subject, Exception $ex, array $other, array $addrList): self
    {
        return new self($subject, array_merge($other, [
            "Error" => str_replace("\n", "<br>", $ex->getMessage()), 
            "Trace" => str_replace("\n", "<br>", $ex->getTraceAsString())
        ]), $addrList);
    }

    public static function errorOnly(string $subject, string $errMsg, array $other, array $addrList): self 
    {
        return new self($subject, array_merge($other, [ "Error" => $errMsg ]), $addrList);
    }
}

final class WebApiEmail extends AWebApiEmail
{
    /**
     * @var string $body Email body
     */
    private string $body = "";
    public function getBody(): string { return $this->body; }

    public function __construct(string $subject, string $body, array $addrList = [])
    {
        parent::__construct($subject, $addrList);
        $this->body = $body;
    }
}
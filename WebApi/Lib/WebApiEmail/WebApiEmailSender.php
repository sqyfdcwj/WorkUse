<?php

namespace WebApiEmail;

use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception as PHPMailerException;

final class WebApiEmailSender 
{
    private PHPMailer $mail;

    private array $savedAddrList = [];

    private array $savedEmailList = [];

    public function __construct(
        WebApiEmailUser $user, 
        array $addrList
    )
    {
        $this->mail = new PHPMailer(true);  // Set true to throw caught PHPMailerException
        $this->mail->IsSMTP();
        $this->mail->IsHTML(true);
        $this->mail->CharSet = "UTF-8";
        $this->mail->SMTPAuth = true;
        $this->mail->SMTPAutoTLS = false;
        $this->mail->SMTPSecure = PHPMailer::ENCRYPTION_STARTTLS;   // Default value = ''

        $this->mail->Host = $user->host;
        $this->mail->Port = $user->port;
        $this->mail->Username = $user->username;
        $this->mail->Password = $user->password;
        $this->mail->From = $user->from;
        $this->mail->FromName = $user->fromName;
        
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
    public function send(WebApiEmail $email, bool $isThrowEx = false): bool
    {
        $caughtEx = null;
        $result = true;
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
                $email->getBody(),
            );
        } catch (PHPMailerException $e) {
            $caughtEx = $e;
            $result = false;
        } finally {
            // if not empty then restore WebApiEmailSender::$savedAddrList
            if (!empty($emailAddrList)) {
                $this->mail->clearAddresses();
                foreach ($this->savedAddrList as $addr => $name) {
                    $this->mail->addAddress($addr, $name);
                }
            }
            if ($caughtEx !== null) {
                if ($isThrowEx) {
                    throw $e;
                } else {
                    $msg = "[".basename(__FILE__)."][".__METHOD__."] ".$e->getMessage();
                    error_log($msg);
                    $result = false;
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
}
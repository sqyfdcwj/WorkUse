<?php

namespace WebApiEmail;

final class WebApiEmail
{
    private string $subject = "";
    public function getSubject(): string { return $this->subject; }

    private string $body = "";
    public function getBody(): string { return $this->body; }

    /**
     * @var array $addrList Overrides WebApiEmailSender::$savedAddrList
     */
    private array $addrList = [];
    public function getAddrList(): array { return $this->addrList; }

    public function __construct(string $subject, string $body, array $addrList = [])
    {
        $this->subject = $subject;
        $this->body = $body;
        $this->addAddressList($addrList);
    }

    public function addAddressList(array $addrList): void
    {
        foreach ($addrList as $addr => $name) {
            if (is_string($addr) && is_string($name)) { 
                $this->addAddress($addr, $name);
            }
        }
    }

    public function addAddress(string $addr, string $name): void 
    {
        $this->addrList[$addr] = $name;
    }

    public static function withPDOEx(string $subject, \PDOException $e, string $dsn, array $addrList = []): self
    {
        return self::withEx($subject, $e, [ "Database" => $dsn ], $addrList);
    }

    public static function withEx(string $subject, \Exception $e, array $other = [], $addrList = []): self
    {
        return new self(
            $subject, 
            self::toHtmlTable(array_merge([
                "URL" => $_SERVER["HTTP_HOST"].$_SERVER["REQUEST_URI"]
            ],
            $other,
            [
                "Error" => str_replace("\n", "<br>", $e->getMessage()), 
                "Trace" => str_replace("\n", "<br>", $e->getTraceAsString())
            ])), 
            $addrList
        );
    }
    public static function toHtmlTable(array $list): string
    {
        ob_start();
?>
        <table border="1">
        <?php foreach ($list as $k => $v): ?>
            <?php if ((is_string($k) || is_numeric($k)) && (is_string($v) || is_numeric($v))): ?>
                <tr>
                    <td><?=$k;?></td>
                    <td><?=$v;?></td>
                </tr>
            <?php endif; ?>
        <?php endforeach; ?>
        </table>
<?php
        $result = ob_get_contents();
        ob_end_clean();
        return $result;
    }
}
<?php

require_once '../include/ipworksedi_as2sender.php';
require_once '../include/ipworksedi_as2receiver.php';
require_once '../include/ipworksedi_certmgr.php';
require_once '../include/ipworksedi_edifacttranslator.php';
require_once '../include/ipworksedi_edifactvalidator.php';
require_once '../include/ipworksedi_const.php';

require_once 'IPWorksEDILicense.php';

final class EDITranslator
{
    private IPWorksEDI_EDIFACTTranslator $t;

    private array $outputFormatMap = [
        EDIFACTTRANSLATOR_OUTPUTFORMAT_JSON => "JSON",
        EDIFACTTRANSLATOR_OUTPUTFORMAT_XML => "XML",
        EDIFACTTRANSLATOR_OUTPUTFORMAT_EDIFACT => "EDIFACT"
    ];
    
    public function __construct()
    {
        $this->t = new IPWorksEDI_EDIFACTTranslator();
        $this->t->setRuntimeLicense(IPWorksEDILicense::LICENSE);
    }

    public function toJson(
        string $input, 
        string $schemaFileName,
        bool $isThrowEx = FALSE
    ): EDITranslatorResult {
        return $this->convert(
            $input,
            EDIFACTTRANSLATOR_INPUTFORMAT_EDIFACT,
            EDIFACTTRANSLATOR_OUTPUTFORMAT_JSON,
            EDIFACTTRANSLATOR_SCHEMAFORMAT_JSON,
            $schemaFileName,
            $isThrowEx
        );
    }

    public function toXml(
        string $input, 
        string $schemaFileName,
        bool $isThrowEx = FALSE
    ): EDITranslatorResult {
        return $this->convert(
            $input,
            EDIFACTTRANSLATOR_INPUTFORMAT_EDIFACT,
            EDIFACTTRANSLATOR_OUTPUTFORMAT_XML,
            EDIFACTTRANSLATOR_SCHEMAFORMAT_JSON,
            $schemaFileName,
            $isThrowEx
        );
    }

    public function fromJson(
        string $input, 
        string $schemaFileName,
        bool $isThrowEx = FALSE
    ): EDITranslatorResult
    {
        return $this->convert(
            $input,
            EDIFACTTRANSLATOR_INPUTFORMAT_JSON,
            EDIFACTTRANSLATOR_OUTPUTFORMAT_EDIFACT,
            EDIFACTTRANSLATOR_SCHEMAFORMAT_JSON,
            $schemaFileName,
            $isThrowEx
        );
    }

    public function fromXml(
        string $input, 
        string $schemaFileName,
        bool $isThrowEx = FALSE
    ): EDITranslatorResult
    {
        return $this->convert(
            $input,
            EDIFACTTRANSLATOR_INPUTFORMAT_XML,
            EDIFACTTRANSLATOR_OUTPUTFORMAT_EDIFACT,
            EDIFACTTRANSLATOR_SCHEMAFORMAT_JSON,
            $schemaFileName,
            $isThrowEx
        );
    }

    private function convert(
        string $input,
        int $inputFormat,
        int $outputFormat,
        int $schemaFormat,
        string $schemaFileName,
        bool $inputFromFile = FALSE,
        bool $isThrowEx = FALSE
    ): EDITranslatorResult { 
        try {
            $this->t->setInputFormat($inputFormat);
            $this->t->setOutputFormat($outputFormat);
            $this->t->setSchemaFormat($schemaFormat);
    
            $this->t->doLoadSchema($schemaFileName);    // Ex
            
            if ($inputFromFile) {
                $this->t->setInputFile($input);
            } else {
                $this->t->setInputData($input);
            }

            $this->t->doTranslate();    // Ex
            return new EDITranslatorResult(
                NULL, 
                $this->t->getOutputData(),
                $this->outputFormatMap[$outputFormat] ?? ""
            );
        } catch (Exception $e) {
            if ($isThrowEx) {
                throw $e;
            }
            return new EDITranslatorResult($e, "", "");
        }
    }
}

final class EDITranslatorResult
{
    private ?Exception $ex = NULL;
    public function getException(): ?Exception { return $this->ex; }

    public function getIsSuccess(): bool { return $this->ex === NULL; }
    public function getErrMsg(): ?string { return $this->ex === NULL ? NULL : $this->ex->getMessage(); }

    private string $outputFormat = "";
    public function getOutputFormat(): string { return $this->outputFormat; }
    public function getIsEDI(): bool { return $this->outputFormat === "EDIFACT"; }
    public function getIsXML(): bool { return $this->outputFormat === "XML"; }
    public function getIsJson(): bool { return $this->outputFormat === "JSON"; }

    private string $output = "";
    public function getOutput(): string { return $this->output; }

    public function __construct(
        ?Exception $ex,
        string $output,
        string $outputFormat
    ) { 
        $this->ex = $ex;
        $this->output = $output;
        $this->outputFormat = $outputFormat;
    }
}

final class EDIValidator
{
    private IPWorksEDI_EDIFACTValidator $v;

    public function __construct()
    {
        $this->v = new IPWorksEDI_EDIFACTValidator();
        $this->v->setRuntimeLicense(IPWorksEDILicense::LICENSE);
    }

    public function validate(string $schemaFileName): ?string
    {
        try {
            $this->v->doLoadSchema($schemaFileName);
            $this->v->doValidate();
            return NULL;
        } catch (Exception $e) {
            return $e->getMessage();
        }
    }
}

final class EDICert
{
    public string $fileName;
    public ?string $password;

    public string $subject;

    public function __construct(string $fileName, ?string $password, string $subject)
    {
        $this->fileName = $fileName;
        $this->password = $password;
        $this->subject = $subject;
    }
}

final class EDIAS2Result
{
    public ?string $mdnReceiptHeaders;
    public ?string $mdnReceiptMessage;
    public ?string $mdnReceiptMDN;
    public ?string $mdnReceiptContent;

    public function __construct(
        ?string $mdnReceiptHeaders,
        ?string $mdnReceiptMessage,
        ?string $mdnReceiptMDN,
        ?string $mdnReceiptContent
    )
    {
        $this->mdnReceiptHeaders = $mdnReceiptHeaders;
        $this->mdnReceiptMessage = $mdnReceiptMessage;
        $this->mdnReceiptMDN = $mdnReceiptMDN;
        $this->mdnReceiptContent = $mdnReceiptContent;
    }
}

final class EDIAS2Sender
{
    private IPWorksEDI_AS2Sender $as2;

    public function __construct(
        EDICert $senderKey,
        EDICert $receiverKey
    )
    {
        $this->as2 = new IPWorksEDI_AS2Sender();
        $this->as2->setRuntimeLicense(IPWorksEDILicense::LICENSE);
        $this->as2->setLogDirectory(basename(__DIR__)."/AS2 Logs/%date%/From %as2from%/%messageid%");
        $this->as2->doConfig("LogOptions=All");
        $this->as2->setMDNOptions("");
        $this->as2->setCompressionFormat(AS2SENDER_COMPRESSIONFORMAT_ZLIB);

        $this->as2->setSignatureAlgorithm("sha-256");
        $this->as2->setEncryptionAlgorithm("3des");

        $this->as2->setSigningCertStoreType(AS2SENDER_SIGNINGCERTSTORETYPE_PFXFILE);      // 2 (demo)
        $this->as2->setSigningCertStore($senderKey->fileName);
        if ($senderKey->password !== NULL) {
            $this->as2->setSigningCertStorePassword($senderKey->password);
        }
        $this->as2->setSigningCertSubject($senderKey->subject);

        $this->as2->setRecipientCertCount(1);
        $this->as2->setRecipientCertStoreType(0, AS2RECEIVER_CERTSTORETYPE_PEMKEY_FILE);  // 6 (demo)
        $this->as2->setRecipientCertStore(0, $receiverKey->fileName);
        if ($receiverKey->password !== NULL) {
            $this->as2->setRecipientCertStorePassword(0, $receiverKey->password);
        }
        $this->as2->setRecipientCertSubject(0, $receiverKey->subject);

        $this->as2->setReceiptSignerCertStoreType(AS2RECEIVER_SIGNERCERTSTORETYPE_PEMKEY_FILE);
        $this->as2->setReceiptSignerCertStore($receiverKey->fileName);
        if ($receiverKey->password !== NULL) {
            $this->as2->setReceiptSignerCertStorePassword($receiverKey->password);
        }
        $this->as2->setReceiptSignerCertSubject($receiverKey->subject);

    }

    /**
     * @throws Exception
     * @return EDIAS2Result
     */
    public function send(
        string $from,
        string $to,
        string $url,
        string $mdnTo,
        string $ediData
    ): EDIAS2Result
    {
        $this->as2->setAS2From($from);
        $this->as2->setAS2To($to);
        $this->as2->setUrl($url);
        $this->as2->setMDNTo($mdnTo);
        $this->as2->setEDIData($ediData);
        $this->as2->doPost();
        return new EDIAS2Result(
            $this->as2->getMDNReceiptHeaders(),
            $this->as2->getMDNReceiptMessage(),
            $this->as2->getMDNReceiptMDN(),
            $this->as2->getMDNReceiptContent()
        );
    }
}

final class EDIAS2Receiver
{
    private IPWorksEDI_AS2Receiver $as2;

    public function __construct(        
        EDICert $senderKey,
        EDICert $receiverKey
    )
    {
        $this->as2 = new IPWorksEDI_AS2Receiver();
        $this->as2->setRuntimeLicense(IPWorksEDILicense::LICENSE);
        $this->as2->setLogDirectory(__DIR__."/AS2 Logs/%date%/From %as2from%/%messageid%");
        $this->as2->doConfig("LogOptions=All");
        $headers = getallheaders();
        $this->as2->setRequestHeaderCount(count($headers));
        $idx = 0;
        foreach ($headers as $field => $value) {
            $this->as2->setRequestHeaderField($idx, $field);
            $this->as2->setRequestHeaderValue($idx, $value);
            $idx++;
        }

        $this->as2->setSignerCertStoreType(AS2RECEIVER_CERTSTORETYPE_PEMKEY_FILE);
        $this->as2->setSignerCertStore($senderKey->fileName);
        if ($senderKey->password !== NULL) {
            $this->as2->setSignerCertStorePassword($senderKey->password);
        }
        $this->as2->setSignerCertSubject($senderKey->subject);
    
        # Use receiver's private key to decrypte content
        $this->as2->setCertStoreType(AS2RECEIVER_CERTSTORETYPE_PFXFILE);
        $this->as2->setCertStore($receiverKey->fileName);
        if ($receiverKey->password !== NULL) {
            $this->as2->setCertStorePassword($receiverKey->password);
        }
        $this->as2->setCertSubject($receiverKey->password);
    }

    /**
     * @throws Exception
     * @return string
     */
    public function parse(string $body): string
    {
        try {
            $this->as2->setRequest($body);
            $this->as2->doReadRequest();
            $this->as2->doParseRequest();
            return $this->as2->getEDIData();
        } catch (Exception $e) {
            $this->as2->doConfig("ProcessingError=true");
            throw $e;
        }

    }

    /**
     * @throws Exception
     * @return EDIAS2Result
     */
    public function createMDNReceipt(string $receiptMessage): EDIAS2Result
    {
        $this->as2->doCreateMDNReceipt("", "", $receiptMessage);
        $mdnHeaders = explode("\r\n", $this->as2->getMDNReceiptHeaders());
        foreach ($mdnHeaders as $header) {
            if (strlen($header) > 0) { 
                header($header);
            }
        }
        return new EDIAS2Result(
            $this->as2->getMDNReceiptHeaders(),
            $this->as2->getMDNReceiptMessage(),
            $this->as2->getMDNReceiptMDN(),
            $this->as2->getMDNReceiptContent()
        );
    }
}
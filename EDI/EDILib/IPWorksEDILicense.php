<?php


final class IPWorksEDILicense
{
    public const LICENSE = "42455048415A30343033323433305745425452314131005A51474C474545534259555155464851003030303030303030000030565833563158394A4D50410000";
}

final class EDICertStore
{
    /*
    Certificates with private keys may be stored in several ways. 
    One common way is to use a file in PKCS12 format (typically with a .pfx or .p12 extension.

    You will also need to obtain certificates from your trading partners. 
    These will be in PKCS#7 or Base-64 encoded format, and will contain public keys only. 
    Typically, these certificates will have extensions such as .cer, .crt, or .der.

    ####

    The RecipientCert, ReceiptSignerCert, and SSLAcceptServerCert properties on the sender side, 
    and the SignerCert property on the receiver side follow this format. 
    Please see Configuring Message Security for information on how to use these properties.



    Client (Sender)
    IPWorksEDI_AS2Sender::setSigningCertStore("./as2sender.pfx");   // Sender's private key
    IPWorksEDI_AS2Sender::setReceiptSignerCertStore("./as2receiver.cer");   // Receiver's public key

    Server (Receiver)
    IPWorksEDI_AS2Receiver::setCertStore("./as2receiver.pfx");      // Receiver's private key
    IPWorksEDI_AS2Receiver::setSignerCertStore("./as2sender.cer");  // Sender's public key

    */

    # as2sender_pfx
    public const DEMO_SENDER_PRIVATE_KEY = "./as2sender.pfx";
    public const DEMO_SENDER_PUBLIC_KEY = "./as2sender.cer";

    public const DEMO_RECEIVER_PRIVATE_KEY = "./as2receiver.pfx";
    public const DEMO_RECEIVER_PUBLIC_KEY = "./as2receiver.cer";

    public const EDI01_PFX_PRIVATE_KEY = "./edi01.xtrapower.org/domain.pfx";   

    public const EDI01_CER_PUBLIC_KEY = "./edi01.xtrapower.org/fullchain.cer";

    public const EDI02_PFX_PRIVATE_KEY = "./edi02.xtrapower.org/domain.pfx";   

    public const EDI02_CER_PUBLIC_KEY = "./edi02.xtrapower.org/fullchain.cer";
}

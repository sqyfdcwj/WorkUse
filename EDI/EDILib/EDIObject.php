<!-- <?php

/*

UNA (Document level, optional)
UNB (Interchange level, compulsory)
    UNG (Functional group level, optional)
        UNH (Transaction set)
        UNT (Transaction set footer)
    UNE (Functional group footer)
UNZ (Interchange footer)

https://en.wikipedia.org/wiki/EDIFACT

# There is only 1 interchange in each EDI 
# An interchange can contains
# A segment can contain Loop, Composite, and Element
# A Loop contains ONLY segment

InterchangeHeader
    MessageHeader
    SegmentList
        Segment
            Loop
                Segment
            Composite
                Element
            Element
    MessageFooter
InterchangeFooter
*/

/*
interface IEDIToArray
{
    public function toArray(): array;
}

class EDINode implements IEDIToArray
{
    protected string $type;
    protected array $children = [];
    public function __construct(string $type, array $children)
    {
        $this->type = $type;
        $this->children = $children;
    }

    public function toArray(): array
    {
        return [ "type" => $this->type ];
    }
}

final class EDISegment extends EDINode
{
    private string $name = "";

    public function __construct(string $name, array $children)
    { 
        $this->name = $name;
        parent::__construct("Segment", array_filter($children, function ($v) {
            return is_array($v) || is_numeric($v) || is_string($v);
        }));
    }

    public function toArray(): array
    {
        $result = [];
        foreach ($this->children as $idx => $child) {
            $key = $this->name.($idx + 1);
            if (is_array($child)) {
                $result[$key]["type"] = "Composite";
                foreach ($child as $childIdx => $cev) {
                    $childKey = $key.($childIdx + 1);
                    $result[$key][$childKey]["value"] = $cev;
                }
            } else {
                $result[$key] = [ "value" => $child ];
            }
        }
        return array_merge(parent::toArray(), [ "name" => $this->name ], $result);
    }
}

final class EDILoop extends EDINode
{
    private string $name = "";

    public function __construct(string $name, array $children)
    {
        $this->name = $name;
        parent::__construct("Loop", array_filter($children, function ($v) { 
            return ($v instanceof EDISegment) || ($v instanceof EDILoop); 
        }));
    }

    public function toArray(): array
    {
        return array_merge(parent::toArray(), [ 
            $this->name => array_map(function (IEDIToArray $toa) { return $toa->toArray(); }, $this->children) 
        ]);
    }
}

final class EDITransactonSet implements IEDIToArray
{
    private string $messageRef = "";
    private array $segments = [];

    public function __construct(string $messageRef, array $segments)
    {
        $this->messageRef = $messageRef;
        $this->segments = array_filter($segments, function ($v) { 
            return ($v instanceof EDISegment) || ($v instanceof EDILoop); 
        });
    }

    public function toArray(): array
    {
        return [
            "meta" => [
                "type" => "TransactionSet",
                "UNH1" => [ "value" => $this->messageRef ],
                "UNH2" => [
                    "type" => "Composite",
                    "UNH2.1" => [ "value" => "ORDERS" ],
                    "UNH2.2" => [ "value" => "D" ],
                    "UNH2.3" => [ "value" => "97A" ],
                    "UNH2.4" => [ "value" => "UN" ],
                    "UNH2.5" => [ "value" => "EDPO04" ],
                ]
            ],
            "segments" => array_map(function (IEDIToArray $toa) { return $toa->toArray(); }, $this->segments),
            "UNT" => [
                "type" => "Segment",
                "UNT01" => [ "value" => count($this->segments) ],  // Also included UNH and UNT
                "UNT02" => [ "value" => $this->messageRef ],
            ]
        ];
    }
}

final class EDIInterchange implements IEDIToArray
{
    private string $sender = "";
    private string $recipient = ""; // IFX.B2B.PROD
    private string $preparationDate = "";
    private string $preparationTime = ""; 
    private string $interchangeControlRef = "";
    private string $applicationRef = "";    // ORDERS

    private array $transactionSets;

    public function __construct(
        string $sender,
        string $recipient,
        string $preparationDate,
        string $preparationTime,
        string $interchangeControlRef,
        string $applicationRef,
        array $transactionSets
    )
    {
        $this->sender = $sender;
        $this->recipient = $recipient;
        $this->preparationDate = $preparationDate;
        $this->preparationTime = $preparationTime;
        $this->interchangeControlRef = $interchangeControlRef;
        $this->applicationRef = $applicationRef;
        $this->transactionSets = array_filter($transactionSets, function ($v) {
            return $v instanceof EDITransactonSet;
        });
    }

    public function toArray(): array 
    {
        return [
            "meta" => [
                "type" => "Interchange",
                "UNB1" => [
                    "type" => "Composite",
                    "UNB1.1" => [ "value" => "UNOA" ],
                    "UNB1.2" => [ "value" => "1" ]
                ],
                "UNB2" => [
                    "type" => "Composite",
                    "UNB2.1" => [ "value" => $this->sender ]
                ],
                "UNB3" => [
                    "type" => "Composite",
                    "UNB3.1" => [ "value" => $this->recipient ]
                ],
                "UNB4" => [
                    "type" => "Composite",
                    "UNB4.1" => [ "value" => $this->preparationDate ],
                    "UNB4.2" => [ "value" => $this->preparationTime ]
                ],
                "UNB5" => [ "value" => $this->interchangeControlRef ],
                "UNB6" => [ 
                    "type" => "Composite",
                    "value" => "" 
                ],  
                "UNB7" => [ "value" => $this->applicationRef ],
            ],
            "transactionsets" => array_map(function (EDITransactonSet $v) { return $v->toArray(); }, $this->transactionSets),
            "UNZ" => [
                "type" => "Segment",
                "UNZ1" => [ "value" => 1 ],
                "UNZ2" => [ "value" => $this->interchangeControlRef ]
            ]
        ];
    }
}

final class EDIInterchangeHeader implements IEDIToArray
{
    private array $children = [];

    public function __construct(array $children)
    {
        $this->children = array_filter($children, function ($v) {
            return is_array($v) || is_string($v) || is_numeric($v);
        });
    }

    public function toArray(): array
    {
        return array_merge([ "type" => "Interchange" ]);
    }
}
*/
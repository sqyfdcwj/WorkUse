
<?php 

require_once 'EDIFilter.php';

function isSeg($seg): bool
{ return is_array($seg) && isset($seg["type"]) && $seg["type"] === "Segment" && isset($seg["name"]) && is_string($seg["name"]); }

function isLoop($loop): bool
{ return is_array($loop) && isset($loop["type"]) && $loop["type"] === "Loop"; }

function isPIA(string $v): bool { return strpos($v, "PIA") === 0; }

function parsePIA(string $pia): array
{
    $result = [];
    if (!isPIA($pia)) { return $result; }
    $arr = explode("+", $pia);
    if (count($arr) <= 2) { return $result; }
    for ($idx = 2; $idx < count($arr); $idx++) {
        $composite = $arr[$idx];
        $eList = explode(":", $composite);
        $result[$eList[1]] = $eList;
    }
    return $result;
}

################################
#  BEGIN OF EDI OBJECT
################################

function getEDILoop(array $list, int $idx): ?EDILoop
{
    if (!isset($list[$idx]) || !($list[$idx] instanceof EDILoop)) { return NULL; }
    return $list[$idx];
}

final class EDIInterchange 
{ 
    private array $header = [];
    private array $trailer = [];
    private array $list = [];   // Message list
    public function getList(): array { return $this->list; }

    public function __construct(array $obj)
    {
        if (isset($obj["meta"]) && is_array($obj["meta"])) {
            $this->header = $obj["meta"];
            unset($this->header["type"]);
            unset($this->header["delimiters"]);
        }
        if (isset($obj["transactionsets"]) && is_array($obj["transactionsets"])) {
            foreach ($obj["transactionsets"] as $msg) {
               $this->list[] = new EDIMessage($msg);
            }
        }
        if (isset($obj["UNZ"]) && is_array($obj["UNZ"])) {
            $this->trailer = $obj["UNZ"];
        }
    }

    public function getMessageCount(): int { return count($this->list); }

    public function getMessage(int $idx): ?EDIMessage
    { return isset($this->list[$idx]) ? $this->list[$idx] : NULL; }
}

final class EDIMessage 
{ 
    use EDIChildrenTrait;

    private array $header = [];
    private array $trailer = [];

    public function __construct(array $obj)
    {
        if (isset($obj["meta"]) && is_array($obj["meta"])) {
            $this->header = $obj["meta"];
        }
        if (isset($obj["segments"]) && is_array($obj["segments"])) {
            foreach ($obj["segments"] as $seg) {
                if (isSeg($seg)) {
                    $this->list[] = new EDISegment($seg);
                } else if (isLoop($seg)) {
                    $this->list[] = new EDILoop($seg);
                }
            }
        }
        if (isset($obj["UNT"]) && is_array($obj["UNT"])) {
            $this->trailer = $obj["UNT"];
            unset($this->trailer["type"]);
        }
    }

    public function findSeg(EDISegFilter $f): ?EDISegment 
    { 
        foreach ($this->list as $obj) {
            if (!($obj instanceof EDISegment)) { continue; }
            if ($f->predicate($obj)) {
                return $obj;
            }
        }
        return NULL;
    }

    public function findLoopList(EDILoopWithName $f): array
    {
        return array_values(array_filter($this->list, function ($v) use ($f) {
            return ($v instanceof EDILoop) && $f->predicate($v);
        }));
    }

    public function findLoop(EDILoopWithName $f): ?EDILoop 
    { 
        foreach ($this->list as $obj) {
            if (!($obj instanceof EDILoop)) { continue; }
            if ($f->predicate($obj)) {
                return $obj;
            }
        }
        return NULL;
    }

    public function findLoopSegVal(
        EDILoopWithName $loopFilter,
        EDISegFilter $segFilter,
        string $path
    ): ?string
    {
        $loop = $this->findLoop($loopFilter);
        if ($loop === NULL) { return NULL; }
        foreach ($loop->getChildren($loopFilter->getLoopName()) as $obj) {
            if (($obj instanceof EDISegment) && $segFilter->predicate($obj)) {
                return $obj->findValue($path);
            }
        }
        return NULL;
    }

    public function findSegVal(EDISegFilter $f, string $path): ?string 
    { 
        $list = array_filter($this->list, function ($v) use ($f) {
            return ($v instanceof EDISegment) && $f->predicate($v);
        });
        return ($seg = @array_pop($list)) ? $seg->findValue($path) : NULL;
    }
}

final class EDISegment 
{ 
    use EDIChildrenTrait;

    private string $name;
    public function getName(): string { return $this->name; }

    public function __construct(array $obj)
    {
        $this->name = $obj["name"];
        $this->list = $obj;
        unset($this->list["name"]);
        unset($this->list["type"]);
    }

    public function findValue(string $path): ?string
    {
        $result = $this->list;
        $keyList = explode("/", $path);
        foreach ($keyList as $key) {
            if (isset($result[$key])) {
                $result = $result[$key];
            } else {
                return NULL;
            }
        }
        return isset($result["value"]) && is_string($result["value"]) ? $result["value"] : NULL;
    }    
}

final class EDILoop 
{
    use EDIChildrenTrait;

    public function __construct(array $obj)
    {
        foreach ($obj as $k => $v) {
            if ($k === "type" || !is_array($v)) { continue; }
            $this->list[$k] = [];
            foreach ($v as $child) {
                if (isSeg($child)) {
                    $this->list[$k][] = new EDISegment($child);
                } else if (isLoop($child)) {
                    $this->list[$k][] = new EDILoop($child);
                }
            }
        }
    }

    public function hasKey(string $name): bool { return in_array($name, array_keys($this->list)); }

    public function getChildren(string $key): array { return @$this->list[$key] ?? []; }

    public function findSegment(string $key, EDISegFilter $f): ?EDISegment
    {
        return @array_pop(array_filter($this->getChildren($key), function ($v) use ($f) {
            return ($v instanceof EDISegment) && $f->predicate($v);
        }));
    }

    public function findSegVal(string $key, EDISegFilter $f, string $path): ?string
    {
        return ($seg = $this->findSegment($key, $f)) === NULL ? NULL : $seg->findValue($path);
    }

    public function findLoop(string $key, EDILoopFilter $f): ?EDILoop
    { return @array_pop($this->findLoopList($key, $f)); }

    public function findLoopList(string $key, EDILoopFilter $f): array
    {
        return @array_values(array_filter($this->getChildren($key), function ($v) use ($f) {
            return ($v instanceof EDILoop) && $f->predicate($v);
        }));
    }
}

trait EDIChildrenTrait
{
    private array $list = [];
    public function getList(): array { return $this->list; }
}

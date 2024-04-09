<?php

###

# Segments
function segWithName(string $name): EDISegWithName { return new EDISegWithName($name); }
function segWithVal(string $name, string $path, string $val): EDISegWithVal { return new EDISegWithVal($name, $path, $val); }

# Loops
function loopWithName(string $name): EDILoopWithName { return new EDILoopWithName($name); }
function loopSubSeg(string $name, EDISegFilter $f): EDILoopSubSeg { return new EDILoopSubSeg($name, $f); }

###

abstract class EDISegFilter
{
    public abstract function predicate(EDISegment $s): bool;
}

abstract class EDILoopFilter
{
    public abstract function predicate(EDILoop $l): bool;
}

class EDISegWithName extends EDISegFilter
{
    protected string $name;
    public function getName(): string { return $this->name; }
    public function __construct(string $name) { $this->name = $name; }

    public function predicate(EDISegment $s): bool { return $s->getName() === $this->name; }
}

class EDISegWithVal extends EDISegWithName
{
    protected string $name;
    protected string $path;
    protected string $value; 

    public function __construct(string $name, string $path, string $value) 
    { 
        parent::__construct($name);
        $this->path = $path;
        $this->value = $value;
    }

    public function predicate(EDISegment $s): bool 
    { 
        if (!parent::predicate($s)) { return FALSE; }
        return $s->findValue($this->path) === $this->value;
    }
}

###

class EDILoopWithName extends EDILoopFilter
{
    protected string $loopName;
    public function getLoopName(): string { return $this->loopName; }

    public function __construct(string $loopName) { $this->loopName = $loopName; }
    public function predicate(EDILoop $l): bool { return $l->hasKey($this->loopName); }
}

class EDILoopSubSeg extends EDILoopWithName
{
    protected EDISegFilter $segmentFilter;

    public function __construct(string $loopName, EDISegFilter $segmentFilter) { 
        parent::__construct($loopName);
        $this->segmentFilter = $segmentFilter;
    }
    public function predicate(EDILoop $l): bool { 
        if (!parent::predicate($l)) { return FALSE; }
        foreach ($l->getChildren($this->loopName) as $obj) {
            if (($obj instanceof EDISegment) && $this->segmentFilter->predicate($obj)) {
                return TRUE;
            }
        }
        return FALSE;
    }
}
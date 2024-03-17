<?php

foreach (glob("*.php") as $fileName)
{
    require_once $fileName;
}
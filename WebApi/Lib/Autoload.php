<?php

/**
 * @param string $className Fully qualified class name
 * @return void
 */
function xtra_php_autoload(string $className): void
{
    $fileName = basename(__DIR__)."/".str_replace("\\", "/", $className.".php");
    if (file_exists($fileName)) {
        require_once $fileName;
    } else {
        error_log("File not exists: $fileName");
        ob_start();
        debug_print_backtrace();
        $trace = ob_get_contents();
        ob_end_clean();
        error_log(str_replace("\n", "", $trace));
        die($trace);
    }
}

spl_autoload_register("xtra_php_autoload");


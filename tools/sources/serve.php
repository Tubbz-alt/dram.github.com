<?php

if (preg_match('/\.html$/', $_SERVER['SCRIPT_NAME'])) {
    exec('tools/sources/generate');
    echo file_get_contents(substr($_SERVER['SCRIPT_NAME'], 1));
} else {
    return false;
}

?>

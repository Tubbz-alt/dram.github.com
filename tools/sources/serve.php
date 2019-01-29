<?php

if (preg_match('/\.html$/', $_SERVER['SCRIPT_NAME'])) {
    exec('tools/sources/generate');
    echo file_get_contents($_SERVER['SCRIPT_FILENAME']);
} else {
    return false;
}

?>

<?php

$uri = $_SERVER['REQUEST_URI'];
$path = substr($uri, 1) . ($uri[-1] == '/' ? 'index.html' : '');
if (preg_match('/\.html$/', $path)) {
    exec('tools/sources/generate');
    echo file_get_contents($path);
} else {
    return false;
}

?>

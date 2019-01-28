<?php

if (preg_match('/(\/|\.html)$/', $_SERVER['REQUEST_URI']))
    error_log(shell_exec('make'));

return false;

?>

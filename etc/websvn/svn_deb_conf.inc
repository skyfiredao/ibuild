<?php
// please edit /etc/websvn/config.php 
// or use dpkg-reconfigure websvn
$config->parentPath("/local/srv/svn/repo/ichange");
$config->addRepository("ichange", "file:///local/srv/svn/repo/ichange");
$config->setEnscriptPath("/usr/bin");
$config->setSedPath("/bin");
$config->useEnscript();
?>

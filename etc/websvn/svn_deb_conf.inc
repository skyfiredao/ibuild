<?php
// please edit /etc/websvn/config.php 
// or use dpkg-reconfigure websvn
$config->parentPath("/local/srv/svn/repo/ichange");
$config->addRepository("[ichange] Tracking", "file:///local/srv/svn/repo/ichange");
$config->addRepository("[iversion] Tracking", "file:///local/srv/svn/repo/iversion/iversion/2017");
$config->setEnscriptPath("/usr/bin");
$config->setSedPath("/bin");
$config->useEnscript();
?>

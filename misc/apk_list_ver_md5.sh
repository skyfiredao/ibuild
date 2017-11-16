#!/bin/bash
# Copyright (C) <2014,2015>  <Ding Wei>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# Change log
# 170105 Create by Ding Wei
source /etc/bash.bashrc
export LC_CTYPE=C
export LC_ALL=C
export USER=`whoami`
export BUILD_SEC_TIME=`date +%s`
export SEED=$BUILD_SEC_TIME.$RANDOM
export BUILD_TIME=`date +%y%m%d%H%M%S`
export TASK_SPACE=/dev/shm

echo '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title></title>
<meta name="generator" content="HTML::TextToHTML v2.51"/>
</head>
<body>
<table border="1">
<tr><td align=center>APK Name</td><td align=center>Package Name</td><td align=right>Version</td><td align=center>MD5</td></tr>' >/tmp/apk.list.html

[[ ! -e file.list ]] && find >file.list
[[ ! $(grep out/target/product file.list) ]] && find out/ >>file.list
export AAPT=$(cat file.list | grep linux-x86/bin/aapt$ | head -n1)

for FILE_URL in $(cat file.list | grep out/target/product/ | egrep -v 'obj/APPS' | grep apk$)
do
    export TMP_APK_DUMP=$($AAPT dump badging $FILE_URL | grep version)
    export APK_NAME=$(basename $FILE_URL)
    export APK_PKG_NAME=$(echo $TMP_APK_DUMP | awk -F'name=' {'print $2'} | awk -F' ' {'print $1'} | sed "s/'//g")
    export APK_VER=$(echo $TMP_APK_DUMP | awk -F'versionName=' {'print $2'} | awk -F' ' {'print $1'} | sed "s/'//g")
    echo "<tr><td align=left>$APK_NAME</td><td align=left>$APK_PKG_NAME</td><td align=right>$APK_VER</td><td align=right>$(md5sum $FILE_URL | awk -F' ' {'print $1'})</td></tr>" >>/tmp/apk.list.html
done

echo '</table>
</body>
</html>
' >>/tmp/apk.list.html

echo /tmp/apk.list.html




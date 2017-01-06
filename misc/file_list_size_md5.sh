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

export TARGET_PATH=$1
[[ -z $TARGET_PATH ]] && export TARGET_PATH=$(pwd)
export TARGET_PATH_NAME=$(basename $TARGET_PATH)

pushd $TARGET_PATH
echo '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title></title>
<meta name="generator" content="HTML::TextToHTML v2.51"/>
</head>
<body>
<table border="1">
<tr><td style=width:50% align=center>File Name</td><td style=width:5% align="center">Size</td><td style=width:20% align=right>MD5</td></tr>' >/tmp/$TARGET_PATH_NAME.list.html

for FILE_URL in $(find -type f | awk -F'^./' {'print $2'} | sort -u)
do
    echo "<tr><td align=left>$FILE_URL</td><td align=right>$(du -sh $FILE_URL | awk -F' ' {'print $1'})</td><td align=right>$(md5sum $FILE_URL | awk -F' ' {'print $1'})</td></tr>" >>/tmp/$TARGET_PATH_NAME.list.html
done
popd >/dev/null 2>&1

echo '</table>
</body>
</html>
' >>/tmp/$TARGET_PATH_NAME.list.html

echo /tmp/$TARGET_PATH_NAME.list.html




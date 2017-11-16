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

export LICENSE_LIST='Apache License|GNU GENERAL PUBLIC LICENSE|Software License|OpenSSL License|compiler_rt License|"BSD-Like" license|MIT license|The FreeType Project LICENS|Common Public Licens|libc++abi License|License: BSD|Free Software Licens|"Old MIT" license|public domain|free license'

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
<tr><td align=center>NOTICE</td><td align=center>License</td><td align=right>Module</td><td align=center>Target</td></tr>' >/tmp/$TARGET_PATH_NAME.list.html

[[ ! -e file.list ]] && find >file.list
[[ ! $(grep out/target/product file.list) ]] && find out/ >>file.list

for FILE_URL in $(cat file.list | egrep -v 'hardware/qcom|/prebuilts/|/eclipse-|/tools/' | grep NOTICE$)
do
    export NOTICE_LICENSE=$(cat $FILE_URL | egrep "$LICENSE_LIST" | sed 's/Licensed under the //g' | sed 's/(the "License");//g' | sort -u)
    [[ -z $NOTICE_LICENSE ]] && export NOTICE_LICENSE='Copyright but License'
    export MK_PATH=$(dirname $FILE_URL)
    export MODULE_NAME=''
    export TARGET_MODULE_NAME=''
    [[ -e $MK_PATH/Android.mk ]] && export MODULE_NAME=$(egrep 'LOCAL_MODULE :=|LOCAL_MODULE:=' $MK_PATH/Android.mk | awk -F'=' {'print $2'} | head -n1)
[[ -z $MODULE_NAME ]] && echo $MK_PATH
    [[ ! -z $MODULE_NAME ]] && export TARGET_MODULE_URL=$(cat file.list | grep out/target | grep "$MODULE_NAME." | head -n1)
    [[ -e $TARGET_MODULE_URL ]] && export TARGET_MODULE_NAME=$(basename $TARGET_MODULE_URL)
    [[ ! -z $MODULE_NAME ]] && echo "<tr><td align=left>$(echo $FILE_URL | awk -F'^./' {'print $2'})</td><td align=left>$NOTICE_LICENSE</td><td align=right>$MODULE_NAME</td><td align=right>$TARGET_MODULE_NAME</td></tr>" >>/tmp/$TARGET_PATH_NAME.list.html
done
popd >/dev/null 2>&1

echo '</table>
</body>
</html>
' >>/tmp/$TARGET_PATH_NAME.list.html

echo /tmp/$TARGET_PATH_NAME.list.html




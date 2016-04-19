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
# 160419 Create by Ding Wei
source /etc/bash.bashrc
export LC_CTYPE=C
export LC_ALL=C
export USER=`whoami`
export BUILD_SEC_TIME=`date +%s`
export SEED=$BUILD_SEC_TIME.$RANDOM
export BUILD_TIME=`date +%y%m%d%H%M%S`
export TASK_SPACE=/dev/shm
export TOOL_PATH=$(dirname $0)

adb root
adb remount

for APP in `ls $OUT/system/app`
do
    cd $OUT/system/app/$APP
    for APK in `ls | grep apk$`
    do
        echo '----------------------------------------'
        rm -f *signed_*
        [[ `echo $APK | grep orig_` ]] && export APK=$(echo $APK | awk -F'orig_' {'print $2'})
        echo $OUT/system/app/$APP/$APK
        [[ ! -f orig_$APK ]] && cp $APK orig_$APK
        rm -f $APK
        redex orig_$APK -o $APK
        $TOOL_PATH/apk_sign.sh $APK platform
        adb push signed_$APK /system/app/$APP/$APK && rm -f signed_$APK
    done
done

 

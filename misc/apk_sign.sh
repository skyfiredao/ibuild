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

export APK=$1
export KEY=$2
if [[ ! -e $APK ]] ; then
    echo "Can NOT find $APK"
    exit
fi

if [[ ! -e $ANDROID_BUILD_TOP/build/target/product/security ]] ; then
    echo "can NOT find $ANDROID_BUILD_TOP/build/target/product/security"
    exit
else
    export KEY_PATH=$ANDROID_BUILD_TOP/build/target/product/security
fi

if [[ -z $KEY || ! `ls $ANDROID_BUILD_TOP/build/target/product/security | grep pem | grep $KEY` ]] ; then
    echo "Your $KEY out of key list:"
    ls $ANDROID_BUILD_TOP/build/target/product/security | grep pem | awk -F'.' {'print $1'}
    exit
fi


if [[ -e $ANDROID_BUILD_TOP/prebuilts/sdk/tools/lib/signapk.jar ]] ; then
    export SIGNAPK=$ANDROID_BUILD_TOP/prebuilts/sdk/tools/lib/signapk.jar
elif [[ -e $ANDROID_BUILD_TOP/out/host/linux-x86/framework/signapk.jar ]] ; then
    export SIGNAPK=$ANDROID_BUILD_TOP/out/host/linux-x86/framework/signapk.jar
fi

export SINGAPK_CMD="java -jar $SIGNAPK $KEY_PATH/$KEY.x509.pem $KEY_PATH/$KEY.pk8 $APK signed_$APK"
echo $SINGAPK_CMD
$SINGAPK_CMD

 

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
# 150306 Create by Ding Wei
source /etc/bash.bashrc
export LC_CTYPE=C
export LC_ALL=C
export USER=$(whoami)
export TASK_SPACE=/run/shm
export HOSTNAME=$(hostname)
export TOWEEK=$(date +%yw%V)

export IVERIFY_ROOT=$HOME/iverify
export IVERIFY_CONF=$HOME/iverify/conf/iverify.conf
if [[ ! -f $HOME/iverify/conf/iverify.conf ]] ; then
    echo -e "Please put iverify in your $HOME"
    exit 0
fi

echo ------------------------- `date`

EXIT()
{
 for SVN_M_URL in `svn st ~/iverify | grep '^M ' | awk -F' ' {'print $2'}`
 do
     rm -f $SVN_M_URL
 done
 svn up -q ~/iverify
 rm -f $IVERIFY_SPACE/build_info.[0-9]*
 rm -f $IVERIFY_SPACE/[0-9]*.build_info
 exit
}

CHK_IVERIFY_LOCK()
{
 export DEVICE_ID=$1
 export DEVICES_LOCK=$(ls $IVERIFY_SPACE | grep ^lock | wc -l)

 if [[ $DEVICES_LOCK -ge $DEVICES_WC ]] ; then
     touch $IVERIFY_SPACE/busy_node
 else
     rm -f $IVERIFY_SPACE/busy_node
 fi

 if [[ -f $IVERIFY_SPACE/busy_node ]] ; then
     echo "No free device"
     $NETCAT 127.0.0.1 4444
     $NETCAT 127.0.0.1 5555
     EXIT
 fi
}

NODE_STANDBY()
{
 export NETCAT=$(which nc)
     [[ -z $NETCAT ]] && export NETCAT="$IVERIFY_ROOT/bin/netcat.openbsd-u14.04"
 export HOST_MD5=$(echo $HOSTNAME | md5sum | awk -F' ' {'print $1'})
 export NOW=$(date +%y%m%d%H%M%S)
 export SEED=$NOW.$RANDOM

 $NETCAT -l 4444 >$IVERIFY_SPACE/build_info.$SEED
 export IVER=$(grep '^IVER=' $IVERIFY_SPACE/build_info.$SEED | awk -F'IVER=' {'print $2'})
     [[ -z $IVER ]] && export IVER=$SEED

 mv $IVERIFY_SPACE/build_info.$SEED $IVERIFY_SPACE/$IVER.build_info >/dev/null 2>&1 
 export IVERIFY=$(grep '^IVERIFY=' $IVERIFY_SPACE/$IVER.build_info | awk -F'IVERIFY=' {'print $2'})
 export RESULT=$(grep '^RESULT=' $IVERIFY_SPACE/$IVER.build_info | awk -F'RESULT=' {'print $2'})
 export MAKE_STATUS=$(grep '^MAKE_STATUS=' $IVERIFY_SPACE/$IVER.build_info | awk -F'MAKE_STATUS=' {'print $2'})
 export DOWNLOAD_PKG_NAME=$(grep '^DOWNLOAD_PKG_NAME=' $IVERIFY_SPACE/$IVER.build_info | awk -F'DOWNLOAD_PKG_NAME=' {'print $2'} | head -n1)

 if [[ $RESULT != PASSED || ! -z $MAKE_STATUS || -z $DOWNLOAD_PKG_NAME || -z $IVERIFY ]] ; then
     egrep 'RESULT=|MAKE_STATUS=|IVERIFY=|DOWNLOAD_PKG_NAME=' $IVERIFY_SPACE/$IVER.build_info
     EXIT
 fi

 export IBUILD_TARGET_PRODUCT=$(grep '^IBUILD_TARGET_PRODUCT=' $IVERIFY_SPACE/$IVER.build_info | awk -F'IBUILD_TARGET_PRODUCT=' {'print $2'})
 export ITASK_REV=$(grep '^ITASK_REV=' $IVERIFY_SPACE/$IVER.build_info | awk -F'ITASK_REV=' {'print $2'})
 export IVERIFY_DEVICE_ID=''

 $ADB devices >$TASK_SPACE/iverify/adb_devices.log

 for DEVICE_ONLINE in `cat $IVERIFY_SPACE/adb_devices.log | egrep -v 'daemon|attached|offline' | grep device$ | awk -F' ' {'print $1'}`
 do
     if [[ -f $IVERIFY_SPACE/inode.svn/$HOSTNAME.$IBUILD_TARGET_PRODUCT.$DEVICE_ONLINE && ! -f $IVERIFY_SPACE/lock.$DEVICE_ONLINE ]] ; then
         export IVERIFY_DEVICE_ID=$DEVICE_ONLINE
         echo $HOSTNAME.$IBUILD_TARGET_PRODUCT.$DEVICE_ONLINE
     else
         echo "$IVERIFY_SPACE/lock.$DEVICE_ID locked"
     fi
 done

 if [[ ! -z $IVERIFY_DEVICE_ID ]] ; then
     $NETCAT 127.0.0.1 5555
     echo "$NOW|$IVER|$HOSTNAME.$IBUILD_TARGET_PRODUCT.$IVERIFY_DEVICE_ID" | $NETCAT -l 5555
     echo $IVERIFY_SPACE/$IVER.build_info $IVERIFY_DEVICE_ID
     cat $IVERIFY_CONF >>$IVERIFY_SPACE/$IVER.build_info
     RUN_hostrunner $IVERIFY_SPACE/$IVER.build_info $IVERIFY_DEVICE_ID
 fi
}

RUN_hostrunner()
{
 export BUILD_INFO=$1
 export IVERIFY_hostrunner_serial=$2
 touch $IVERIFY_SPACE/lock.$IVERIFY_hostrunner_serial

 export IBUILD_GRTSRV_BRANCH=$(grep '^IBUILD_GRTSRV_BRANCH=' $BUILD_INFO | awk -F'IBUILD_GRTSRV_BRANCH=' {'print $2'})
 export IBUILD_TARGET_BUILD_VARIANT=$(grep '^IBUILD_TARGET_BUILD_VARIANT=' $BUILD_INFO | awk -F'IBUILD_TARGET_BUILD_VARIANT=' {'print $2'})
 export IBUILD_TARGET_PRODUCT=$(grep '^IBUILD_TARGET_PRODUCT=' $BUILD_INFO | awk -F'IBUILD_TARGET_PRODUCT=' {'print $2'})
 export DOWNLOAD_URL=$(grep '^DOWNLOAD_URL=' $BUILD_INFO | awk -F'DOWNLOAD_URL=' {'print $2'} | head -n1)
 export DOWNLOAD_PKG_NAME=$(grep '^DOWNLOAD_PKG_NAME=' $BUILD_INFO | awk -F'DOWNLOAD_PKG_NAME=' {'print $2'} | head -n1)
 export IVERIFY_hostrunner_variant=$IBUILD_TARGET_BUILD_VARIANT
 export IBUILD_GRTSRV_BRANCH_TOP=$(echo $IBUILD_GRTSRV_BRANCH | awk -F'/' {'print $1'})
 export IVERIFY_hostrunner_project=${IBUILD_TARGET_PRODUCT}$(echo $IBUILD_GRTSRV_BRANCH | awk -F"$IBUILD_GRTSRV_BRANCH_TOP" {'print $2'} | sed 's/\//_/g')
 export IVERIFY_FOUNDER_EMAIL=$(grep '^IVERIFY_FOUNDER_EMAIL=' $IVERIFY_CONF | awk -F'IVERIFY_FOUNDER_EMAIL=' {'print $2'})

 rm -f $IVERIFY_SPACE/$IVER.$IVERIFY_hostrunner_serial.sh >/dev/null 2>&1

 echo "#!/bin/bash -x
# `date`
# auto create script
export PATH=/usr/lib/jvm/java-7-openjdk-amd64/bin:~/iverify/bin:~/bin:$PATH:
export CLASSPATH=/usr/lib/jvm/java-7-openjdk-amd64/lib:.
export JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64

export KBITS_HOST=/tmp/$IVER.$DOWNLOAD_PKG_NAME
export FASTBOOT_SERIAL=$IVERIFY_hostrunner_serial
export PRE_COMMIT_DSN=$IVERIFY_hostrunner_serial
export IVERIFY_hostrunner_project=$IVERIFY_hostrunner_project
export IVERIFY_hostrunner_variant=$IVERIFY_hostrunner_variant

rm -f /tmp/$IVER.$DOWNLOAD_PKG_NAME
wget -q $DOWNLOAD_URL/$DOWNLOAD_PKG_NAME -O /tmp/$IVER.$DOWNLOAD_PKG_NAME

$IVERIFY_ROOT/script/pre_commit.sh

rm -f /tmp/$IVER.$DOWNLOAD_PKG_NAME
">$IVERIFY_SPACE/$IVER.$IVERIFY_hostrunner_serial.sh

 chmod +x $IVERIFY_SPACE/$IVER.$IVERIFY_hostrunner_serial.sh
 echo $IVERIFY_SPACE/$IVER.$IVERIFY_hostrunner_serial.sh
 cat $IVERIFY_SPACE/$IVER.$IVERIFY_hostrunner_serial.sh | mail -s "[iverify][assign][$ITASK_REV] $HOSTNAME.$IBUILD_TARGET_PRODUCT.$DEVICE_ONLINE" $IVERIFY_FOUNDER_EMAIL
 cp $IVERIFY_SPACE/$IVER.$IVERIFY_hostrunner_serial.sh /tmp/
 rm -f $IVERIFY_SPACE/$IVER.$IVERIFY_hostrunner_serial.log
 source $IVERIFY_SPACE/$IVER.$IVERIFY_hostrunner_serial.sh >>$IVERIFY_SPACE/$IVER.$IVERIFY_hostrunner_serial.log 2>&1
 cat $IVERIFY_SPACE/$IVER.$IVERIFY_hostrunner_serial.log | mail -s "[iverify][$ITASK_REV] $HOSTNAME.$IBUILD_TARGET_PRODUCT.$DEVICE_ONLINE" $IVERIFY_FOUNDER_EMAIL

 rm -f $IVERIFY_SPACE/lock.$IVERIFY_hostrunner_serial
}

export IVERIFY_SPACE=$TASK_SPACE/iverify
export ADB=$IVERIFY_ROOT/bin/adb
[[ `ps aux | grep nc | grep 4444` ]] && exit

export DEVICES_WC=$(cat $IVERIFY_SPACE/adb_devices.log | egrep -v 'daemon|attached|offline' | grep device$ | awk -F' ' {'print $1'} | wc -l)

for DEVICE_ID in `cat $IVERIFY_SPACE/adb_devices.log | egrep -v 'daemon|attached|offline' | grep device$ | awk -F' ' {'print $1'}`
do
    CHK_IVERIFY_LOCK $DEVICE_ID
done

while [ ! -f $IVERIFY_SPACE/busy_node ] ; 
do
    if [[ -f $TASK_SPACE/EXIT ]] ; then
        $NETCAT 127.0.0.1 4444
        $NETCAT 127.0.0.1 5555
        EXIT
    fi
    NODE_STANDBY
done

EXIT


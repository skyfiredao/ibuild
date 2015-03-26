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
export IP=$(/sbin/ifconfig | grep 'inet addr:' | egrep -v '127.0.0.1|:172.[0-9]' | awk -F':' {'print $2'} | awk -F' ' {'print $1'} | head -n1)
export MAC=$(/sbin/ifconfig | grep HWaddr | awk -F'HWaddr ' {'print $2'} | head -n1)
export HOSTNAME=$(hostname)
export CPU=$(cat /proc/cpuinfo | grep CPU | awk -F': ' {'print $2'} | sort -u)
export JOBS=$(cat /proc/cpuinfo | grep CPU | wc -l)
export TOWEEK=$(date +%yw%V)
export TODAY=$(date +%y%m%d)
export IVERIFY_ROOT=$HOME/iverify
	[[ ! -d $HOME/iverify ]] && export IVERIFY_ROOT=$(dirname $0 | awk -F'/iverify' {'print $1'})'/iverify'
if [[ ! -f $HOME/iverify/conf/iverify.conf ]] ; then
	echo -e "Please put iverify in your $HOME"
	exit 0
fi

echo ------------------------- `date`

mkdir -p $HOME/queue.iverify.local >/dev/null 2>&1

if [[ -f /usr/lib/jvm/java-7-openjdk-amd64/bin/java ]] ; then
	export PATH=/usr/lib/jvm/java-7-openjdk-amd64/bin:$PATH:
	export CLASSPATH=/usr/lib/jvm/java-7-openjdk-amd64/lib:.
	export JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64
else
	echo -e "Please setup JDK in your PATH"
	exit 0
fi
export ADB=$IVERIFY_ROOT/bin/adb

svn up -q $IVERIFY_ROOT >/dev/null 2>&1

export IVERIFY_SVN_SRV=$(grep '^IVERIFY_SVN_SRV=' $IVERIFY_ROOT/conf/iverify.conf | awk -F'IVERIFY_SVN_SRV=' {'print $2'})
export IVERIFY_SVN_OPTION=$(grep '^IVERIFY_SVN_OPTION=' $IVERIFY_ROOT/conf/iverify.conf | awk -F'IVERIFY_SVN_OPTION=' {'print $2'})
export IVERIFY_SVN_REV_SRV=$(svn info $IVERIFY_SVN_OPTION svn://$IVERIFY_SVN_SRV/iverify/iverify | grep 'Last Changed Rev: ' | awk -F': ' {'print $2'})
export IVERIFY_SVN_SRV_HOSTNAME=$(echo $IVERIFY_SVN_SRV | awk -F'.' {'print $1'})

if [[ -d $TASK_SPACE/iverify/inode.svn/.svn ]] ; then
    export SVN_REV_LOC=$(svn info $TASK_SPACE/iverify/inode.svn | grep 'Last Changed Rev: ' | awk -F': ' {'print $2'})
    if [[ $IVERIFY_SVN_REV_SRV != $SVN_REV_LOC ]] ; then
        svn cleanup $TASK_SPACE/iverify/inode.svn >/dev/null 2>&1
        svn up -q $IVERIFY_SVN_OPTION $TASK_SPACE/iverify/inode.svn >/dev/null 2>&1
    fi
else
    rm -fr $TASK_SPACE/iverify >/dev/null 2>&1
    mkdir -p $TASK_SPACE/iverify >/dev/null 2>&1
    rm -fr $TASK_SPACE/iverify/inode.svn >/dev/null 2>&1
    svn co -q $IVERIFY_SVN_OPTION svn://$IVERIFY_SVN_SRV/iverify/iverify/inode $TASK_SPACE/iverify/inode.svn
fi

INODE_REG()
{
 export HOSTNAME=$1
 export TARGET_PRODUCT=$2
 export DEVICE_ID=$3
 export DEVICE_STATUS=$4
 echo "# verify node info
IP=$IP
TARGET_PRODUCT=$TARGET_PRODUCT
HOSTNAME=$HOSTNAME
DEVICE_ID=$DEVICE_ID
DEVICE_STATUS=$DEVICE_STATUS
MAC=$MAC
CPU=$CPU
JOBS=$JOBS
USER=$USER" | sort -u >$TASK_SPACE/iverify/inode.svn/$HOSTNAME.$TARGET_PRODUCT.$DEVICE_ID

 if [[ ! -z $TARGET_PRODUCT ]] ; then
     svn add $TASK_SPACE/iverify/inode.svn/$HOSTNAME.$TARGET_PRODUCT.$DEVICE_ID >/dev/null 2>&1
 else
     rm -f $TASK_SPACE/iverify/inode.svn/$HOSTNAME.$TARGET_PRODUCT.$DEVICE_ID >/dev/null 2>&1
 fi
}

$ADB devices >$TASK_SPACE/iverify/adb_devices.log
for ADB_PID in `ps aux | grep adb | grep getprop | awk -F' ' {'print $2'}`
do
    kill -9 $ADB_PID
done

for DEVICE_ID in `ls $TASK_SPACE/iverify | egrep 'device.' | awk -F'device.' {'print $2'}`
do
    [[ ! `grep $DEVICE_ID $TASK_SPACE/iverify/adb_devices.log` ]] && rm -f $TASK_SPACE/iverify/device.$DEVICE_ID
done

for DEVICE_ID in `cat $TASK_SPACE/iverify/adb_devices.log | egrep -v 'daemon|attached|offline' | grep device$ | awk -F' ' {'print $1'}`
do
    $ADB -s $DEVICE_ID shell getprop >$TASK_SPACE/iverify/device.$DEVICE_ID
    export TARGET_PRODUCT=$(grep ro.build $TASK_SPACE/iverify/device.$DEVICE_ID | grep fingerprint | awk -F'/' {'print $2'})
    [[ ! -z $TARGET_PRODUCT ]] && INODE_REG $HOSTNAME $TARGET_PRODUCT $DEVICE_ID online
done

for DEVICE_OFFLINE in `cat $TASK_SPACE/iverify/adb_devices.log | egrep -v 'daemon|attached' | grep offline$ | awk -F' ' {'print $1'}`
do
    INODE_REG $HOSTNAME $TARGET_PRODUCT $DEVICE_ID offline
    rm -f $TASK_SPACE/iverify/lock.$DEVICE_OFFLINE >/dev/null 2>&1
done

for DEVICE_LOST in `ls $TASK_SPACE/iverify | grep lock | awk -F'^lock.' {'print $2'}`
do
    if [[ ! `ls $TASK_SPACE/iverify/inode.svn | grep $HOSTNAME | grep $DEVICE_LOST` ]] ; then
    rm -f $TASK_SPACE/iverify/lock.$DEVICE_LOST
    fi
done

for CHK_HOST_DEVICE in `ls $TASK_SPACE/iverify/inode.svn | grep $HOSTNAME`
do
    export CHK_DEVICE_ID=$(echo $CHK_HOST_DEVICE | awk -F'.' {'print $3'})
    if [[ ! `grep $CHK_DEVICE_ID $TASK_SPACE/iverify/adb_devices.log` ]] ; then
        svn rm $TASK_SPACE/iverify/inode.svn/$CHK_HOST_DEVICE
    fi
done

if [[ `svn st $TASK_SPACE/iverify/inode.svn | grep $HOSTNAME` ]] ; then
    svn ci $IVERIFY_SVN_OPTION -m "auto: update $HOSTNAME $IP" $TASK_SPACE/iverify/inode.svn
    if [[ $? != 0 ]] ; then
        rm -fr $TASK_SPACE/iverify/inode.svn
        echo -e "Waiting for next cycle because conflict"
        exit 1
    fi
fi

if [[ ! `crontab -l | grep iverify_node_reg` && -f $IVERIFY_ROOT/bin/iverify_node_reg ]] ; then
    echo "# m h  dom mon dow   command
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
*/5 * * * * $IVERIFY_ROOT/bin/iverify_node_reg >/tmp/iverify_node_reg.log 2>&1
" >/tmp/$USER.crontab
    crontab -l | egrep -v '#|iverify_node_reg' >>/tmp/$USER.crontab
    crontab /tmp/$USER.crontab
fi

if [[ `ps aux | grep -v grep | grep nc | grep 4444` ]] ; then
    $IVERIFY_ROOT/bin/iverify_node_run >/tmp/iverify_node_run.log 2>&1 &
else
    $IVERIFY_ROOT/bin/iverify_node_daemon >/tmp/iverify_node_daemon.log 2>&1 &
fi

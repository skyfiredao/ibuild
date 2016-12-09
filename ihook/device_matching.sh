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
# 150312 Create by Ding Wei
source /etc/bash.bashrc
export LC_CTYPE=C
export LC_ALL=C
export TASK_SPACE=/dev/shm
export LOCK_SPACE=/dev/shm/lock
export SEED=$RANDOM
[[ `echo $* | grep debug` ]] && export DEBUG=echo
[[ ! -d $HOME/ibuild ]] && export HOME=/local

export IBUILD_ROOT=$HOME/ibuild
        [[ -z $IBUILD_ROOT ]] && export IBUILD_ROOT=$(dirname $0 | awk -F'/ibuild' {'print $1'})'/ibuild'
if [[ ! -f $HOME/ibuild/conf/ibuild.conf ]] ; then
	echo -e "Please put ibuild in your $HOME"
	exit 0
fi

source $IBUILD_ROOT/imake/function
EXPORT_IBUILD_CONF

EXIT()
{
 rm -f $LOCK_SPACE/queue_icase.lock
 rm -fr $IVERIFY_SPACE
 exit
}

MATCHING()
{
 export PRIORITY_ICASE_REV=$1
 export IVERIFY_PRIORITY=$(echo $PRIORITY_ICASE_REV | awk -F'.' {'print $1'})
 export ICASE_REV=$(echo $PRIORITY_ICASE_REV | awk -F'.' {'print $2'})
 export IBUILD_TARGET_PRODUCT=$(echo $PRIORITY_ICASE_REV | awk -F'.' {'print $3'})

 if [[ ! -d $IVERIFY_SPACE/inode.lock/.svn ]] ; then
     svn co -q $IBUILD_SVN_OPTION svn://$IBUILD_SVN_SRV/iverify/iverify/inode $IVERIFY_SPACE/inode.lock
 fi

 export ICASE_URL=$(svn log -v -r $ICASE_REV $IBUILD_SVN_OPTION svn://$IBUILD_SVN_SRV/icase/icase | egrep 'A |M ' | awk -F' ' {'print $2'} | head -n1)
 if [[ ! -d $IVERIFY_SPACE/icase.svn/.svn ]] ; then
     svn co -q $IBUILD_SVN_OPTION svn://$IBUILD_SVN_SRV/icase/icase/$TOYEAR/$TOWEEK $IVERIFY_SPACE/icase.svn
 fi
 export BUILD_INFO_NAME=$(basename $ICASE_URL | head -n1)
 export BUILD_INFO=$IVERIFY_SPACE/icase.svn/$BUILD_INFO_NAME

 for HOST_DEVICE in `ls $IVERIFY_SPACE/inode.lock | grep $IBUILD_TARGET_PRODUCT`
 do
     export HOSTNAME_DEVICE=$(echo $HOST_DEVICE | awk -F".$IBUILD_TARGET_PRODUCT" {'print $1'})
     export HOST_IP=$(grep '^IP=' $IVERIFY_SPACE/inode.lock/$HOST_DEVICE | awk -F'IP=' {'print $2'})
     export DEVICE_STATUS=$(grep '^DEVICE_STATUS=' $IVERIFY_SPACE/inode.lock/$HOST_DEVICE | awk -F'DEVICE_STATUS=' {'print $2'})
     export DEVICE_ID=$(grep '^DEVICE_ID=' $IVERIFY_SPACE/inode.lock/$HOST_DEVICE | awk -F'DEVICE_ID=' {'print $2'})
     export TARGET_PRODUCT=$(grep '^TARGET_PRODUCT=' $IVERIFY_SPACE/inode.lock/$HOST_DEVICE | awk -F'TARGET_PRODUCT=' {'print $2'})

     cat $BUILD_INFO | $NETCAT $HOST_IP 4444
     sleep 1
     $NETCAT $HOST_IP 5555 >$IVERIFY_SPACE/$HOST_DEVICE.assign
#     export ASSIGN_HOST_DEVICE=$(cat $IVERIFY_SPACE/$HOST_DEVICE.assign | awk -F'|' {'print $3'})
#     if [[ $ASSIGN_HOST_DEVICE = $HOST_DEVICE ]] ; then
     if [[ `grep $HOSTNAME_DEVICE $IVERIFY_SPACE/$HOST_DEVICE.assign` ]] ; then
#         svn rm -q $IBUILD_SVN_OPTION -m "auto: remove $PRIORITY_ICASE_REV" svn://$IBUILD_SVN_SRV/itask/queue/icase/$PRIORITY_ICASE_REV
         rm -f /local/queue/icase/$PRIORITY_ICASE_REV
#         svn up -q $IBUILD_SVN_OPTION $QUEUE_SPACE
         if [[ -f $QUEUE_SPACE/$PRIORITY_ICASE_REV ]] ; then
#             svn rm --force $QUEUE_SPACE/$PRIORITY_ICASE_REV
             rm -f /local/queue/icase/$PRIORITY_ICASE_REV
             rm -f $IVERIFY_SPACE/inode.lock/$HOST_DEVICE
         fi
         EXIT
     fi
 done

# export FREE_HOST_DEVICE=$(ls $IVERIFY_SPACE/inode.lock | grep $IBUILD_TARGET_PRODUCT | wc -l)
# if [[ $FREE_HOST_DEVICE = 0 ]] ; then
#     svn up -q $IBUILD_SVN_OPTION $IVERIFY_SPACE/inode.lock
# fi 
}

export QUEUE_SPACE=$1
export IVERIFY_SPACE=$TASK_SPACE/tmp/iverify.$SEED

[[ ! -d $IVERIFY_SPACE ]] && mkdir -p $IVERIFY_SPACE >/dev/null 2>&1

for PRIORITY_ICASE_REV in `ls $QUEUE_SPACE`
do
    [[ -f /tmp/EXIT ]] && EXIT
    echo $PRIORITY_ICASE_REV >$LOCK_SPACE/queue_icase.lock
    chmod 777 $LOCK_SPACE/queue_icase.lock

    MATCHING $PRIORITY_ICASE_REV
    sleep 10
done

EXIT



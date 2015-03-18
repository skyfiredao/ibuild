#!/bin/bash -x
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
[[ `echo $* | grep debug` ]] && export DEBUG=echo
export HOME=/root

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
 rm -f $TASK_SPACE/queue_icase.lock
 exit
}

MATCHING()
{
 export PRIORITY_ICASE_REV=$1
 export IVERIFY_PRIORITY=$(echo $PRIORITY_ICASE_REV | awk -F'.' {'print $1'})
 export ICASE_REV=$(echo $PRIORITY_ICASE_REV | awk -F'.' {'print $2'})
 export IBUILD_TARGET_PRODUCT=$(echo $PRIORITY_ICASE_REV | awk -F'.' {'print $3'})

 if [[ ! -d $IVERFY_SPACE/inode.lock ]] ; then
	svn co -q $IBUILD_SVN_OPTION svn://$IBUILD_SVN_SRV/iverify/iverify/inode $IVERFY_SPACE/inode.lock
 fi

 for HOST_DEVICE in `ls $IVERFY_SPACE/inode.lock | grep $IBUILD_TARGET_PRODUCT`
 do
	export HOST_IP=$(grep '^IP=' $IVERFY_SPACE/inode.lock/$HOST_DEVICE | awk -F'IP=' {'print $2'})
	export DEVICE_STATUS=$(grep '^DEVICE_STATUS=' $IVERFY_SPACE/inode.lock/$HOST_DEVICE | awk -F'DEVICE_STATUS=' {'print $2'})
	export DEVICE_ID=$(grep '^DEVICE_ID=' $IVERFY_SPACE/inode.lock/$HOST_DEVICE | awk -F'DEVICE_ID=' {'print $2'})
	export TARGET_PRODUCT=$(grep '^TARGET_PRODUCT=' $IVERFY_SPACE/inode.lock/$HOST_DEVICE | awk -F'TARGET_PRODUCT=' {'print $2'})

	cat $BUILD_INFO | $NETCAT $HOST_IP 4444
	sleep 1
	$NETCAT $HOST_IP 5555 >$IVERFY_SPACE/$HOST_DEVICE.assign
	export ASSIGN_HOST_DEVICE=$(cat $IVERFY_SPACE/$HOST_DEVICE.assign | awk -F'|' {'print $3'})
	if [[ $ASSIGN_HOST_DEVICE = $HOST_DEVICE ]] ; then
		rm -f $QUEUE_SPACE/$PRIORITY_ICASE_REV
		rm -f $IVERFY_SPACE/inode.lock/$HOST_DEVICE
		EXIT
	fi
 done

 export FREE_HOST_DEVICE=$(ls $IVERFY_SPACE/inode.lock | grep $IBUILD_TARGET_PRODUCT | wc -l)
 if [[ -z $FREE_HOST_DEVICE ]] ; then
	svn up -q $IBUILD_SVN_OPTION $IVERFY_SPACE/inode.lock
 fi 
}

export QUEUE_SPACE=$1
export IVERFY_SPACE=$2
export BUILD_INFO=$3

for PRIORITY_ICASE_REV in `ls $QUEUE_SPACE`
do
	[[ -f /tmp/EXIT ]] && EXIT
	echo $PRIORITY_ICASE_REV >$TASK_SPACE/queue_icase.lock
	chmod 777 $TASK_SPACE/queue_icase.lock

	MATCHING $PRIORITY_ICASE_REV
done

EXIT



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
export IVERIFY_hostrunner_PATH=$HOME/iverify/hostrunner
if [[ ! -f $HOME/iverify/conf/iverify.conf ]] ; then
	echo -e "Please put iverify in your $HOME"
	exit 0
fi

date

CHK_IVERIFY_LOCK()
{
 export DEVICE_ID=$1
 export DEVICES_LOCK=$(ls $IVERIFY_SPACE | grep lock | wc -l)

 if [[ $DEVICES_WC = $DEVICES_LOCK ]] ; then
	touch $IVERIFY_SPACE/busy_node
 else
	rm -f $IVERIFY_SPACE/busy_node
 fi

 if [[ -f $IVERIFY_SPACE/lock.$DEVICE_ID || -f $IVERIFY_SPACE/busy_node ]] ; then
	echo "$IVERIFY_SPACE/lock.$DEVICE_ID locked"
	exit 0
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
 export ITASK_REV=$(grep '^ITASK_REV=' $IVERIFY_SPACE/build_info.$SEED | awk -F'ITASK_REV=' {'print $2'})
 [[ -z $ITASK_REV ]] && export ITASK_REV=$SEED

 mv $IVERIFY_SPACE/build_info.$SEED $IVERIFY_SPACE/build_info.$ITASK_REV >/dev/null 2>&1 
 export IVERIFY=$(grep '^IVERIFY=' $IVERIFY_SPACE/build_info.$ITASK_REV | awk -F'IVERIFY=' {'print $2'})
 export RESULT=$(grep '^RESULT=' $IVERIFY_SPACE/build_info.$ITASK_REV | awk -F'RESULT=' {'print $2'})
 export MAKE_STATUS=$(grep '^MAKE_STATUS=' $IVERIFY_SPACE/build_info.$ITASK_REV | awk -F'MAKE_STATUS=' {'print $2'})
 export DOWNLOAD_PKG_NAME=$(grep '^DOWNLOAD_PKG_NAME=' $IVERIFY_SPACE/build_info.$ITASK_REV | awk -F'DOWNLOAD_PKG_NAME=' {'print $2'} | head -n1)

 if [[ $RESULT != PASSED || ! -z $MAKE_STATUS || -z $DOWNLOAD_PKG_NAME || -z $IVERIFY ]] ; then
	exit
 fi

 export TARGET_PRODUCT=$(grep '^TARGET_PRODUCT=' $IVERIFY_SPACE/build_info.$ITASK_REV | awk -F'TARGET_PRODUCT=' {'print $2'})
 export IVERIFY_DEVICE_ID=''

 for DEVICE_ONLINE in `cat $IVERIFY_SPACE/adb_devices.log | egrep -v 'daemon|attached|offline' | grep device$ | awk -F' ' {'print $1'}`
 do
	if [[ `ls $IVERIFY_SPACE/inode.svn | grep $HOSTNAME | grep $TARGET_PRODUCT | $DEVICE_ONLINE` ]] ; then
		export IVERIFY_DEVICE_ID=$DEVICE_ONLINE
	fi
 done

 if [[ ! -z $IVERIFY_DEVICE_ID ]] ; then
	$NETCAT 127.0.0.1 4444
	echo "$NOW|$ITASK_REV|$HOSTNAME.$TARGET_PRODUCT.$IVERIFY_DEVICE_ID" | $NETCAT -l 5555
	RUN_hostagent $IVERIFY_SPACE/build_info.$SEED $IVERIFY_DEVICE_ID
 fi
}

RUN_hostagent()
{
 export BUILD_INFO=$1
 export IVERIFY_hostrunner_serial=$2
 touch $IVERIFY_SPACE/lock.$IVERIFY_hostrunner_serial

 export IBUILD_GRTSRV_BRANCH=$(grep '^IBUILD_GRTSRV_BRANCH=' $BUILD_INFO | awk -F'IBUILD_GRTSRV_BRANCH=' {'print $2'})
 export IBUILD_TARGET_BUILD_VARIANT=$(grep '^IBUILD_TARGET_BUILD_VARIANT=' $BUILD_INFO | awk -F'IBUILD_TARGET_BUILD_VARIANT=' {'print $2'})
 export IBUILD_TARGET_PRODUCT=$(grep '^IBUILD_TARGET_PRODUCT=' $BUILD_INFO | awk -F'IBUILD_TARGET_PRODUCT=' {'print $2'})
 export DOWNLOAD_URL=$(grep '^DOWNLOAD_URL=' $BUILD_INFO | awk -F'DOWNLOAD_URL=' {'print $2'} | head -n1)
 export DOWNLOAD_PKG_NAME=$(grep '^DOWNLOAD_PKG_NAME=' $BUILD_INFO | awk -F'DOWNLOAD_PKG_NAME=' {'print $2'} | head -n1)

 cd $IVERIFY_SPACE
 if [[ ! -f $IVERIFY_SPACE/$ITASK_REV.$DOWNLOAD_PKG_NAME ]] ; then
	wget $DOWNLOAD_URL/$DOWNLOAD_PKG_NAME -O $ITASK_REV.$DOWNLOAD_PKG_NAME
 fi

 export KBITS_HOST=$IVERIFY_SPACE/$ITASK_REV.$DOWNLOAD_PKG_NAME
 export FASTBOOT_SERIAL=$IVERIFY_hostrunner_serial
 export IVERIFY_hostrunner_type=nightly
 export IVERIFY_hostrunner_variant=${IBUILD_TARGET_BUILD_VARIANT}_$(basename $IBUILD_GRTSRV_BRANCH)
 export IVERIFY_hostrunner_project=$IBUILD_TARGET_PRODUCT
 export IVERIFY_hostrunner_build_number=$(grep '^IVERIFY_hostrunner_build_number=' $IVERIFY_CONF | awk -F'IVERIFY_hostrunner_build_number=' {'print $2'})
 export IVERIFY_hostrunner_testsuite=$(grep '^IVERIFY_hostrunner_testsuite=' $IVERIFY_CONF | awk -F'IVERIFY_hostrunner_testsuite=' {'print $2'})
 export IVERIFY_hostrunner_url=$(grep '^IVERIFY_hostrunner_url=' $IVERIFY_CONF | awk -F'IVERIFY_hostrunner_url=' {'print $2'})
 export IVERIFY_hostrunner_device_config=$(grep '^IVERIFY_hostrunner_device_config=' $IVERIFY_CONF | awk -F'IVERIFY_hostrunner_url=' {'print $2'})

 cd $IVERIFY_hostrunner_PATH
 $IVERIFY_hostrunner_PATH/hostrunner \
--type $IVERIFY_hostrunner_type \
--variant $IVERIFY_hostrunner_variant \
--project $IVERIFY_hostrunner_project \
--build-number $IVERIFY_hostrunner_build_number \
--testsuite $IVERIFY_hostrunner_testsuite \
--url $IVERIFY_hostrunner_url \
--serial $IVERIFY_hostrunner_serial \
--device-config $IVERIFY_hostrunner_device_config

 rm -f $IVERIFY_SPACE/$ITASK_REV.$DOWNLOAD_PKG_NAME
 rm -f $IVERIFY_SPACE/lock.$IVERIFY_hostrunner_serial
}

export IVERIFY_SPACE=$TASK_SPACE/iverify
[[ -f $IVERIFY_SPACE/iverify.lock ]] && exit

touch $IVERIFY_SPACE/iverify.lock
export DEVICES_WC=$(cat $IVERIFY_SPACE/db_devices.log | egrep -v 'daemon|attached|offline' | grep device$ | awk -F' ' {'print $1'} | wc -l)

for DEVICE_ID in `cat $IVERIFY_SPACE/db_devices.log | egrep -v 'daemon|attached|offline' | grep device$ | awk -F' ' {'print $1'}`
do
	
	CHK_IVERIFY_LOCK $DEVICE_ID
done

while [ ! -f $IVERIFY_SPACE/busy_node ] ; 
do
	if [[ -f $TASK_SPACE/exit.lock ]] ; then
		$NETCAT 127.0.0.1 5555
		pkill -9 nc
		exit 0
	fi
	NODE_STANDBY
done

rm -f $IVERIFY_SPACE/iverify.lock


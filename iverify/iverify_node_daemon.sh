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

EXIT()
{
 rm -f $IVERIFY_SPACE/iverify.lock 
 rm -f $IVERIFY_SPACE/build_info.[1-9]*
 exit
}

CHK_IVERIFY_LOCK()
{
 export DEVICE_ID=$1
 export DEVICES_LOCK=$(ls $IVERIFY_SPACE | grep -v lock$ | grep ^lock | wc -l)

 if [[ $DEVICES_WC = $DEVICES_LOCK ]] ; then
	touch $IVERIFY_SPACE/busy_node
 else
	rm -f $IVERIFY_SPACE/busy_node
 fi

 if [[ -f $IVERIFY_SPACE/lock.$DEVICE_ID || -f $IVERIFY_SPACE/busy_node ]] ; then
	echo "$IVERIFY_SPACE/lock.$DEVICE_ID locked"
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

 mv $IVERIFY_SPACE/build_info.$SEED $IVERIFY_SPACE/build_info.$IVER >/dev/null 2>&1 
 export IVERIFY=$(grep '^IVERIFY=' $IVERIFY_SPACE/build_info.$IVER | awk -F'IVERIFY=' {'print $2'})
 export RESULT=$(grep '^RESULT=' $IVERIFY_SPACE/build_info.$IVER | awk -F'RESULT=' {'print $2'})
 export MAKE_STATUS=$(grep '^MAKE_STATUS=' $IVERIFY_SPACE/build_info.$IVER | awk -F'MAKE_STATUS=' {'print $2'})
 export DOWNLOAD_PKG_NAME=$(grep '^DOWNLOAD_PKG_NAME=' $IVERIFY_SPACE/build_info.$IVER | awk -F'DOWNLOAD_PKG_NAME=' {'print $2'} | head -n1)

 if [[ $RESULT != PASSED || ! -z $MAKE_STATUS || -z $DOWNLOAD_PKG_NAME || -z $IVERIFY ]] ; then
	egrep 'RESULT=|MAKE_STATUS=|IVERIFY=|DOWNLOAD_PKG_NAME=' $IVERIFY_SPACE/build_info.$IVER
	EXIT
 fi

 export IBUILD_TARGET_PRODUCT=$(grep '^IBUILD_TARGET_PRODUCT=' $IVERIFY_SPACE/build_info.$IVER | awk -F'IBUILD_TARGET_PRODUCT=' {'print $2'})
 export IVERIFY_DEVICE_ID=''

 for DEVICE_ONLINE in `cat $IVERIFY_SPACE/adb_devices.log | egrep -v 'daemon|attached|offline' | grep device$ | awk -F' ' {'print $1'}`
 do
	if [[ -f $IVERIFY_SPACE/inode.svn/$HOSTNAME.$IBUILD_TARGET_PRODUCT.$DEVICE_ONLINE && ! -f $IVERIFY_SPACE/lock.$DEVICE_ONLINE ]] ; then
		export IVERIFY_DEVICE_ID=$DEVICE_ONLINE
		echo $HOSTNAME.$IBUILD_TARGET_PRODUCT.$DEVICE_ONLINE
	fi
 done

 if [[ ! -z $IVERIFY_DEVICE_ID ]] ; then
#	$NETCAT 127.0.0.1 4444
	$NETCAT 127.0.0.1 5555
	echo "$NOW|$IVER|$HOSTNAME.$IBUILD_TARGET_PRODUCT.$IVERIFY_DEVICE_ID" | $NETCAT -l 5555
	echo $IVERIFY_SPACE/build_info.$IVER $IVERIFY_DEVICE_ID
	cat $IVERIFY_CONF >>$IVERIFY_SPACE/build_info.$IVER
	RUN_hostrunner $IVERIFY_SPACE/build_info.$IVER $IVERIFY_DEVICE_ID
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
 export IVERIFY_hostrunner_type=nightly
 export IVERIFY_hostrunner_variant=${IBUILD_TARGET_BUILD_VARIANT}_$(basename $IBUILD_GRTSRV_BRANCH)
 export IVERIFY_hostrunner_project=$IBUILD_TARGET_PRODUCT
 export IVERIFY_hostrunner_build_number=$(grep '^IVERIFY_hostrunner_build_number=' $IVERIFY_CONF | awk -F'IVERIFY_hostrunner_build_number=' {'print $2'})
 export IVERIFY_hostrunner_testsuite=$(grep '^IVERIFY_hostrunner_testsuite=' $IVERIFY_CONF | awk -F'IVERIFY_hostrunner_testsuite=' {'print $2'})
 export IVERIFY_hostrunner_url=$(grep '^IVERIFY_hostrunner_url=' $IVERIFY_CONF | awk -F'IVERIFY_hostrunner_url=' {'print $2'})
 export IVERIFY_hostrunner_device_config=$(grep '^IVERIFY_hostrunner_device_config=' $IVERIFY_CONF | awk -F'IVERIFY_hostrunner_device_config=' {'print $2'})

 cd $IVERIFY_hostrunner_PATH
 rm -fr $IVERIFY_hostrunner_PATH/workdir/$IVERIFY_hostrunner_serial-* >/dev/null 2>&1
 rm -f $IVERIFY_SPACE/$IVER.$IVERIFY_hostrunner_serial.sh >/dev/null 2>&1
 mkdir -p $IVERIFY_hostrunner_PATH/workdir >/dev/null 2>&1
 export hostrunner_SPACE=$IVERIFY_hostrunner_PATH/workdir
 export KBITS_HOST=$hostrunner_SPACE/$IVER.$DOWNLOAD_PKG_NAME
 export FASTBOOT_SERIAL=$IVERIFY_hostrunner_serial

 echo "#!/bin/bash
# auto create script
export PATH=/usr/lib/jvm/java-7-openjdk-amd64/bin:$PATH:
export CLASSPATH=/usr/lib/jvm/java-7-openjdk-amd64/lib:.
export JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64

cd $IVERIFY_hostrunner_PATH

export KBITS_HOST=$hostrunner_SPACE/$IVER.$DOWNLOAD_PKG_NAME
export FASTBOOT_SERIAL=$IVERIFY_hostrunner_serial

rm -f $hostrunner_SPACE/$IVER.$DOWNLOAD_PKG_NAME
wget -q $DOWNLOAD_URL/$DOWNLOAD_PKG_NAME -O $hostrunner_SPACE/$IVER.$DOWNLOAD_PKG_NAME

$IVERIFY_hostrunner_PATH/hostrunner \
--type $IVERIFY_hostrunner_type \
--variant $IVERIFY_hostrunner_variant \
--project $IVERIFY_hostrunner_project \
--build-number $IVERIFY_hostrunner_build_number \
--testsuite $IVERIFY_hostrunner_testsuite \
--url $IVERIFY_hostrunner_url \
--serial $IVERIFY_hostrunner_serial \
--device-config $IVERIFY_hostrunner_device_config

rm -f $hostrunner_SPACE/$IVER.$DOWNLOAD_PKG_NAME
">$IVERIFY_SPACE/$IVER.$IVERIFY_hostrunner_serial.sh

 chmod +x $IVERIFY_SPACE/$IVER.$IVERIFY_hostrunner_serial.sh
 cat $IVERIFY_SPACE/$IVER.$IVERIFY_hostrunner_serial.sh
 source $IVERIFY_SPACE/$IVER.$IVERIFY_hostrunner_serial.sh >>$IVERIFY_SPACE/$IVER.$IVERIFY_hostrunner_serial.log 2>&1

 cd $hostrunner_SPACE
 find | egrep -v 'file.list$|.svn' >$IVER.file.list

 for LOG_FILE in `grep $IVERIFY_hostrunner_serial $IVER.file.list | grep testrun | grep log.txt$`
 do
	export LOG_FILE_PATH=$(dirname $LOG_FILE)
	export LOG_FILE_sequence=$(basename $LOG_FILE_PATH)
	mv $LOG_FILE $IVERIFY_SPACE/$IVER.$LOG_FILE_sequence.log.txt
 done

 rm -f $IVERIFY_SPACE/lock.$IVERIFY_hostrunner_serial
}

export IVERIFY_SPACE=$TASK_SPACE/iverify
[[ -f $IVERIFY_SPACE/iverify.lock ]] && exit

touch $IVERIFY_SPACE/iverify.lock
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

rm -f $IVERIFY_SPACE/iverify.lock


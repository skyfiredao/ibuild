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
if [[ ! -f $HOME/iverify/conf/iverify.conf ]] ; then
	echo -e "Please put iverify in your $HOME"
	exit 0
fi

date

CHK_IVERIFY_LOCK()
{
 export DEVICE_ID=$1
 export DEVICES_LOCK=$(ls $TASK_SPACE/iverify | grep lock | wc -l)

 if [[ $DEVICES_WC = $DEVICES_LOCK ]] ; then
	touch $TASK_SPACE/iverify/busy_node
 else
	rm -f $TASK_SPACE/iverify/busy_node
 fi

 if [[ -f $TASK_SPACE/iverify/lock.$DEVICE_ID || -f $TASK_SPACE/iverify/busy_node ]] ; then
	echo "$TASK_SPACE/iverify/lock.$DEVICE_ID locked"
	exit 0
 fi
}

NODE_STANDBY()
{
 export NETCAT=$(which nc)
	[[ -z $NETCAT ]] && export NETCAT="$IVERIFY_ROOT/bin/netcat.openbsd-u14.04"
 export HOST_MD5=$(echo $HOSTNAME | md5sum | awk -F' ' {'print $1'})

 CHK_ITASK_LOCK
 $NETCAT -l 4444 >$TASK_SPACE/itask.jobs
 export JOBS_REV=`cat $TASK_SPACE/itask.jobs`
 CHK_ITASK_LOCK
 
 if [[ -z $JOBS_REV ]] ; then
	rm -f $TASK_SPACE/itask.lock
	exit
 fi
 export JOBS_MD5=`echo $JOBS_REV | md5sum | awk -F' ' {'print $1'}`
 export NOW=`date +%y%m%d%H%M%S`
 
 $NETCAT 127.0.0.1 4444
 echo "$NOW|$JOBS_MD5|$HOST_MD5" | $NETCAT -l 4321
 
 if [[ ! -z $JOBS_REV ]] ; then
	sleep 3
	svn up -q $IVERIFY_SVN_OPTION $TASK_SPACE/itask/svn/jobs.txt
	svn up -q $IVERIFY_ROOT
	if [[ `cat $TASK_SPACE/itask/svn/jobs.txt | grep ^$JOBS_REV | grep $HOSTNAME` ]] ; then
		$IVERIFY_ROOT/imake/build.sh $JOBS_REV >/tmp/build-$JOBS_REV.log 2>&1
		echo "build: "`date` >>$TASK_SPACE/count
	fi
 fi
 rm -f $TASK_SPACE/itask.jobs
}

export DEVICES_WC=$($ADB devices | egrep -v 'daemon|attached|offline' | grep device$ | awk -F' ' {'print $1'} | wc -l)

for DEVICE_ID in `$ADB devices | egrep -v 'daemon|attached|offline' | grep device$ | awk -F' ' {'print $1'}`
do
	
	CHK_IVERIFY_LOCK $DEVICE_ID
done

while [ ! -f $TASK_SPACE/iverify/busy_node ] ; 
do
	if [[ -f $TASK_SPACE/exit.lock ]] ; then
		$NETCAT 127.0.0.1 5555
		pkill -9 nc
		exit 0
	fi
	NODE_STANDBY
done

rm -f $TASK_SPACE/itask.lock


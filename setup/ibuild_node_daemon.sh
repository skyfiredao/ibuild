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
# 150119 Create by Ding Wei
source /etc/bash.bashrc
export LC_CTYPE=C
export LC_ALL=C
export USER=`whoami`
export TASK_SPACE=/run/shm
export HOSTNAME=`hostname`
export DOMAIN_NAME=`cat /etc/resolv.conf | grep search | awk -F' ' {'print $2'}`
export JOBS=`cat /proc/cpuinfo | grep CPU | wc -l`
export TOWEEK=`date +%yw%V`
export ITASK_PATH=$1

export IBUILD_ROOT=$HOME/ibuild
	[[ ! -d $HOME/ibuild ]] && export IBUILD_ROOT=`dirname $0 | awk -F'/ibuild' {'print $1'}`'/ibuild'
if [[ ! -f $HOME/ibuild/conf/ibuild.conf ]] ; then
	echo -e "Please put ibuild in your $HOME"
	exit 0
fi

date

CHK_ITASK_LOCK()
{
 if [[ -f $TASK_SPACE/itask.lock ]] ; then
	echo -e "$TASK_SPACE/itask.lock"
	exit 0
 fi
}

NODE_STANDBY()
{
 export NETCAT=`which nc`
	[[ -z $NETCAT ]] && export NETCAT="$IBUILD_ROOT/bin/netcat.openbsd-u14.04"
 export HOST_MD5=`echo $HOSTNAME | md5sum | awk -F' ' {'print $1'}`

 $NETCAT -l 1234 >$TASK_SPACE/itask.jobs
 export JOBS_REV=`cat $TASK_SPACE/itask.jobs`
 CHK_ITASK_LOCK
 
 echo $ITASK_PATH >$TASK_SPACE/itask.lock
 if [[ -z $JOBS_REV ]] ; then
	rm -f $TASK_SPACE/itask.lock
	exit
 fi
 export JOBS_MD5=`echo $JOBS_REV | md5sum | awk -F' ' {'print $1'}`
 export NOW=`date +%y%m%d%H%M%S`
 
 $NETCAT 127.0.0.1 4321
 echo "$NOW|$JOBS_MD5|$HOST_MD5" | $NETCAT -l 4321
 
 if [[ ! -z $JOBS_REV ]] ; then
	sleep 3
	svn up -q $IBUILD_SVN_OPTION $TASK_SPACE/itask-$TOWEEK/jobs.txt
	svn up -q $IBUILD_ROOT
	if [[ `cat $TASK_SPACE/itask-$TOWEEK/jobs.txt | grep ^$JOBS_REV | grep $HOSTNAME` ]] ; then
		$IBUILD_ROOT/imake/build.sh $JOBS_REV >/tmp/build-$JOBS_REV.log 2>&1
		echo "build: "`date` >>$TASK_SPACE/count
	fi
 fi
 rm -f $TASK_SPACE/itask.jobs
}

CHK_ITASK_LOCK

while [ ! -f $TASK_SPACE/itask.lock ] ; 
do
	if [[ -f $TASK_SPACE/exit.lock ]] ; then
		$NETCAT 127.0.0.1 1234
		pkill -9 nc
		exit 0
	fi
	NODE_STANDBY
done

rm -f $TASK_SPACE/itask.lock


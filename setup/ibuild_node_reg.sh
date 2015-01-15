#!/bin/bash
# Copyright (C) <2014>  <Ding Wei>
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
# 150114 Create by Ding Wei

export LC_CTYPE=C
export LC_ALL=C
export USER=`whoami`
export TASK_SPACE=/run/shm
export IP=`/sbin/ifconfig eth0 | grep 'inet addr:' | awk -F':' {'print $2'} | awk -F' ' {'print $1'}`
export HOSTNAME=`hostname`
export DOMAIN_NAME=`cat /etc/resolv.conf | grep search | awk -F' ' {'print $2'}`
export FS=`mount | grep btrfs`
	[[ -z $FS ]] && export FS=ext4
export MEMORY=`free -gh --si | grep Mem | awk -F' ' {'print $2'}`
export CPU=`cat /proc/cpuinfo | grep CPU | awk -F': ' {'print $2'} |sort -u`
export JOBS=`cat /proc/cpuinfo | grep CPU | wc -l`

export NOW=`date +%y%m%d%H%M%S`
export TOWEEK=`date +%yw%V`

if [[ ! -d $HOME/ibuild/.svn ]] ; then
	export IBUILD_PATH=`dirname $0 | awk -F'/ibuild' {'print $1'}`'/ibuild'
	[[ `echo $0 | grep '^./'` ]] && export IBUILD_PATH=`pwd`/`echo $0 | sed 's/^.\///g'`
else
	export IBUILD_PATH=$HOME/ibuild
fi 

export SVN_SRV=`grep '^IBUILD_SVN_SRV=' $IBUILD_PATH/conf/ibuild.conf | awk -F'IBUILD_SVN_SRV=' {'print $2'}`
export SVN_OPTION=`grep '^IBUILD_SVN_OPTION=' $IBUILD_PATH/conf/ibuild.conf | awk -F'IBUILD_SVN_OPTION=' {'print $2'}`

if [[ -d $TASK_SPACE/itask-$TOWEEK ]] ; then
	export REV_SRV=`svn info $SVN_OPTION svn://$SVN_SRV/itask/itask | grep 'Last Changed Rev: ' | awk -F': ' {'print $2'}`
	export REV_LOC=`svn info $TASK_SPACE/itask-$TOWEEK | grep 'Last Changed Rev: ' | awk -F': ' {'print $2'}`
	if [[ $REV_SRV != $REV_LOC ]] ; then
		svn up -q $SVN_OPTION $TASK_SPACE/itask-$TOWEEK
	fi
else
	rm -fr $TASK_SPACE/itask-*
	svn co -q $SVN_OPTION svn://$SVN_SRV/itask/itask $TASK_SPACE/itask
fi

if [[ ! -d $TASK_SPACE/itask/inode ]] ; then
	svn mkdir $TASK_SPACE/itask/inode
	svn ci $SVN_OPTION -m 'auto: add inode in $IP'
fi

echo "
IP=$IP
HOSTNAME=$HOSTNAME
DOMAIN_NAME=$DOMAIN_NAME
FS=$FS
MEMORY=$MEMORY
CPU=$CPU
JOBS=$JOBS
" > $TASK_SPACE/itask/inode/$HOSTNAME

if [[ `svn st $TASK_SPACE/itask/inode/$HOSTNAME | grep $HOSTNAME` ]] ; then
	svn add -q $TASK_SPACE/itask/inode/$HOSTNAME
	svn ci $SVN_OPTION -m 'auto: update $HOSTNAME $IP'
fi





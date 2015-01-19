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
source /etc/bash.bashrc
export LC_CTYPE=C
export LC_ALL=C
export USER=`whoami`
export TASK_SPACE=/run/shm
export NETWORK=`grep auto /etc/network/interfaces | grep -v lo | awk -F'auto ' {'print $2'} | heat -n1`
export IP=`/sbin/ifconfig $NETWORK | grep 'inet addr:' | awk -F':' {'print $2'} | awk -F' ' {'print $1'}`
export MAC=`/sbin/ifconfig $NETWORK | grep HWaddr | awk -F'HWaddr ' {'print $2'}`
export HOSTNAME=`hostname`
export DOMAIN_NAME=`cat /etc/resolv.conf | grep search | awk -F' ' {'print $2'}`
export BTRFS_PATH=`mount | grep btrfs | awk -F' ' {'print $3'} | tail -n1`
export MEMORY=`free -g | grep Mem | awk -F' ' {'print $2'}`
	export MEMORY=`echo $MEMORY + 1 | bc`
export CPU=`cat /proc/cpuinfo | grep CPU | awk -F': ' {'print $2'} | sort -u | awk -F' ' {'print $3$5$6'}`
export JOBS=`cat /proc/cpuinfo | grep CPU | wc -l`
export TOWEEK=`date +%yw%V`

if [[ -f $HOME/ibuild/conf/ibuild.conf ]] ; then
	export IBUILD_ROOT=$HOME/ibuild
else
	[[ `echo $0 | grep '^./'` ]] && export IBUILD_ROOT=`pwd`/`echo $0 | sed 's/^.\///g'`
	[[ `echo $0 | grep '^/'` ]] && export IBUILD_ROOT=`pwd``echo $0 | sed 's/^.\///g'`
	export IBUILD_ROOT=`dirname $0 | awk -F'/ibuild' {'print $1'}`'/ibuild'
fi

date
svn up -q $IBUILD_ROOT

export SVN_SRV=`grep '^IBUILD_SVN_SRV=' $IBUILD_ROOT/conf/ibuild.conf | awk -F'IBUILD_SVN_SRV=' {'print $2'}`
export SVN_OPTION=`grep '^IBUILD_SVN_OPTION=' $IBUILD_ROOT/conf/ibuild.conf | awk -F'IBUILD_SVN_OPTION=' {'print $2'}`
export SVN_REV_SRV=`svn info $SVN_OPTION svn://$SVN_SRV/itask/itask | grep 'Last Changed Rev: ' | awk -F': ' {'print $2'}`

if [[ -d $TASK_SPACE/itask-$TOWEEK ]] ; then
	export SVN_REV_LOC=`svn info $TASK_SPACE/itask-$TOWEEK | grep 'Last Changed Rev: ' | awk -F': ' {'print $2'}`
	if [[ $SVN_REV_SRV != $SVN_REV_LOC ]] ; then
		svn up -q $SVN_OPTION $TASK_SPACE/itask-$TOWEEK
	fi
else
	rm -fr $TASK_SPACE/itask-*
	svn co -q $SVN_OPTION svn://$SVN_SRV/itask/itask $TASK_SPACE/itask-$TOWEEK
fi

if [[ ! -d $TASK_SPACE/itask-$TOWEEK/inode ]] ; then
	svn mkdir $TASK_SPACE/itask-$TOWEEK/inode
	svn ci $SVN_OPTION -m "auto: add inode in $IP" $TASK_SPACE/itask-$TOWEEK/inode
fi

echo "# build node info
IP=$IP
HOSTNAME=$HOSTNAME
DOMAIN_NAME=$DOMAIN_NAME
MAC=$MAC
BTRFS_PATH=$BTRFS_PATH
MEMORY=$MEMORY
CPU=$CPU
JOBS=$JOBS
USER=$USER" | sort -u > $TASK_SPACE/itask-$TOWEEK/inode/$HOSTNAME

if [[ `svn st $TASK_SPACE/itask-$TOWEEK/inode/$HOSTNAME | grep $HOSTNAME` ]] ; then
	svn add -q $TASK_SPACE/itask-$TOWEEK/inode/$HOSTNAME
	svn ci $SVN_OPTION -m "auto: update $HOSTNAME $IP" $TASK_SPACE/itask-$TOWEEK/inode/$HOSTNAME
fi

if [[ ! `crontab -l | grep ibuild_node_reg` && -f $IBUILD_ROOT/setup/ibuild_node_reg.sh ]] ; then
	echo "# m h  dom mon dow   command
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
*/5 * * * * $IBUILD_ROOT/setup/ibuild_node_reg.sh >/tmp/ibuild_node_reg.log 2>&1
" >/tmp/$USER.crontab
	crontab -l | egrep -v '#|ibuild_node_reg.sh' >>/tmp/$USER.crontab
	crontab /tmp/$USER.crontab
fi

$IBUILD_PATH/setup/ibuild_node_daemon.sh >/tmp/ibuild_node_daemon.log 2>&1 &
$IBUILD_PATH/setup/sync_repo_local_mirror.sh >/tmp/sync_repo_local_mirror.log 2>&1 &


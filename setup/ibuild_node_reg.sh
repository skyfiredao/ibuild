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
# 150114 Create by Ding Wei
source /etc/bash.bashrc
export LC_CTYPE=C
export LC_ALL=C
export USER=`whoami`
export TASK_SPACE=/run/shm
export IP=`/sbin/ifconfig | grep 'inet addr:' | egrep -v '127.0.0.1|:172.[0-9]' | awk -F':' {'print $2'} | awk -F' ' {'print $1'} | head -n1`
export MAC=`/sbin/ifconfig | grep HWaddr | awk -F'HWaddr ' {'print $2'} | head -n1`
export HOSTNAME=`hostname`
export DOMAIN_NAME=`cat /etc/resolv.conf | grep search | awk -F' ' {'print $2'}`
export BTRFS_PATH=`mount | grep btrfs | awk -F' ' {'print $3'} | tail -n1`
export MEMORY=`free -g | grep Mem | awk -F' ' {'print $2'}`
	export MEMORY=`echo $MEMORY + 1 | bc`
export CPU=`cat /proc/cpuinfo | grep CPU | awk -F': ' {'print $2'} | sort -u`
export JOBS=`cat /proc/cpuinfo | grep CPU | wc -l`
export TOWEEK=`date +%yw%V`
export TODAY=`date +%y%m%d`
export IBUILD_ROOT=$HOME/ibuild
	[[ ! -d $HOME/ibuild ]] && export IBUILD_ROOT=`dirname $0 | awk -F'/ibuild' {'print $1'}`'/ibuild'
if [[ ! -f $HOME/ibuild/conf/ibuild.conf ]] ; then
	echo -e "Please put ibuild in your $HOME"
	exit 0
fi

svn up -q $IBUILD_ROOT

export IBUILD_SVN_SRV=`grep '^IBUILD_SVN_SRV=' $IBUILD_ROOT/conf/ibuild.conf | awk -F'IBUILD_SVN_SRV=' {'print $2'}`
export IBUILD_SVN_OPTION=`grep '^IBUILD_SVN_OPTION=' $IBUILD_ROOT/conf/ibuild.conf | awk -F'IBUILD_SVN_OPTION=' {'print $2'}`
export IBUILD_SVN_REV_SRV=`svn info $IBUILD_SVN_OPTION svn://$IBUILD_SVN_SRV/itask/itask | grep 'Last Changed Rev: ' | awk -F': ' {'print $2'}`
export IBUILD_SVN_SRV_HOSTNAME=`echo $IBUILD_SVN_SRV | awk -F'.' {'print $1'}`

$IBUILD_ROOT/setup/reboot.sh >/tmp/reboot.log 2>&1

if [[ -f $TASK_SPACE/itask/svn.$TOWEEK.lock && -d $TASK_SPACE/itask/svn/.svn ]] ; then
	export SVN_REV_LOC=`svn info $TASK_SPACE/itask/svn | grep 'Last Changed Rev: ' | awk -F': ' {'print $2'}`
	if [[ $IBUILD_SVN_REV_SRV != $SVN_REV_LOC ]] ; then
		sudo chmod 777 -R $TASK_SPACE/itask
		svn cleanup $TASK_SPACE/itask/svn
		svn up -q $IBUILD_SVN_OPTION $TASK_SPACE/itask/svn
	fi
else
	mkdir -p $TASK_SPACE/itask >/dev/null 2>&1
	rm -fr $TASK_SPACE/itask/svn* >/dev/null 2>&1
	touch $TASK_SPACE/itask/svn.$TOWEEK.lock
	svn co -q $IBUILD_SVN_OPTION svn://$IBUILD_SVN_SRV/itask/itask $TASK_SPACE/itask/svn
fi

if [[ ! -d $TASK_SPACE/itask/svn/inode ]] ; then
	svn mkdir $TASK_SPACE/itask/svn/inode
	svn ci $IBUILD_SVN_OPTION -m "auto: add inode in $IP" $TASK_SPACE/itask/svn/inode
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
USER=$USER" | sort -u > $TASK_SPACE/itask/svn/inode/$HOSTNAME

if [[ `svn st $TASK_SPACE/itask/svn/inode/$HOSTNAME | grep $HOSTNAME` ]] ; then
	svn add $TASK_SPACE/itask/svn/inode/$HOSTNAME >/dev/null 2>&1
	svn ci $IBUILD_SVN_OPTION -m "auto: update $HOSTNAME $IP" $TASK_SPACE/itask/svn/inode/$HOSTNAME
	if [[ $? != 0 ]] ; then
		rm -fr $TASK_SPACE/itask/svn
		echo -e "Waiting for next cycle because conflict"
		exit 1
	fi
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

if [[ $IBUILD_SVN_SRV_HOSTNAME = $HOSTNAME ]] ; then
	svn up -q $IBUILD_SVN_OPTION $TASK_SPACE/itask/svn/inode
	for CHK_HOST in `ls $TASK_SPACE/itask/svn/inode`
	do
		export CHK_HOST_IP=`grep '^IP=' $TASK_SPACE/itask/svn/inode/$CHK_HOST | awk -F'IP=' {'print $2'}`
		/bin/ping -c 3 -W 1 $CHK_HOST_IP >/dev/null 2>&1
		if [[ $? = 1 ]] ; then
			svn rm $TASK_SPACE/itask/svn/inode/$CHK_HOST
		fi
	done

	if [[ `svn st $TASK_SPACE/itask/svn/inode | grep ^D` ]] ; then
		svn ci $IBUILD_SVN_OPTION -m "auto: clean" $TASK_SPACE/itask/svn/inode/
	fi

	if [[ ! -f $TASK_SPACE/ganglia-$TODAY ]] ; then
		rm -f $TASK_SPACE/ganglia-*
		touch $TASK_SPACE/ganglia-$TODAY
		sudo /etc/init.d/gmetad restart
		sudo /etc/init.d/ganglia-monitor restart
	fi

	if [[ ! -f $TASK_SPACE/clean_task_spec-$TOWEEK ]] ; then
		rm -f $TASK_SPACE/clean_task_spec-*
		touch $TASK_SPACE/clean_task_spec-$TOWEEK
		$IBUILD_ROOT/misc/clean_task_spec.sh >/tmp/clean_task_spec.log
	fi

	$IBUILD_ROOT/imake/daily_build.sh >>/tmp/daily_build.log 2>&1 &
else
	bash -x $IBUILD_ROOT/setup/ibuild_node_daemon.sh $TASK_SPACE/itask/svn >/tmp/ibuild_node_daemon.log 2>&1 &
fi

$IBUILD_ROOT/setup/sync_repo_local_mirror.sh >/tmp/sync_repo_local_mirror.log 2>&1 &



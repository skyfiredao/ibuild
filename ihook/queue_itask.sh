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
# 150120 Create by Ding Wei
source /etc/bash.bashrc
export LC_CTYPE=C
export LC_ALL=C
export TASK_SPACE=/dev/shm
export TODAY=$(date +%y%m%d)

export IBUILD_ROOT=$HOME/ibuild
        [[ -z $IBUILD_ROOT ]] && export IBUILD_ROOT=$(dirname $0 | awk -F'/ibuild' {'print $1'})'/ibuild'
if [[ ! -f $HOME/ibuild/conf/ibuild.conf ]] ; then
	echo -e "Please put ibuild in your $HOME"
	exit 0
fi

export IBUILD_SVN_SRV=$(grep '^IBUILD_SVN_SRV=' $IBUILD_ROOT/conf/ibuild.conf | awk -F'IBUILD_SVN_SRV=' {'print $2'})
export IBUILD_SVN_OPTION=$(grep '^IBUILD_SVN_OPTION=' $IBUILD_ROOT/conf/ibuild.conf | awk -F'IBUILD_SVN_OPTION=' {'print $2'})

export QUEUE_SPACE=$TASK_SPACE/queue_itask
mkdir -p $QUEUE_SPACE >/dev/null 2>&1
chmod 777 -R $QUEUE_SPACE

export ITASK_REV=$1
export ITASK_SPEC_URL=$(svn log -v -r $ITASK_REV $IBUILD_SVN_OPTION svn://$IBUILD_SVN_SRV/itask/itask | egrep 'A |M ' | awk -F' ' {'print $2'} | head -n1)

if [[ `echo $ITASK_SPEC_URL | grep '^/itask/tasks'` ]] ; then
	export ITASK_SPEC_NAME=$(basename $ITASK_SPEC_URL)
	export IBUILD_PRIORITY=$(svn cat -r $ITASK_REV $IBUILD_SVN_OPTION svn://$IBUILD_SVN_SRV/itask/itask/tasks/$ITASK_SPEC_NAME | grep '^IBUILD_PRIORITY=' | awk -F'IBUILD_PRIORITY=' {'print $2'})
	[[ -z $IBUILD_PRIORITY ]] && export IBUILD_PRIORITY=x

	touch $QUEUE_SPACE/$IBUILD_PRIORITY.$ITASK_REV
	echo $IBUILD_PRIORITY.$ITASK_REV >>$TASK_SPACE/itask-$TODAY.list
	chmod 777 -R $QUEUE_SPACE
elif [[ `echo $ITASK_SPEC_URL | grep 'jobs.txt$'` ]] ; then
	$IBUILD_ROOT/ihook/mail_itask.sh $ITASK_REV
else
	exit
fi

[[ -f $TASK_SPACE/queue_itask.lock ]] && exit

while [[ `ls $QUEUE_SPACE` || ! -f /tmp/EXIT ]] ;
do
	$IBUILD_ROOT/ihook/node_matching.sh $QUEUE_SPACE >/tmp/node_matching.log 2>&1
	sleep `expr $RANDOM % 7 + 3`
done

[[ -d $TASK_SPACE/inode.lock/.svn ]] && svn up -q $IBUILD_SVN_OPTION $TASK_SPACE/inode.lock

rm -f $TASK_SPACE/queue_itask.lock

